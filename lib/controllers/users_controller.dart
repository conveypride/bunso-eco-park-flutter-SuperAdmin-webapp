import 'package:bunso_ecopark_admin/data/models/user_model.dart';
import 'package:bunso_ecopark_admin/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

class UsersController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var users = <UserModel>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  // 1. Fetch All Staff
  void fetchUsers() async {
    try {
      isLoading.value = true;
      final snapshot = await _db.collection('users').get();
      
      users.value = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();
      
    } catch (e) {
      Get.snackbar("Error", "Could not load users: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 2. Create New User (The "Secondary App" Trick)
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      isLoading.value = true;

      // A. Initialize a temporary secondary app
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // B. Create the user on that secondary app
      // This prevents the Super Admin from being logged out!
      UserCredential cred = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      // C. Save User Details to Firestore (Using the MAIN app)
      String uid = cred.user!.uid;
      
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': name,
        'role': role,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.back(); // Close Dialog
      Get.snackbar("Success", "User $name created successfully!");
      fetchUsers(); // Refresh list

    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? "Failed to create user");
    } catch (e) {
      Get.snackbar("Error", "System error: $e");
    } finally {
      // D. Clean up
      await secondaryApp?.delete();
      isLoading.value = false;
    }
  }

  // 3. Toggle Block/Unblock
  Future<void> toggleUserStatus(UserModel user) async {
    try {
      bool newStatus = !user.isActive;
      await _db.collection('users').doc(user.uid).update({'isActive': newStatus});
      
      // Update local list instantly
      int index = users.indexWhere((u) => u.uid == user.uid);
      if (index != -1) {
        users[index] = UserModel(
          uid: user.uid,
          email: user.email,
          name: user.name,
          role: user.role,
          isActive: newStatus,
        );
      }
      Get.snackbar("Updated", "${user.name} is now ${newStatus ? 'Active' : 'Blocked'}");
    } catch (e) {
      Get.snackbar("Error", "Could not update status");
    }
  }
}