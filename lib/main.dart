import 'package:bunso_ecopark_admin/controllers/auth_controller.dart';
import 'package:bunso_ecopark_admin/routes/app_pages.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  // (Make sure you have run 'flutterfire configure' to generate firebase_options.dart)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Initialize Auth Controller Immediately
  // We put this in memory *before* the app runs so we can check login status
  Get.put(AuthController());

  runApp(const BunsoAdminApp());
}

class BunsoAdminApp extends StatelessWidget {
  const BunsoAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Bunso Admin Dashboard',
      debugShowCheckedModeBanner: false,

      // === THEME CONFIGURATION ===
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5016), // Primary Brand Green
          primary: const Color(0xFF2D5016),
          secondary: const Color(0xFF6B9544), // Lighter Green
          tertiary: const Color(0xFFFFB800),  // Gold Accent
        ),
        useMaterial3: true,
        fontFamily: 'Poppins', // Ensure you add this font to pubspec.yaml later
        
        // Customize Card Theme for Dashboard Widgets
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
        ),
      ),

      // === NAVIGATION ===
      // We don't use 'home:'. We use 'initialRoute' for better security management.
      initialRoute: '/login', 
      
      // Load our route definitions (from lib/routes/app_pages.dart)
      getPages: AppPages.routes,
    );
  }
}