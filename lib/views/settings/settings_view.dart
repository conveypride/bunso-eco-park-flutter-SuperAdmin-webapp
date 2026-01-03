 import 'package:bunso_ecopark_admin/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());
    
    // Determine screen size for responsiveness
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === HEADER ===
            const Text("Global Settings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D5016))),
            const Text("Configure revenue sharing and communication preferences.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            // === CONTENT (STACKED ON MOBILE, SIDE-BY-SIDE ON DESKTOP IF SPACE PERMITS) ===
            // Note: Since both sections can be tall, we usually keep them stacked vertically 
            // but full width. However, on very wide screens, we can use a Wrap or Row.
            // For settings pages, a single vertical column is usually cleaner UX, 
            // so we will optimize the *internal* layout of each card.
            
            _buildWhatsAppSection(context, controller, isMobile),
            const SizedBox(height: 30),
            _buildRevenueSection(context, controller, isMobile),
          ],
        ),
      ),
    );
  }

  // === 1. WHATSAPP GROUPS SECTION ===
  Widget _buildWhatsAppSection(BuildContext context, SettingsController controller, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF2D5016).withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.message_outlined, color: Color(0xFF2D5016)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "WhatsApp Report Groups", 
                        style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile) 
                _buildAddGroupButton(context, controller),
            ],
          ),
          
          // Mobile Add Button (Below header if space is tight)
          if (isMobile) ...[
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: _buildAddGroupButton(context, controller)),
          ],

          const Divider(height: 30),
          
          // List
          Obx(() {
            if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
            if (controller.whatsappGroups.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text("No groups created yet. Add one to allow cashiers to send reports.", textAlign: TextAlign.center)),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.whatsappGroups.length,
              separatorBuilder: (c, i) => const Divider(),
              itemBuilder: (context, index) {
                final group = controller.whatsappGroups[index];
                final List phones = group['phones'] ?? [];
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(group['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${phones.length} recipients: ${phones.join(', ')}", maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showGroupDialog(context, controller, group),
                        tooltip: "Edit",
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, controller, group['id']),
                        tooltip: "Delete",
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAddGroupButton(BuildContext context, SettingsController controller) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: const Icon(Icons.add, size: 18),
      label: const Text("New Group"),
      onPressed: () => _showGroupDialog(context, controller, null),
    );
  }

  // === 2. REVENUE SECTION ===
  Widget _buildRevenueSection(BuildContext context, SettingsController controller, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF2D5016).withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.pie_chart, color: Color(0xFF2D5016)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Revenue Splits (Per Activity)", 
                  style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          
          Obx(() {
            if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.activities.length,
              separatorBuilder: (c, i) => const Divider(height: 40), // More space between items
              itemBuilder: (context, index) {
                final activity = controller.activities[index];
                double ecoparkVal = (activity['ecoparkPercent'] as num).toDouble();
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(activity['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (!isMobile)
                          Text(
                            "Park: ${ecoparkVal.toInt()}%  |  Facility: ${(100 - ecoparkVal).toInt()}%", 
                            style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)
                          ),
                      ],
                    ),
                    
                    // Mobile Only: Show percentage below title
                    if (isMobile) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Park: ${ecoparkVal.toInt()}%  |  Facility: ${(100 - ecoparkVal).toInt()}%", 
                        style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Slider Row
                    Row(
                      children: [
                        const Text("0%", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF2D5016),
                              inactiveTrackColor: Colors.grey[200],
                              thumbColor: const Color(0xFF2D5016),
                              overlayColor: const Color(0xFF2D5016).withValues(alpha:0.1),
                              valueIndicatorColor: const Color(0xFF2D5016),
                            ),
                            child: Slider(
                              value: ecoparkVal,
                              min: 0,
                              max: 100,
                              divisions: 20, 
                              label: "${ecoparkVal.toInt()}% Ecopark",
                              onChanged: (val) {
                                // Optional: Update local state for smooth slider dragging if needed
                                // But usually build rebuilds fast enough with Obx
                              }, 
                              onChangeEnd: (val) => controller.updateSplit(activity['id'], val),
                            ),
                          ),
                        ),
                        const Text("100% (Park)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                );
              },
            );
          }),
        ],
      ),
    );
  }

  // === DIALOGS ===
  void _showGroupDialog(BuildContext context, SettingsController controller, Map<String, dynamic>? group) {
    final nameCtrl = TextEditingController(text: group?['name'] ?? "");
    List<String> existingPhones = group != null ? List<String>.from(group['phones']) : [];
    final phoneCtrl = TextEditingController(text: existingPhones.join('\n'));

    // Responsive Dialog Size
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(group == null ? "Create New Group" : "Edit Group"),
        content: SizedBox(
          width: isMobile ? width * 0.9 : 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Group Name (e.g. Management)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Phone Numbers (One per line)", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: "024XXXXXXX\n055XXXXXXX",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Note: Type 1 Phone Contact per line here.", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5016), foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              
              List<String> phones = phoneCtrl.text
                  .split('\n')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();

              controller.saveGroup(group?['id'], nameCtrl.text, phones);
              Get.back(); // Close manually after save trigger
            },
            child: const Text("Save Group"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, SettingsController controller, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Group?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              controller.deleteGroup(id);
              Get.back();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
// import 'package:bunso_ecopark_admin/controllers/settings_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class SettingsView extends StatelessWidget {
//   const SettingsView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(SettingsController());

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("Global Settings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//             const Text("Configure revenue sharing and system preferences.", style: TextStyle(color: Colors.grey)),
//             const SizedBox(height: 30),

//             // === REVENUE SHARE CONFIGURATION ===
//             Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 10)],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(Icons.pie_chart, color: Color(0xFF2D5016)),
//                       const SizedBox(width: 10),
//                       const Text("Revenue Splits (Per Activity)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                   const Divider(height: 30),
                  
//                   Obx(() {
//                     if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());

//                     return ListView.separated(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: controller.activities.length,
//                       separatorBuilder: (c, i) => const Divider(),
//                       itemBuilder: (context, index) {
//                         final activity = controller.activities[index];
//                         double ecoparkVal = (activity['ecoparkPercent'] as num).toDouble();
                        
//                         return Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Header
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(activity['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                                 Text(
//                                   "Park: ${ecoparkVal.toInt()}%  |  Facility: ${(100 - ecoparkVal).toInt()}%", 
//                                   style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)
//                                 ),
//                               ],
//                             ),
                            
//                             // Slider
//                             Row(
//                               children: [
//                                 const Text("0%"),
//                                 Expanded(
//                                   child: Slider(
//                                     value: ecoparkVal,
//                                     min: 0,
//                                     max: 100,
//                                     divisions: 20, // 5% steps
//                                     activeColor: const Color(0xFF2D5016),
//                                     label: "${ecoparkVal.toInt()}% Ecopark",
//                                     onChanged: (val) {
//                                       // Optimistic update handled by slider visual, but real save on 'onChangeEnd'
//                                       // For GetX simplicity we update state via controller method directly usually, 
//                                       // but to avoid lag lets just save on end.
//                                     },
//                                     onChangeEnd: (val) {
//                                       controller.updateSplit(activity['id'], val);
//                                     },
//                                   ),
//                                 ),
//                                 const Text("100% (Park)"),
//                               ],
//                             ),
//                           ],
//                         );
//                       },
//                     );
//                   }),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }