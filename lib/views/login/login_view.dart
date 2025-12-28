import 'package:bunso_ecopark_admin/controllers/auth_controller.dart';
import 'package:bunso_ecopark_admin/views/widgets/build_logo_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF2D5016), // Brand Green Background
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Logo Section
               BuildLogoHeader(namecolor:Color(0xFF2D5016)),
              const SizedBox(height: 10),
               
              const Text("Admin Portal", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              // 2. Input Fields
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => controller.login(emailCtrl.text, passCtrl.text),
              ),
              const SizedBox(height: 30),

              // 3. Login Button with Loading State
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const ElevatedButton(
                      onPressed: null, 
                      child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                    );
                  }
                  
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5016),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => controller.login(emailCtrl.text, passCtrl.text),
                    child: const Text("SECURE LOGIN", style: TextStyle(fontWeight: FontWeight.bold)),
                  );
                }),
              ),
              
              const SizedBox(height: 20),
              const Text("Authorized Personnel Only", style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}