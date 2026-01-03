import 'package:bunso_ecopark_admin/controllers/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthController authController = Get.find<AuthController>();

  var isLoading = false.obs;
  var isObscure = true.obs; // For password field

  // Update Display Name
  Future<void> updateProfile(String newName) async {
    try {
      isLoading.value = true;
      User? user = _auth.currentUser;

      if (user != null) {
        // 1. Update Firebase Auth Profile
        await user.updateDisplayName(newName);
        
        // 2. Update Firestore User Document (Optional but recommended for consistency)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'displayName': newName});

        // 3. Update Local State
        authController.currentUser.value = authController.currentUser.value!.copyWith(name: newName); // Ensure UserModel has copyWith or just refresh
        authController.currentUser.refresh(); // Trigger UI update in sidebar/header
        
        Get.snackbar("Success", "Profile updated successfully!", backgroundColor: Colors.green.withValues(alpha:0.1));
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to update profile: $e", backgroundColor: Colors.red.withValues(alpha:0.1));
    } finally {
      isLoading.value = false;
    }
  }

  // Change Password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      isLoading.value = true;
      User? user = _auth.currentUser;

      if (user != null && user.email != null) {
        // Re-authenticate first (Required for security sensitive actions)
        AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
        await user.reauthenticateWithCredential(credential);

        // Update Password
        await user.updatePassword(newPassword);
        
        Get.snackbar("Success", "Password changed! Please login again.");
        authController.signOut(); // Force re-login for safety
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? "Password change failed");
    } catch (e) {
      Get.snackbar("Error", "An error occurred");
    } finally {
      isLoading.value = false;
    }
  }
}