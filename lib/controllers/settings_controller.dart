import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = true.obs;
  
  // Revenue Splits
  var activities = <Map<String, dynamic>>[].obs;
  
  // WhatsApp Groups
  var whatsappGroups = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  void fetchData() async {
    try {
      isLoading.value = true;
      // 1. Fetch Activities
      final actSnapshot = await _db.collection('activities').get();
      activities.value = actSnapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        if (data['ecoparkPercent'] == null) data['ecoparkPercent'] = 80;
        return data;
      }).toList();

      // 2. Fetch WhatsApp Groups
      final groupSnapshot = await _db.collection('whatsapp_groups').get();
      whatsappGroups.value = groupSnapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        // Ensure phones list exists
        if (data['phones'] == null) data['phones'] = [];
        return data;
      }).toList();

    } catch (e) {
      Get.snackbar("Error", "Could not load settings: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // === REVENUE SPLIT METHODS ===
  Future<void> updateSplit(String id, double ecoparkPercent) async {
    try {
      await _db.collection('activities').doc(id).update({
        'ecoparkPercent': ecoparkPercent,
      });
      int index = activities.indexWhere((a) => a['id'] == id);
      if (index != -1) {
        activities[index]['ecoparkPercent'] = ecoparkPercent;
        activities.refresh();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to save split: $e");
    }
  }

  // === WHATSAPP GROUP METHODS ===
  
  // Create or Update Group
  Future<void> saveGroup(String? id, String name, List<String> phones) async {
    try {
      if (id == null) {
        // Create New
        final doc = await _db.collection('whatsapp_groups').add({
          'name': name,
          'phones': phones,
          'createdAt': FieldValue.serverTimestamp(),
        });
        whatsappGroups.add({'id': doc.id, 'name': name, 'phones': phones});
      } else {
        // Update Existing
        await _db.collection('whatsapp_groups').doc(id).update({
          'name': name,
          'phones': phones,
        });
        int index = whatsappGroups.indexWhere((g) => g['id'] == id);
        if (index != -1) {
          whatsappGroups[index] = {'id': id, 'name': name, 'phones': phones};
        }
      }
      whatsappGroups.refresh();
      Get.back(); // Close dialog
      Get.snackbar("Success", "Group saved successfully", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Failed to save group: $e");
    }
  }

  Future<void> deleteGroup(String id) async {
    try {
      await _db.collection('whatsapp_groups').doc(id).delete();
      whatsappGroups.removeWhere((g) => g['id'] == id);
      Get.back(); // Close confirmation
      Get.snackbar("Deleted", "Group removed", backgroundColor: Colors.orange.withValues(alpha:0.1));
    } catch (e) {
      Get.snackbar("Error", "Failed to delete: $e");
    }
  }
}
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class SettingsController extends GetxController {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;

//   var isLoading = true.obs;
//   var activities = <Map<String, dynamic>>[].obs;

//   @override
//   void onInit() {
//     super.onInit();
//     fetchActivities();
//   }

//   void fetchActivities() async {
//     try {
//       isLoading.value = true;
//       final snapshot = await _db.collection('activities').get();
      
//       activities.value = snapshot.docs.map((doc) {
//         var data = doc.data();
//         data['id'] = doc.id;
//         // Ensure default values exist if not set yet
//         if (data['ecoparkPercent'] == null) data['ecoparkPercent'] = 80;
//         return data;
//       }).toList();
      
//     } catch (e) {
//       Get.snackbar("Error", "Could not load settings: $e");
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> updateSplit(String id, double ecoparkPercent) async {
//     try {
//       await _db.collection('activities').doc(id).update({
//         'ecoparkPercent': ecoparkPercent,
//       });
//       // Update local list
//       int index = activities.indexWhere((a) => a['id'] == id);
//       if (index != -1) {
//         activities[index]['ecoparkPercent'] = ecoparkPercent;
//         activities.refresh();
//       }
//       Get.snackbar("Saved", "Revenue split updated successfully!", 
//         duration: const Duration(milliseconds: 800), backgroundColor: Colors.green.withValues(alpha:0.1));
//     } catch (e) {
//       Get.snackbar("Error", "Failed to save: $e");
//     }
//   }
// }