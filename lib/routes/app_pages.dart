import 'package:bunso_ecopark_admin/middlewares/auth_guard.dart';
import 'package:bunso_ecopark_admin/views/layout/main_layout.dart';
import 'package:bunso_ecopark_admin/views/login/login_view.dart';
import 'package:get/get.dart';

class AppPages {
  static final routes = [
   GetPage(
      name: '/login',
      page: () => const LoginView(), // <--- Connect here
    ),
   GetPage(
      name: '/dashboard',
      page: () => const MainLayout(), 
      middlewares: [AuthGuard()],
    ),
    // This allows you to go to admin.com/activities directly
    GetPage(
      name: '/activities',
      page: () => const MainLayout(), // We reuse MainLayout
      binding: BindingsBuilder(() {
        // Optional: Pre-select index 3 if user lands here directly
        // You'd need a small logic in MainLayout to read the current route
      }),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: '/users',
      page: () => MainLayout(),  
      middlewares: [AuthGuard()], // <--- Protected
    ),

// SETTINGS PAGE
    GetPage(
      name: '/settings',
      page: () => MainLayout(),  
      middlewares: [AuthGuard()], // <--- Protected
    ),

// TRANSACTION PAGE
    GetPage(
      name: '/transactions',
      page: () => MainLayout(),  
      middlewares: [AuthGuard()], // <--- Protected
    ),

    // REPORT PAGE
    GetPage(
      name: '/report',
      page: () => MainLayout(),  
      middlewares: [AuthGuard()], // <--- Protected
    ),

    // profile PAGE
    GetPage(
      name: '/profile',
      page: () => MainLayout(),  
      middlewares: [AuthGuard()], // <--- Protected
    ),

  ];
}