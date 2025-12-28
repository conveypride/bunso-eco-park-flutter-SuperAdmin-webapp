 import 'package:bunso_ecopark_admin/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavigationController extends GetxController {
  var selectedIndex = 0.obs;
  
  // Controls the Sidebar open/close on smaller screens
  var isSidebarOpen = true.obs; 

  void changePage(int index) {
    selectedIndex.value = index;
    // On mobile/tablet, auto-close sidebar after selection
    if (Get.width < 900) {
      isSidebarOpen.value = false;
    }
  }

  // Define the Menu Items here so we can filter them by Role
  List<MenuItem> getMenuItems() {
    final auth = Get.find<AuthController>();
    final isSuper = auth.currentUser.value?.isSuperAdmin ?? false;

    // 1. Common Menus
    List<MenuItem> items = [
      MenuItem(icon: Icons.dashboard, title: "Dashboard", index: 0),
      MenuItem(icon: Icons.bar_chart, title: "Reports", index: 1),
      MenuItem(icon: Icons.receipt_long, title: "Transactions", index: 2),
    ];

    // 2. Super Admin Only
    if (isSuper) {
      items.add(MenuItem(icon: Icons.edit_note, title: "Activity Manager", index: 3));
      items.add(MenuItem(icon: Icons.people_alt, title: "User Management", index: 4));
      items.add(MenuItem(icon: Icons.settings, title: "Settings", index: 5));
    } else {
       // Admins can view activities but maybe we just lump it in the same index or show read-only
       items.add(MenuItem(icon: Icons.visibility, title: "View Activities", index: 3));
    }

    return items;
  }
}

class MenuItem {
  final IconData icon;
  final String title;
  final int index;
  MenuItem({required this.icon, required this.title, required this.index});
}