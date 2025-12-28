import 'package:bunso_ecopark_admin/controllers/navigation_controller.dart';
import 'package:bunso_ecopark_admin/views/widgets/build_logo_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final navCtrl = Get.find<NavigationController>();
    final menuItems = navCtrl.getMenuItems();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Container(
      width: isDesktop ? 280 : 260,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // === LOGO HEADER WITH GRADIENT ===
          Container(
            height: 120,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2D5016),
                  Color(0xFF4A7C2B),
                  Color(0xFF5D9939),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFC107).withOpacity(0.2),
                    ),
                  ),
                ),
                // Logo
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BuildLogoHeader(namecolor: Colors.white),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "ADMIN PANEL",
                          style: TextStyle(
                            color: Color(0xFF2D5016),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // === MENU ITEMS ===
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: menuItems.length,
              itemBuilder: (context, i) {
                return Obx(() {
                  final item = menuItems[i];
                  final isSelected = navCtrl.selectedIndex.value == item.index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF2D5016), Color(0xFF4A7C2B)],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2D5016).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          navCtrl.changePage(item.index);
                          // Close drawer on mobile after selection
                          if (!isDesktop) {
                            Navigator.of(context).pop();
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              // Icon with yellow accent when selected
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFFC107).withOpacity(0.3)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF2D5016),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Title
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFF2D5016),
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              // Arrow indicator
                              if (isSelected)
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Color(0xFFFFC107),
                                  size: 14,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
          ),

          // === DECORATIVE DIVIDER ===
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey[300]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // === VERSION INFO WITH STYLE ===
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7F0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF2D5016).withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFC107),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Color(0xFF2D5016),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Version 1.0.0",
                      style: TextStyle(
                        color: Color(0xFF2D5016),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "EcoPark Admin",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
//  import 'package:bunso_ecopark_admin/controllers/navigation_controller.dart';
// import 'package:bunso_ecopark_admin/views/widgets/build_logo_header.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class SideMenu extends StatelessWidget {
//   const SideMenu({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final navCtrl = Get.find<NavigationController>();
//     final menuItems = navCtrl.getMenuItems();

//     return Container(
//       width: 250,
//       color: Colors.white, // Or Brand Green
//       child: Column(
//         children: [
//           // 1. LOGO HEADER
//           Container(
//             height: 100,
//             alignment: Alignment.center,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 BuildLogoHeader(),
//               ],
//             ),
//           ),
//           const Divider(),

//           // 2. MENU LIST
//           Expanded(
//             child: ListView.builder(
//               itemCount: menuItems.length,
//               itemBuilder: (context, i) {
//                 return Obx(() {
//                   final item = menuItems[i];
//                   final isSelected = navCtrl.selectedIndex.value == item.index;

//                   return Container(
//                     margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: isSelected ? const Color(0xFF2D5016).withOpacity(0.1) : null,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: ListTile(
//                       onTap: () => navCtrl.changePage(item.index),
//                       leading: Icon(
//                         item.icon, 
//                         color: isSelected ? const Color(0xFF2D5016) : Colors.grey[500]
//                       ),
//                       title: Text(
//                         item.title,
//                         style: TextStyle(
//                           color: isSelected ? const Color(0xFF2D5016) : Colors.grey[700],
//                           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
//                         ),
//                       ),
//                     ),
//                   );
//                 });
//               },
//             ),
//           ),

//           // 3. VERSION INFO
//           const Padding(
//             padding: EdgeInsets.all(20.0),
//             child: Text("v1.0.0", style: TextStyle(color: Colors.grey)),
//           )
//         ],
//       ),
//     );
//   }
// }