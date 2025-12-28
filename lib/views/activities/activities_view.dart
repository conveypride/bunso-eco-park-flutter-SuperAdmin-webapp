import 'package:bunso_ecopark_admin/controllers/activities_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ActivitiesView extends StatelessWidget {
  const ActivitiesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ActivitiesController());

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
                const Text("Activity & Pricing Manager", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5016),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Add New Activity"),
                  onPressed: () => _showActivityDialog(context, controller, null),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text("Manage attractions and their price tiers here. Changes sync to tablets immediately.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            // === ACTIVITY GRID ===
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());

                if (controller.activities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.attractions, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        const Text("No activities found. Add one!", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // Responsive Grid
                double width = MediaQuery.of(context).size.width;
                int crossAxisCount = width > 1200 ? 3 : (width > 800 ? 2 : 1);

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: controller.activities.length,
                  itemBuilder: (context, index) {
                    final activity = controller.activities[index];
                    return _buildActivityCard(context, activity, controller);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, Map<String, dynamic> activity, ActivitiesController controller) {
    List tiers = activity['priceTiers'] ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  activity['name'], 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D5016))
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text("Edit Prices")),
                    const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                  ],
                  onSelected: (val) {
                    if (val == 'edit') _showActivityDialog(context, controller, activity);
                    if (val == 'delete') controller.deleteActivity(activity['id']);
                  },
                ),
              ],
            ),
            const Divider(),
            
            // Price Tiers List
            Expanded(
              child: ListView.builder(
                itemCount: tiers.length,
                itemBuilder: (context, i) {
                  final tier = tiers[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tier['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          "GHS ${(tier['price'] as num).toStringAsFixed(2)}", 
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === THE EDIT DIALOG ===
  void _showActivityDialog(BuildContext context, ActivitiesController controller, Map<String, dynamic>? activity) {
    final nameCtrl = TextEditingController(text: activity?['name'] ?? '');
    
    // Tiers State (We use a reactive list inside the dialog)
    RxList<Map<String, dynamic>> tempTiers = <Map<String, dynamic>>[].obs;
    
    if (activity != null && activity['priceTiers'] != null) {
      for (var t in activity['priceTiers']) {
        tempTiers.add({'name': t['name'], 'price': t['price']});
      }
    } else {
      // Default tiers for new activity
      tempTiers.add({'name': 'Adult (GH)', 'price': 0.0});
      tempTiers.add({'name': 'Adult (Foreign)', 'price': 0.0});
      tempTiers.add({'name': 'Child (GH)', 'price': 0.0});
      tempTiers.add({'name': 'Child (Foreign)', 'price': 0.0});
    }

    Get.defaultDialog(
      title: activity == null ? "New Activity" : "Edit Activity",
      content: SizedBox(
        width: 400,
        height: 400, // Fixed height for scrolling
        child: Column(
          children: [
            TextField(
              controller: nameCtrl, 
              decoration: const InputDecoration(labelText: "Activity Name (e.g. Zipline)", border: OutlineInputBorder())
            ),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text("Price Tiers", style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            
            // Dynamic Tier List
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: tempTiers.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: tempTiers[i]['name'],
                            decoration: const InputDecoration(labelText: "Tier Name", isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) => tempTiers[i]['name'] = val,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            initialValue: tempTiers[i]['price'].toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Price", isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) => tempTiers[i]['price'] = double.tryParse(val) ?? 0.0,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => tempTiers.removeAt(i),
                        )
                      ],
                    ),
                  );
                },
              )),
            ),
            
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Tier"),
              onPressed: () => tempTiers.add({'name': 'New Tier', 'price': 0.0}),
            )
          ],
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5016), foregroundColor: Colors.white),
        onPressed: () {
          if (nameCtrl.text.isEmpty) return;
          controller.saveActivity(
            id: activity?['id'],
            name: nameCtrl.text,
            tiers: tempTiers,
          );
        },
        child: const Text("Save Changes"),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
    );
  }
}