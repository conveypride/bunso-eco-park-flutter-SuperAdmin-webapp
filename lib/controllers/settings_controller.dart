import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = true.obs;
  var activities = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchActivities();
  }

  void fetchActivities() async {
    try {
      isLoading.value = true;
      final snapshot = await _db.collection('activities').get();
      
      activities.value = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        // Ensure default values exist if not set yet
        if (data['ecoparkPercent'] == null) data['ecoparkPercent'] = 80;
        return data;
      }).toList();
      
    } catch (e) {
      Get.snackbar("Error", "Could not load settings: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateSplit(String id, double ecoparkPercent) async {
    try {
      await _db.collection('activities').doc(id).update({
        'ecoparkPercent': ecoparkPercent,
      });
      // Update local list
      int index = activities.indexWhere((a) => a['id'] == id);
      if (index != -1) {
        activities[index]['ecoparkPercent'] = ecoparkPercent;
        activities.refresh();
      }
      Get.snackbar("Saved", "Revenue split updated successfully!", 
        duration: const Duration(milliseconds: 800), backgroundColor: Colors.green.withOpacity(0.1));
    } catch (e) {
      Get.snackbar("Error", "Failed to save: $e");
    }
  }
}