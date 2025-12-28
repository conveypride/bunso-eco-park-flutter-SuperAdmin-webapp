import 'package:bunso_ecopark_admin/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Global Settings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("Configure revenue sharing and system preferences.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            // === REVENUE SHARE CONFIGURATION ===
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pie_chart, color: Color(0xFF2D5016)),
                      const SizedBox(width: 10),
                      const Text("Revenue Splits (Per Activity)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 30),
                  
                  Obx(() {
                    if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.activities.length,
                      separatorBuilder: (c, i) => const Divider(),
                      itemBuilder: (context, index) {
                        final activity = controller.activities[index];
                        double ecoparkVal = (activity['ecoparkPercent'] as num).toDouble();
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(activity['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  "Park: ${ecoparkVal.toInt()}%  |  Facility: ${(100 - ecoparkVal).toInt()}%", 
                                  style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)
                                ),
                              ],
                            ),
                            
                            // Slider
                            Row(
                              children: [
                                const Text("0%"),
                                Expanded(
                                  child: Slider(
                                    value: ecoparkVal,
                                    min: 0,
                                    max: 100,
                                    divisions: 20, // 5% steps
                                    activeColor: const Color(0xFF2D5016),
                                    label: "${ecoparkVal.toInt()}% Ecopark",
                                    onChanged: (val) {
                                      // Optimistic update handled by slider visual, but real save on 'onChangeEnd'
                                      // For GetX simplicity we update state via controller method directly usually, 
                                      // but to avoid lag lets just save on end.
                                    },
                                    onChangeEnd: (val) {
                                      controller.updateSplit(activity['id'], val);
                                    },
                                  ),
                                ),
                                const Text("100% (Park)"),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}