 import 'package:bunso_ecopark_admin/controllers/report_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ReportView extends StatelessWidget {
  const ReportView({super.key});

  // Theme Colors
  static const primaryGreen = Color(0xFF2D5016);
  static const accentGreen = Color(0xFF4A7C2B);
  static const lightGreen = Color(0xFF5D9939);
  static const accentYellow = Color(0xFFFFC107);
  static const bgColor = Color(0xFFF5F7F0);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportController());
    final isDesktop = MediaQuery.of(context).size.width > 1024;
    final isTablet = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === HEADER & CONTROLS ===
            _buildHeader(context, controller, isDesktop, isTablet),
            const SizedBox(height: 30),

            // === FINANCIAL SUMMARY CARDS (2 rows of 4) ===
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: primaryGreen),
                  ),
                );
              }

              // Calculate totals
              double gross = controller.totalGross.value;
              double net = (100 / 121.9) * gross;
              double dev = gross * 0.05;
              double vat = gross - net;
              double shared = gross - dev - vat;
              
              // Calculate splits
              double ecoparkTotal = 0;
              double facilityTotal = 0;
              controller.reportRows.forEach((activity, data) {
                double ecoPct = controller.activitySplits[activity] ?? 80.0;
                double revenueToShare = data['shared']!;
                ecoparkTotal += revenueToShare * (ecoPct / 100);
                facilityTotal += revenueToShare * ((100 - ecoPct) / 100);
              });

              return Column(
                children: [
                  // First Row
                  _buildMetricsRow(
                    context,
                    isDesktop,
                    [
                      _MetricData("Gross Revenue (VAT Inc)", "GHS ${gross.toStringAsFixed(2)}", Icons.account_balance_wallet, accentGreen),
                      _MetricData("Net (W/O VAT)", "GHS ${net.toStringAsFixed(2)}", Icons.money_off, lightGreen),
                      _MetricData("5% Dev", "GHS ${dev.toStringAsFixed(2)}", Icons.build_circle, accentYellow),
                      _MetricData("Revenue to Share", "GHS ${shared.toStringAsFixed(2)}", Icons.share, primaryGreen),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 20 : 16),
                  // Second Row
                  _buildMetricsRow(
                    context,
                    isDesktop,
                    [
                      _MetricData("Ecopark Share", "GHS ${ecoparkTotal.toStringAsFixed(2)}", Icons.eco, accentGreen),
                      _MetricData("Facility Share", "GHS ${facilityTotal.toStringAsFixed(2)}", Icons.business, lightGreen),
                      _MetricData("VAT & Levies", "GHS ${vat.toStringAsFixed(2)}", Icons.receipt_long, Colors.orange[700]!),
                      _MetricData("Active Activities", "${controller.reportRows.length}", Icons.attractions, accentYellow),
                    ],
                  ),
                ],
              );
            }),

            const SizedBox(height: 40),

            // === INTELLIGENCE CHARTS ===
            Row(
              children: [
                const Text("Operational Intelligence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),

            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: primaryGreen));
              }

              return Column(
                children: [
                  // Charts Row 1
                  _buildChartsRow(
                    context,
                    isDesktop,
                    isTablet,
                    [
                      _buildChartCard(
                        title: "Peak Hours (Busiest Times)",
                        subtitle: "Revenue distribution by hour of day",
                        height: 380,
                        child: _buildHourlyChart(controller.peakHours),
                      ),
                      _buildChartCard(
                        title: "Weekly Rhythm",
                        subtitle: "Which days generate the most revenue?",
                        height: 380,
                        child: _buildWeeklyChart(controller.weeklyRhythm),
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 20 : 16),

                  // Charts Row 2 - Revenue Distribution Pie Chart
                  _buildChartCard(
                    title: "Revenue Distribution by Activity",
                    subtitle: "Top performing activities and their contribution",
                    height: isDesktop ? 450 : 400,
                    child: _buildRevenueDistributionChart(controller.reportRows),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // === HELPER WIDGETS ===

  Widget _buildHeader(BuildContext context, ReportController controller, bool isDesktop, bool isTablet) {
    if (!isTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Reports & Intelligence",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryGreen),
          ),
          const SizedBox(height: 8),
          Text(
            "Export financial data and analyze operational trends",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 20),
          _buildDatePicker(context, controller),
          const SizedBox(height: 12),
          _buildExportButton(controller),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Reports & Intelligence",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryGreen),
              ),
              const SizedBox(height: 8),
              Text(
                "Export financial data and analyze operational trends",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Row(
          children: [
            _buildDatePicker(context, controller),
            const SizedBox(width: 12),
            _buildExportButton(controller),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context, ReportController controller) {
    return Obx(() {
      String start = DateFormat('MMM dd, yyyy').format(controller.dateRange.value.start);
      String end = DateFormat('MMM dd, yyyy').format(controller.dateRange.value.end);
      return OutlinedButton.icon(
        icon: const Icon(Icons.calendar_month, color: primaryGreen),
        label: Text(
          "$start - $end",
          style: const TextStyle(color: primaryGreen),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          backgroundColor: Colors.white,
          side: const BorderSide(color: primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 1)),
            initialDateRange: controller.dateRange.value,
            builder: (context, child) {
              return Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: primaryGreen,
                    onPrimary: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) controller.updateDateRange(picked);
        },
      );
    });
  }

  Widget _buildExportButton(ReportController controller) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      icon: const Icon(Icons.download, size: 20),
      label: const Text("Export CSV", style: TextStyle(fontWeight: FontWeight.w600)),
      onPressed: () => controller.exportToCsv(),
    );
  }

  Widget _buildMetricsRow(BuildContext context, bool isDesktop, List<_MetricData> metrics) {
    if (!isDesktop) {
      return Column(
        children: metrics
            .map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMetricCard(m),
                ))
            .toList(),
      );
    }

    return Row(
      children: metrics
          .map((m) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildMetricCard(m),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildMetricCard(_MetricData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsRow(BuildContext context, bool isDesktop, bool isTablet, List<Widget> charts) {
    if (!isTablet) {
      return Column(
        children: charts.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: charts
          .map((c) => Expanded(
                child: Padding(padding: const EdgeInsets.only(right: 16), child: c),
              ))
          .toList(),
    );
  }

  Widget _buildChartCard({required String title, required String subtitle, required Widget child, double height = 320}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const Divider(height: 30, color: Color(0xFFE0E0E0)),
          Expanded(child: child),
        ],
      ),
    );
  }

  // === CHART BUILDERS ===

  Widget _buildHourlyChart(Map<int, double> data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, right: 10),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (data.values.isEmpty ? 100 : data.values.reduce((a, b) => a > b ? a : b)) * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => primaryGreen,
               tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${group.x}:00\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  children: [
                    TextSpan(
                      text: 'GHS ${rod.toY.toStringAsFixed(2)}',
                      style: const TextStyle(color: accentYellow, fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              axisNameWidget: const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('Hour of Day', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              ),
              axisNameSize: 30,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (val, meta) {
                  int h = val.toInt();
                  if (h % 3 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text("${h}h", style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(24, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data[index] ?? 0,
                  gradient: LinearGradient(
                    colors: [accentGreen, lightGreen],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(Map<int, double> data) {
    List<String> days = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, right: 10),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (data.values.isEmpty ? 100 : data.values.reduce((a, b) => a > b ? a : b)) * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => primaryGreen,
               tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${days[group.x]}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  children: [
                    TextSpan(
                      text: 'GHS ${rod.toY.toStringAsFixed(2)}',
                      style: const TextStyle(color: accentYellow, fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              axisNameWidget: const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('Day of Week', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              ),
              axisNameSize: 30,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (val, meta) {
                  int d = val.toInt();
                  if (d >= 1 && d <= 7) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(days[d], style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            int day = index + 1;
            bool isWeekend = (day == 6 || day == 7);
            return BarChartGroupData(
              x: day,
              barRods: [
                BarChartRodData(
                  toY: data[day] ?? 0,
                  gradient: LinearGradient(
                    colors: isWeekend ? [accentYellow, Colors.orange] : [accentGreen, lightGreen],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                )
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRevenueDistributionChart(Map<String, Map<String, double>> data) {
    if (data.isEmpty) return const Center(child: Text("No Data", style: TextStyle(color: Colors.grey)));

    // Sort activities by gross revenue
    var sortedEntries = data.entries.toList()..sort((a, b) => b.value['gross']!.compareTo(a.value['gross']!));
    
    // Take top 6 activities
    var topActivities = sortedEntries.take(6).toList();
    double total = topActivities.fold(0, (sum, entry) => sum + entry.value['gross']!);

    List<Color> colors = [
      primaryGreen,
      accentGreen,
      lightGreen,
      accentYellow,
      Colors.orange,
      Colors.teal,
    ];

    return Row(
      children: [
        // Pie Chart with Interactive Touch
        Expanded(
          flex: 2,
          child: _PieChartWidget(
            activities: topActivities,
            colors: colors,
            total: total,
          ),
        ),
        // Legend
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: topActivities.asMap().entries.map((entry) {
                int idx = entry.key;
                var activity = entry.value;
                String name = activity.key;
                String displayName = name.length > 15 ? "${name.substring(0, 13)}.." : name;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colors[idx % colors.length],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'GHS ${activity.value['gross']!.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// Stateful Widget for Interactive Pie Chart
class _PieChartWidget extends StatefulWidget {
  final List<MapEntry<String, Map<String, double>>> activities;
  final List<Color> colors;
  final double total;

  const _PieChartWidget({
    required this.activities,
    required this.colors,
    required this.total,
  });

  @override
  State<_PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<_PieChartWidget> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: List.generate(widget.activities.length, (i) {
          final isTouched = i == touchedIndex;
          final fontSize = isTouched ? 16.0 : 14.0;
          final radius = isTouched ? 110.0 : 100.0;
          final widgetSize = isTouched ? 60.0 : 50.0;
          
          var entry = widget.activities[i];
          double value = entry.value['gross']!;
          double percentage = (value / widget.total) * 100;

          return PieChartSectionData(
            color: widget.colors[i % widget.colors.length],
            value: value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(color: Colors.black26, blurRadius: 2),
              ],
            ),
            badgeWidget: isTouched
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.key.length > 10 ? "${entry.key.substring(0, 8)}.." : entry.key,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: ReportView.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'GHS ${value.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
            badgePositionPercentageOffset: 1.3,
          );
        }),
      ),
    );
  }
}

// Helper class for metrics
class _MetricData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _MetricData(this.title, this.value, this.icon, this.color);
}
// import 'package:bunso_ecopark_admin/controllers/report_controller.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// class ReportView extends StatelessWidget {
//   const ReportView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(ReportController());

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // === HEADER & CONTROLS ===
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text("Reports & Intelligence", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//                     const Text("Export financial data and analyze operational trends.", style: TextStyle(color: Colors.grey)),
//                   ],
//                 ),
                
//                 Row(
//                   children: [
//                     // Date Picker
//                     Obx(() {
//                       String start = DateFormat('MMM dd, yyyy').format(controller.dateRange.value.start);
//                       String end = DateFormat('MMM dd, yyyy').format(controller.dateRange.value.end);
//                       return OutlinedButton.icon(
//                         icon: const Icon(Icons.calendar_month),
//                         label: Text("$start - $end"),
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
//                           backgroundColor: Colors.white,
//                         ),
//                         onPressed: () async {
//                           final picked = await showDateRangePicker(
//                             context: context,
//                             firstDate: DateTime(2020),
//                             lastDate: DateTime.now().add(const Duration(days: 1)),
//                             initialDateRange: controller.dateRange.value,
//                           );
//                           if (picked != null) controller.updateDateRange(picked);
//                         },
//                       );
//                     }),
                    
//                     const SizedBox(width: 12),

//                     // EXPORT BUTTON
//                     ElevatedButton.icon(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF2D5016),
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
//                       ),
//                       icon: const Icon(Icons.download),
//                       label: const Text("Export to CSV"),
//                       onPressed: () => controller.exportToCsv(),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 30),

//             // === FINANCIAL SUMMARY CARDS ===
//             Obx(() {
//                if(controller.isLoading.value) return const LinearProgressIndicator();
               
//                return Row(
//                  children: [
//                    _buildSummaryCard("Total Gross Revenue", "GHS ${controller.totalGross.value.toStringAsFixed(2)}", Icons.attach_money, Colors.green),
//                    const SizedBox(width: 20),
//                    _buildSummaryCard("Active Activities", "${controller.reportRows.length}", Icons.attractions, Colors.orange),
//                  ],
//                );
//             }),
            
//             const SizedBox(height: 30),

//             // === INTELLIGENCE CHARTS ===
//             const Text("Operational Intelligence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 15),

//             Obx(() {
//               if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());

//               return Column(
//                 children: [
//                   Row(
//                     children: [
//                       // 1. PEAK HOURS CHART
//                       Expanded(
//                         child: _buildChartCard(
//                           title: "Peak Hours (Busiest Times)",
//                           subtitle: "Revenue distribution by hour of day",
//                           child: _buildHourlyChart(controller.peakHours),
//                         ),
//                       ),
//                       const SizedBox(width: 20),
//                       // 2. WEEKLY RHYTHM CHART
//                       Expanded(
//                         child: _buildChartCard(
//                           title: "Weekly Rhythm",
//                           subtitle: "Which days generate the most revenue?",
//                           child: _buildWeeklyChart(controller.weeklyRhythm),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // 3. TICKET TIERS BREAKDOWN
//                   _buildChartCard(
//                     title: "Ticket Tier Analysis",
//                     subtitle: "Adult vs. Child/Student Breakdown per Activity",
//                     height: 400,
//                     child: _buildStackedTierChart(controller.ticketTiers),
//                   ),
//                 ],
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }

//   // === WIDGET HELPERS ===

//   Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
//               child: Icon(icon, color: color, size: 28),
//             ),
//             const SizedBox(width: 16),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
//                 Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildChartCard({required String title, required String subtitle, required Widget child, double height = 300}) {
//     return Container(
//       height: height,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//           Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
//           const Divider(height: 30),
//           Expanded(child: child),
//         ],
//       ),
//     );
//   }

//   // --- CHART 1: HOURLY HEATMAP (Bar) ---
//   Widget _buildHourlyChart(Map<int, double> data) {
//     return BarChart(
//       BarChartData(
//         alignment: BarChartAlignment.spaceAround,
//         maxY: (data.values.isEmpty ? 100 : data.values.reduce((a, b) => a > b ? a : b)) * 1.2,
//         titlesData: FlTitlesData(
//           bottomTitles: AxisTitles(
//              sideTitles: SideTitles(
//                showTitles: true,
//                getTitlesWidget: (val, meta) {
//                  int h = val.toInt();
//                  if (h % 3 == 0) return Text("${h}h", style: const TextStyle(fontSize: 10, color: Colors.grey));
//                  return const SizedBox.shrink();
//                },
//              )
//           ),
//           leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         ),
//         gridData: const FlGridData(show: false),
//         borderData: FlBorderData(show: false),
//         barGroups: List.generate(24, (index) {
//           return BarChartGroupData(
//             x: index,
//             barRods: [
//               BarChartRodData(
//                 toY: data[index] ?? 0,
//                 color: Colors.blue.withOpacity(0.7),
//                 width: 8,
//                 borderRadius: BorderRadius.circular(2),
//               )
//             ],
//           );
//         }),
//       ),
//     );
//   }

//   // --- CHART 2: WEEKLY RHYTHM (Bar) ---
//   Widget _buildWeeklyChart(Map<int, double> data) {
//     List<String> days = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
//     return BarChart(
//       BarChartData(
//         alignment: BarChartAlignment.spaceAround,
//         titlesData: FlTitlesData(
//           bottomTitles: AxisTitles(
//              sideTitles: SideTitles(
//                showTitles: true,
//                getTitlesWidget: (val, meta) {
//                  int d = val.toInt();
//                  if (d >= 1 && d <= 7) return Text(days[d], style: const TextStyle(fontSize: 10, color: Colors.grey));
//                  return const SizedBox.shrink();
//                },
//              )
//           ),
//           leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         ),
//         gridData: const FlGridData(show: false),
//         borderData: FlBorderData(show: false),
//         barGroups: List.generate(7, (index) {
//           int day = index + 1;
//           return BarChartGroupData(
//             x: day,
//             barRods: [
//               BarChartRodData(
//                 toY: data[day] ?? 0,
//                 color: (day == 6 || day == 7) ? Colors.orange : Colors.indigo, // Highlight Weekends
//                 width: 16,
//                 borderRadius: BorderRadius.circular(4),
//               )
//             ],
//           );
//         }),
//       ),
//     );
//   }

//   // --- CHART 3: STACKED TIERS (Activity Breakdown) ---
//   Widget _buildStackedTierChart(Map<String, Map<String, int>> data) {
//     if (data.isEmpty) return const Center(child: Text("No Data"));
    
//     // Sort by total volume
//     var sortedKeys = data.keys.toList();
    
//     return BarChart(
//       BarChartData(
//         alignment: BarChartAlignment.spaceAround,
//         titlesData: FlTitlesData(
//           bottomTitles: AxisTitles(
//              sideTitles: SideTitles(
//                showTitles: true,
//                getTitlesWidget: (val, meta) {
//                  int i = val.toInt();
//                  if (i >= 0 && i < sortedKeys.length) {
//                    // Truncate name if too long
//                    String name = sortedKeys[i];
//                    if(name.length > 8) name = "${name.substring(0,6)}..";
//                    return Padding(padding: const EdgeInsets.only(top: 5), child: Text(name, style: const TextStyle(fontSize: 10)));
//                  }
//                  return const SizedBox.shrink();
//                },
//              )
//           ),
//           leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         ),
//         gridData: const FlGridData(show: false),
//         borderData: FlBorderData(show: false),
//         barGroups: sortedKeys.asMap().entries.map((e) {
//           int index = e.key;
//           String act = e.value;
//           Map<String, int> tiers = data[act]!;
          
//           double y1 = (tiers['Adult'] ?? 0).toDouble(); // Adult
//           double y2 = (tiers['Student'] ?? tiers['Child'] ?? 0).toDouble(); // Other
          
//           return BarChartGroupData(
//             x: index,
//             barRods: [
//               BarChartRodData(
//                 toY: y1 + y2,
//                 width: 20,
//                 borderRadius: BorderRadius.circular(4),
//                 rodStackItems: [
//                   BarChartRodStackItem(0, y1, const Color(0xFF2D5016)), // Adult (Green)
//                   BarChartRodStackItem(y1, y1 + y2, Colors.orangeAccent), // Child (Orange)
//                 ],
//               )
//             ],
//           );
//         }).toList(),
//       ),
//     );
//   }
// }