import 'package:bunso_ecopark_admin/controllers/users_controller.dart';
import 'package:bunso_ecopark_admin/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UsersView extends StatelessWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UsersController());
    
    // Responsive breakpoints
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === HEADER ===
            _buildHeader(context, controller, isMobile),
            
            const SizedBox(height: 10),
            const Text(
              "Manage access for Cashiers, Admins, and Super Admins.", 
              style: TextStyle(color: Colors.grey)
            ),
            const SizedBox(height: 30),

            // === CONTENT (Table vs List) ===
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (controller.users.isEmpty) {
                  return _buildEmptyState();
                }

                return isMobile 
                    ? _buildMobileList(controller) 
                    : _buildDesktopTable(controller);
              }),
            ),
          ],
        ),
      ),
    );
  }

  // === 1. HEADER WIDGET ===
  Widget _buildHeader(BuildContext context, UsersController controller, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("User Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => _showAddUserDialog(context, controller),
                icon: const Icon(Icons.person_add, color: Color(0xFF2D5016)),
                tooltip: "Add User",
              )
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("User Management", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D5016),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.person_add, size: 20),
          label: const Text("Add New User"),
          onPressed: () => _showAddUserDialog(context, controller),
        ),
      ],
    );
  }

  // === 2. DESKTOP TABLE VIEW ===
  Widget _buildDesktopTable(UsersController controller) {
    return Container(
      width: MediaQuery.of(Get.context!).size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView( // Vertical scroll for list
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
              headingRowHeight: 80,
              dataRowMinHeight: 80,
              dataRowMaxHeight: 90,
              columnSpacing: 70,
              columns: const [
                DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Role", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))), 
              ],
              rows: controller.users.map((user) => _buildUserRow(user, controller)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildUserRow(UserModel user, UsersController controller) {
    return DataRow(cells: [
      DataCell(Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2D5016).withValues(alpha:0.1),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Color(0xFF2D5016), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      )),
      DataCell(Text(user.email)),
      DataCell(_buildRoleBadge(user.role)),
      DataCell(
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: user.isActive,
            activeThumbColor: const Color(0xFF2D5016),
            onChanged: (val) => controller.toggleUserStatus(user),
          ),
        ),
      ),
     
    ]);
  }

  // === 3. MOBILE LIST VIEW ===
  Widget _buildMobileList(UsersController controller) {
    return ListView.separated(
      itemCount: controller.users.length,
      separatorBuilder: (c, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = controller.users[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 5)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF2D5016).withValues(alpha:0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Color(0xFF2D5016), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: user.isActive,
                    activeThumbColor: const Color(0xFF2D5016),
                    onChanged: (val) => controller.toggleUserStatus(user),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRoleBadge(user.role),
                  
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // === HELPERS ===

  Widget _buildRoleBadge(String role) {
    Color color = Colors.blue;
    String label = role;

    if (role == 'super_admin') {
      color = Colors.purple;
      label = "Super Admin";
    } else if (role == 'cashier') {
      color = Colors.green;
      label = "Cashier";
    } else {
      label = "Admin"; // View Only
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: Text(
        label.toUpperCase(), 
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No users found", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, UsersController controller) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedRole = 'cashier';

    // Using Get.dialog but ensuring it's constrained for desktop and mobile
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create New User"),
        content: SizedBox(
          width: 400, // Constrain width on desktop
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl, 
                  decoration: const InputDecoration(
                    labelText: "Full Name", 
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder()
                  )
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl, 
                  decoration: const InputDecoration(
                    labelText: "Email", 
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder()
                  )
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passCtrl, 
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password", 
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder()
                  )
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: "Role", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'cashier', child: Text("Cashier (Sales)")),
                    DropdownMenuItem(value: 'admin', child: Text("Admin (View Only)")),
                    DropdownMenuItem(value: 'super_admin', child: Text("Super Admin (Full Access)")),
                  ],
                  onChanged: (val) => selectedRole = val!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5016),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
              controller.createUser(
                email: emailCtrl.text.trim(),
                password: passCtrl.text.trim(),
                name: nameCtrl.text.trim(),
                role: selectedRole,
              );
              Navigator.pop(context);
            },
            child: const Text("Create User"),
          ),
        ],
      ),
    );
  }
}
 