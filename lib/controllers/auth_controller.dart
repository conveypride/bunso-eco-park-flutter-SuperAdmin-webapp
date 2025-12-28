 import 'package:bunso_ecopark_admin/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Reactive User State
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to Firebase Auth Changes (Auto-login)
    _auth.authStateChanges().listen(_handleAuthChanged);
  }

  // 1. Monitor Auth State
  Future<void> _handleAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      // User is logged out
      currentUser.value = null;
      isLoading.value = false;
      Get.offAllNamed('/login'); // Force to Login Page
    } else {
      // User is logged in, but we need their ROLE from Firestore
      await _fetchUserRole(firebaseUser.uid);
    }
  }

  // 2. Fetch Role & Check Active Status
  Future<void> _fetchUserRole(String uid) async {
    try {
      isLoading.value = true;
      final doc = await _db.collection('users').doc(uid).get();

      if (doc.exists) {
        final userData = UserModel.fromMap(doc.data()!, uid);

        // SECURITY CHECK 1: Is account active?
        if (!userData.isActive) {
          Get.snackbar("Access Denied", "Your account has been disabled.");
          await signOut();
          return;
        }

        // SECURITY CHECK 2: Is it a Web Role? (Cashiers shouldn't login here)
        if (userData.role == 'cashier') {
           Get.snackbar("Access Denied", "Cashiers use the Mobile App only.");
           await signOut();
           return;
        }

        // Success: Store user in state
        currentUser.value = userData;
        isLoading.value = false;
        
        // Navigate to Dashboard if currently on Login page
        if (Get.currentRoute == '/login') {
          Get.offAllNamed('/dashboard');
        }
      } else {
        // User authenticated but has no database record
        Get.snackbar("Error", "User profile not found.");
        await signOut();
      }
    } catch (e) {
      print("Auth Error: $e");
      isLoading.value = false;
    }
  }

  // 3. Login Function (Called by Login View)
  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      // _handleAuthChanged will trigger automatically after this
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String message = "Login failed";
      if (e.code == 'user-not-found') message = "No user found with this email.";
      if (e.code == 'wrong-password') message = "Incorrect password.";
      Get.snackbar("Error", message);
    }
  }

  // 4. Logout
  Future<void> signOut() async {
    await _auth.signOut();
    currentUser.value = null;
  }
}