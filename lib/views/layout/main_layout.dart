import 'package:bunso_ecopark_admin/controllers/auth_controller.dart';
import 'package:bunso_ecopark_admin/controllers/navigation_controller.dart';
import 'package:bunso_ecopark_admin/views/activities/activities_view.dart'; 
import 'package:bunso_ecopark_admin/views/dashboard/dashboard_view.dart';
import 'package:bunso_ecopark_admin/views/layout/side_menu.dart';
import 'package:bunso_ecopark_admin/views/profile/profile_view.dart';
import 'package:bunso_ecopark_admin/views/report/report_view.dart';
import 'package:bunso_ecopark_admin/views/settings/settings_view.dart';
import 'package:bunso_ecopark_admin/views/transactions/transactions_view.dart';
import 'package:bunso_ecopark_admin/views/users/users_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final navCtrl = Get.put(NavigationController());
    final authCtrl = Get.find<AuthController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F0), // Soft green-tinted background
      
      // === MODERN APP BAR ===
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF2D5016)),
        leading: !isDesktop
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        title: Obx(() {
          final items = navCtrl.getMenuItems();
          if (navCtrl.selectedIndex.value >= items.length) return const SizedBox();
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D5016), Color(0xFF4A7C2B)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  items[navCtrl.selectedIndex.value].title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          );
        }),
        actions: [
          // Search Icon (Desktop/Tablet)
          if (isDesktop || isTablet)
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Color(0xFF2D5016)),
              tooltip: "Search",
              onPressed: () {},
            ),
          
          // Notifications
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Color(0xFF2D5016)),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFC107),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                  ),
                ),
              ],
            ),
            tooltip: "Notifications",
            onPressed: () {},
          ),
          
          const SizedBox(width: 8),
          
          // Profile Section
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                if (isDesktop)
                  Obx(() => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            authCtrl.currentUser.value?.name ?? "Admin",
                            style: const TextStyle(
                              color: Color(0xFF2D5016),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            "Administrator",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      )),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFC107), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF2D5016),
                    child: Text(
                      (authCtrl.currentUser.value?.name ?? "A")[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2D5016)),
                  offset: const Offset(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, color: Color(0xFF2D5016)),
                          SizedBox(width: 12),
                          Text('Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>( 
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined, color: Color(0xFF2D5016)),
                          SizedBox(width: 12),
                          Text('Settings'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Logout', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'logout') authCtrl.signOut();
                    else if (value == 'settings'){
                     navCtrl.changePage(5);
                    } 
                    else if (value == 'profile') {
                     navCtrl.changePage(6);
                    } else {
                      // Handle other selections
                     navCtrl.changePage(0);
                    };
                  },
                ),
              ],
            ),
          ),
        ],
      ),

      // === DRAWER FOR MOBILE/TABLET ===
      drawer: !isDesktop ? const SideMenu() : null,

      // === BODY WITH MODERN LAYOUT ===
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PERMANENT SIDEBAR (Desktop Only)
          if (isDesktop) const SideMenu(),

          // MAIN CONTENT AREA WITH PADDING
          Expanded(
            child: Container(
              margin: EdgeInsets.all(isDesktop ? 24 : 16),
              child: Obx(() {
                Widget content;
                switch (navCtrl.selectedIndex.value) {
                  case 0:
                    content = const DashboardView();
                    break;
                  case 1:
                    content = const ReportView();
                    break;
                  case 2:
                    content = const TransactionsView();
                    break;
                  case 3:
                    content = const ActivitiesView();
                    break;
                  case 4:
                    content = const UsersView();
                    break;
                  case 5:
                    content = const SettingsView();
                  break;
                  case 6: content = const ProfileView();
                    break;
                  default:
                    content = Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "404 - Page Not Found",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                }
                
                // Wrap content with fade animation
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: content,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:bunso_ecopark_admin/controllers/auth_controller.dart';
// import 'package:bunso_ecopark_admin/controllers/navigation_controller.dart';
// import 'package:bunso_ecopark_admin/views/activities/activities_view.dart'; 
// import 'package:bunso_ecopark_admin/views/dashboard/dashboard_view.dart';
// import 'package:bunso_ecopark_admin/views/layout/side_menu.dart';
// import 'package:bunso_ecopark_admin/views/report/report_view.dart';
// import 'package:bunso_ecopark_admin/views/settings/settings_view.dart';
// import 'package:bunso_ecopark_admin/views/transactions/transactions_view.dart';
// import 'package:bunso_ecopark_admin/views/users/users_view.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class MainLayout extends StatelessWidget {
//   const MainLayout({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Inject Controller
//     final navCtrl = Get.put(NavigationController());
//     final authCtrl = Get.find<AuthController>();

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
      
//       // === APP BAR (Top Header) ===
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 1,
//         iconTheme: const IconThemeData(color: Colors.black), // Menu Icon Color
//         title: Obx(() {
//            // Dynamic Title based on selection
//            final items = navCtrl.getMenuItems();
//            // Safety check for index
//            if(navCtrl.selectedIndex.value >= items.length) return const Text("");
//            return Text(
//              items[navCtrl.selectedIndex.value].title.toUpperCase(),
//              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
//            );
//         }),
//         actions: [
//           // Profile Dropdown
//           Center(
//             child: Obx(() => Text(
//               authCtrl.currentUser.value?.name ?? "Admin",
//               style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//             )),
//           ),
//           const SizedBox(width: 10),
//           IconButton(
//             icon: const Icon(Icons.logout, color: Colors.red),
//             tooltip: "Logout",
//             onPressed: () => authCtrl.signOut(),
//           ),
//           const SizedBox(width: 20),
//         ],
//       ),

//       // === DRAWER (Only shows on small screens) ===
//       drawer: MediaQuery.of(context).size.width < 900 ? const SideMenu() : null,

//       // === BODY ===
//       body: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // 1. PERMANENT SIDEBAR (Desktop Only)
//           if (MediaQuery.of(context).size.width >= 900)
//             const SideMenu(),

//           // 2. DYNAMIC CONTENT AREA
//           Expanded(
//             child: Obx(() {
//               // Switch Widget based on Index
//               switch (navCtrl.selectedIndex.value) {
//                 case 0: return const DashboardView();
//                 case 1: return const ReportView();
//                 case 2: return const TransactionsView();
//                 case 3: return const ActivitiesView();
//                 case 4: return const UsersView();  
//                 case 5: return const SettingsView(); 
//                 default: return const Center(child: Text("404 Not Found"));
//               }
//             }),
//           ),
//         ],
//       ),
//     );
//   }
// }