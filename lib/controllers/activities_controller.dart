import 'package:bunso_ecopark_admin/controllers/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ActivitiesController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var activities = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchActivities();
  }

bool isAdmin(){
     final auth = Get.find<AuthController>();
    bool isadmin = auth.currentUser.value?.isAdmin ?? false;

    return isadmin;
} 

  void fetchActivities() async {
    try {
      isLoading.value = true;
      final snapshot = await _db.collection('activities').get();
      activities.value = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id; // Append ID to data
        return data;
      }).toList();
    } catch (e) {
      Get.snackbar("Error", "Could not load activities: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveActivity({
    String? id, // If null, create new
    required String name,
    required List<Map<String, dynamic>> tiers,
  }) async {
    try {
      isLoading.value = true;
      
      final data = {
        'name': name,
        'priceTiers': tiers, // [{name: 'Adult', price: 50}, ...]
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (id == null) {
        // Create New
        await _db.collection('activities').add(data);
      } else {
        // Update Existing
        await _db.collection('activities').doc(id).update(data);
      }

      Get.back(); // Close Dialog
      Get.snackbar("Success", "$name saved successfully!");
      fetchActivities(); // Refresh UI
    } catch (e) {
      Get.snackbar("Error", "Failed to save: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteActivity(String id) async {
    try {
      await _db.collection('activities').doc(id).delete();
      fetchActivities();
      Get.snackbar("Deleted", "Activity removed.");
    } catch (e) {
      Get.snackbar("Error", "Could not delete.");
    }
  }
}