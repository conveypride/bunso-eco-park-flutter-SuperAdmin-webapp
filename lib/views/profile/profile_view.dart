import 'package:bunso_ecopark_admin/controllers/auth_controller.dart';
import 'package:bunso_ecopark_admin/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final controller = Get.put(ProfileController());
    final user = authCtrl.currentUser.value;

    final nameCtrl = TextEditingController(text: user?.name);
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800), // Limit width on large screens
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("My Profile", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Manage your account settings and security.", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),

                // === CARD 1: PERSONAL INFORMATION ===
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Personal Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(height: 30),
                      
                      // Role Badge
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFF2D5016).withValues(alpha:0.1),
                            child: Text(
                              (user?.name ?? "A")[0].toUpperCase(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D5016)),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.email ?? "", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                                child: Text(user?.role.toUpperCase() ?? "STAFF", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Name Field
                      const Text("Display Name", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Enter your name"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Obx(() => ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D5016), 
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                            ),
                            onPressed: controller.isLoading.value ? null : () {
                              controller.updateProfile(nameCtrl.text);
                            },
                            child: const Text("Save"),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),

                // === CARD 2: SECURITY ===
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Security", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      const Divider(height: 30),
                      
                      const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      const Text("Enter your current password to verify your identity.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 20),

                      TextField(
                        controller: oldPassCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Current Password"),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: newPassCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "New Password"),
                      ),
                      const SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerRight,
                        child: Obx(() => ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50], 
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            elevation: 0
                          ),
                          icon: controller.isLoading.value 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                              : const Icon(Icons.lock_reset),
                          label: const Text("Update Password"),
                          onPressed: controller.isLoading.value ? null : () {
                            if (oldPassCtrl.text.isEmpty || newPassCtrl.text.isEmpty) {
                              Get.snackbar("Error", "Please fill all fields");
                              return;
                            }
                            controller.changePassword(oldPassCtrl.text, newPassCtrl.text);
                          },
                        )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}