import 'package:bunso_ecopark_admin/controllers/users_controller.dart';
import 'package:bunso_ecopark_admin/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UsersView extends StatelessWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UsersController());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === HEADER ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("User Management", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5016),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  icon: const Icon(Icons.person_add),
                  label: const Text("Add New User"),
                  onPressed: () => _showAddUserDialog(context, controller),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text("Manage access for Cashiers, Admins, and Super Admins.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            // === USER TABLE ===
            Expanded(
              child: Card(
                child: Obx(() {
                  if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());

                  return SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                        columns: const [
                          DataColumn(label: Text("Name")),
                          DataColumn(label: Text("Email")),
                          DataColumn(label: Text("Role")),
                          DataColumn(label: Text("Status")),
                          DataColumn(label: Text("Action")),
                        ],
                        rows: controller.users.map((user) => _buildUserRow(user, controller)).toList(),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildUserRow(UserModel user, UsersController controller) {
    return DataRow(cells: [
      DataCell(Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[200],
            child: Icon(Icons.person, size: 16, color: Colors.grey[600]),
          ),
          const SizedBox(width: 10),
          Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      )),
      DataCell(Text(user.email)),
      DataCell(_buildRoleBadge(user.role)),
      DataCell(
        Switch(
          value: user.isActive,
          activeColor: Colors.green,
          onChanged: (val) => controller.toggleUserStatus(user),
        ),
      ),
      DataCell(
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.grey),
          onPressed: () {
             Get.snackbar("Tip", "To edit details, block and recreate the user.");
          },
        ),
      ),
    ]);
  }

  Widget _buildRoleBadge(String role) {
    Color color = Colors.blue;
    if (role == 'super_admin') color = Colors.purple;
    if (role == 'cashier') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(role.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showAddUserDialog(BuildContext context, UsersController controller) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedRole = 'cashier';

    Get.defaultDialog(
      title: "Create New User",
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: "Role", border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'cashier', child: Text("Cashier")),
                DropdownMenuItem(value: 'admin', child: Text("Admin (View Only)")),
                DropdownMenuItem(value: 'super_admin', child: Text("Super Admin")),
              ],
              onChanged: (val) => selectedRole = val!,
            ),
          ],
        ),
      ),
      confirm: ElevatedButton(
        onPressed: () {
          if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
          controller.createUser(
            email: emailCtrl.text.trim(),
            password: passCtrl.text.trim(),
            name: nameCtrl.text.trim(),
            role: selectedRole,
          );
        },
        child: const Text("Create User"),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
    );
  }
}