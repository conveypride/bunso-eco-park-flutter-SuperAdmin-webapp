import 'package:bunso_ecopark_admin/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthGuard extends GetMiddleware {
  // Priority (Low number = runs first)
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    // 1. Check if logged in
    if (authController.currentUser.value == null) {
      return const RouteSettings(name: '/login');
    }

    // 2. Check Role Permissions
    // If user tries to access User Management but is NOT Super Admin
    if (route == '/users' && !authController.currentUser.value!.isSuperAdmin) {
      // Kick them back to dashboard
      return const RouteSettings(name: '/dashboard');
    }

    // Allow access
    return null;
  }
}