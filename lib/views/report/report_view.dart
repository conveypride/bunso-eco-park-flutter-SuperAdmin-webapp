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

            // === FINANCIAL SUMMARY CARDS ===
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
            const Text("Operational Intelligence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: primaryGreen));
              }

              return Column(
                children: [
                  // Row 1: Hourly & Weekly
                  _buildChartsRow(
                    context,
                    isDesktop,
                    isTablet,
                    [
                      _buildChartCard(
                        title: "Peak Hours",
                        subtitle: "Revenue by hour",
                        height: 380,
                        child: _buildHourlyChart(controller.peakHours),
                      ),
                      _buildChartCard(
                        title: "Weekly Rhythm",
                        subtitle: "Revenue by day",
                        height: 380,
                        child: _buildWeeklyChart(controller.weeklyRhythm),
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 20 : 16),

                  // Row 2: Revenue Distribution (RESPONSIVE)
                  _buildChartCard(
                    title: "Revenue Distribution by Activity",
                    subtitle: "Top performing activities contribution",
                    // Increase height slightly on desktop for better visibility
                    height: isDesktop ? 450 : 550, 
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

  // === UPDATED: RESPONSIVE PIE CHART ===
  Widget _buildRevenueDistributionChart(Map<String, Map<String, double>> data) {
    if (data.isEmpty) return const Center(child: Text("No Data", style: TextStyle(color: Colors.grey)));

    // Sort and Prepare Data
    var sortedEntries = data.entries.toList()..sort((a, b) => b.value['gross']!.compareTo(a.value['gross']!));
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

    // Use LayoutBuilder to decide layout based on available width
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint: If width is less than 600, switch to Vertical layout
        bool isNarrow = constraints.maxWidth < 600;

        // 1. The Pie Chart Widget
        Widget chartWidget = _PieChartWidget(
          activities: topActivities,
          colors: colors,
          total: total,
          // Make radius dynamic based on screen size
          baseRadius: isNarrow ? 80 : 100, 
        );

        // 2. The Legend Widget
        Widget legendWidget = SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: topActivities.asMap().entries.map((entry) {
              int idx = entry.key;
              var activity = entry.value;
              String name = activity.key;
              
              // Truncate long names
              String displayName = name.length > 20 ? "${name.substring(0, 18)}.." : name;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                    Flexible(
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
        );

        // 3. Return Layout based on width
        if (isNarrow) {
          // === MOBILE LAYOUT (Column) ===
          return Column(
            children: [
              Expanded(flex: 3, child: chartWidget),
              const SizedBox(height: 20),
              Expanded(
                flex: 2, 
                child: SizedBox(
                  width: double.infinity,
                  // Use Wrap or Grid for legend on mobile if needed, or simple column
                  child: legendWidget, 
                ),
              ),
            ],
          );
        } else {
          // === DESKTOP/TABLET LAYOUT (Row) ===
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: chartWidget),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: legendWidget),
            ],
          );
        }
      },
    );
  }

  // ... [Keep existing _buildHeader, _buildDatePicker, _buildExportButton, _buildMetricsRow, _buildMetricCard, _buildChartsRow, _buildChartCard, _buildHourlyChart, _buildWeeklyChart exactly as they were] ...
  
  // (Paste the existing helper widgets here from your previous code to keep the file complete)
  Widget _buildHeader(BuildContext context, ReportController controller, bool isDesktop, bool isTablet) {
    if (!isTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Reports & Intelligence", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryGreen)),
          const SizedBox(height: 8),
          Text("Export financial data and analyze operational trends", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
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
              const Text("Reports & Intelligence", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryGreen)),
              const SizedBox(height: 8),
              Text("Export financial data and analyze operational trends", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Row(children: [_buildDatePicker(context, controller), const SizedBox(width: 12), _buildExportButton(controller)]),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context, ReportController controller) {
    return Obx(() {
      String start = DateFormat('MMM dd, yyyy').format(controller.dateRange.value.start);
      String end = DateFormat('MMM dd, yyyy').format(controller.dateRange.value.end);
      return OutlinedButton.icon(
        icon: const Icon(Icons.calendar_month, color: primaryGreen),
        label: Text("$start - $end", style: const TextStyle(color: primaryGreen)),
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
            builder: (context, child) => Theme(
              data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: primaryGreen, onPrimary: Colors.white)),
              child: child!,
            ),
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
      ),
      icon: const Icon(Icons.download, size: 20),
      label: const Text("Export CSV", style: TextStyle(fontWeight: FontWeight.w600)),
      onPressed: () => controller.exportToCsv(),
    );
  }

  Widget _buildMetricsRow(BuildContext context, bool isDesktop, List<_MetricData> metrics) {
    if (!isDesktop) return Column(children: metrics.map((m) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildMetricCard(m))).toList());
    return Row(children: metrics.map((m) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: _buildMetricCard(m)))).toList());
  }

  Widget _buildMetricCard(_MetricData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(data.title, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500))), Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: data.color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(10)), child: Icon(data.icon, color: data.color, size: 20))]),
          const SizedBox(height: 12),
          Text(data.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: primaryGreen)),
        ],
      ),
    );
  }

  Widget _buildChartsRow(BuildContext context, bool isDesktop, bool isTablet, List<Widget> charts) {
    if (!isTablet) return Column(children: charts.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList());
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: charts.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: c))).toList());
  }

  Widget _buildChartCard({required String title, required String subtitle, required Widget child, double height = 320}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryGreen)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)), const Divider(height: 30, color: Color(0xFFE0E0E0)), Expanded(child: child)]),
    );
  }

  Widget _buildHourlyChart(Map<int, double> data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, right: 10),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (data.values.isEmpty ? 100 : data.values.reduce((a, b) => a > b ? a : b)) * 1.2,
          barTouchData: BarTouchData(enabled: true, touchTooltipData: BarTouchTooltipData(getTooltipColor: (_) => primaryGreen, tooltipBorderRadius: BorderRadius.circular(8))),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (val, _) { int h = val.toInt(); return h % 3 == 0 ? Text("${h}h", style: const TextStyle(fontSize: 11, color: Colors.grey)) : const SizedBox.shrink(); })),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha:0.1), strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(24, (index) => BarChartGroupData(x: index, barRods: [BarChartRodData(toY: data[index] ?? 0, gradient: LinearGradient(colors: [accentGreen, lightGreen], begin: Alignment.bottomCenter, end: Alignment.topCenter), width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))])),
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
          barTouchData: BarTouchData(enabled: true, touchTooltipData: BarTouchTooltipData(getTooltipColor: (_) => primaryGreen, tooltipBorderRadius: BorderRadius.circular(8))),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (val, _) { int d = val.toInt(); return (d >= 1 && d <= 7) ? Text(days[d], style: const TextStyle(fontSize: 11, color: Colors.grey)) : const SizedBox.shrink(); })),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha:0.1), strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            int day = index + 1;
            bool isWeekend = (day == 6 || day == 7);
            return BarChartGroupData(x: day, barRods: [BarChartRodData(toY: data[day] ?? 0, gradient: LinearGradient(colors: isWeekend ? [accentYellow, Colors.orange] : [accentGreen, lightGreen], begin: Alignment.bottomCenter, end: Alignment.topCenter), width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]);
          }),
        ),
      ),
    );
  }
}

// === UPDATED STATEFUL WIDGET FOR INTERACTIVE CHART ===
class _PieChartWidget extends StatefulWidget {
  final List<MapEntry<String, Map<String, double>>> activities;
  final List<Color> colors;
  final double total;
  final double baseRadius; // Added this

  const _PieChartWidget({
    required this.activities,
    required this.colors,
    required this.total,
    required this.baseRadius,
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
        centerSpaceRadius: widget.baseRadius * 0.5, // 50% of base radius
        sections: List.generate(widget.activities.length, (i) {
          final isTouched = i == touchedIndex;
          final fontSize = isTouched ? 16.0 : 12.0;
          final radius = isTouched ? widget.baseRadius * 1.1 : widget.baseRadius;
          
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
              shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
            ),
            // Optional: Hide badges on very small screens if they overlap
            badgeWidget: isTouched ? _buildBadge(entry.key, value) : null,
            badgePositionPercentageOffset: 1.3,
          );
        }),
      ),
    );
  }

  Widget _buildBadge(String name, double value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.2), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name.length > 10 ? "${name.substring(0, 8)}.." : name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ReportView.primaryGreen)),
          const SizedBox(height: 2),
          Text('GHS ${value.toStringAsFixed(0)}', style: TextStyle(fontSize: 9, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  _MetricData(this.title, this.value, this.icon, this.color);
}
//  import 'package:bunso_ecopark_admin/controllers/report_controller.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// class ReportView extends StatelessWidget {
//   const ReportView({super.key});

//   // Theme Colors
//   static const primaryGreen = Color(0xFF2D5016);
//   static const accentGreen = Color(0xFF4A7C2B);
//   static const lightGreen = Color(0xFF5D9939);
//   static const accentYellow = Color(0xFFFFC107);
//   static const bgColor = Color(0xFFF5F7F0);

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(ReportController());
//     final isDesktop = MediaQuery.of(context).size.width > 1024;
//     final isTablet = MediaQuery.of(context).size.width > 768;

//     return Scaffold(
//       backgroundColor: bgColor,
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // === HEADER & CONTROLS ===
//             _buildHeader(context, controller, isDesktop, isTablet),
//             const SizedBox(height: 30),

//             // === FINANCIAL SUMMARY CARDS (2 rows of 4) ===
//             Obx(() {
//               if (controller.isLoading.value) {
//                 return const Center(
//                   child: Padding(
//                     padding: EdgeInsets.all(40.0),
//                     child: CircularProgressIndicator(color: primaryGreen),
//                   ),
//                 );
//               }

//               // Calculate totals
//               double gross = controller.totalGross.value;
//               double net = (100 / 121.9) * gross;
//               double dev = gross * 0.05;
//               double vat = gross - net;
//               double shared = gross - dev - vat;
              
//               // Calculate splits
//               double ecoparkTotal = 0;
//               double facilityTotal = 0;
//               controller.reportRows.forEach((activity, data) {
//                 double ecoPct = controller.activitySplits[activity] ?? 80.0;
//                 double revenueToShare = data['shared']!;
//                 ecoparkTotal += revenueToShare * (ecoPct / 100);
//                 facilityTotal += revenueToShare * ((100 - ecoPct) / 100);
//               });

//               return Column(
//                 children: [
//                   // First Row
//                   _buildMetricsRow(
//                     context,
//                     isDesktop,
//                     [
//                       _MetricData("Gross Revenue (VAT Inc)", "GHS ${gross.toStringAsFixed(2)}", Icons.account_balance_wallet, accentGreen),
//                       _MetricData("Net (W/O VAT)", "GHS ${net.toStringAsFixed(2)}", Icons.money_off, lightGreen),
//                       _MetricData("5% Dev", "GHS ${dev.toStringAsFixed(2)}", Icons.build_circle, accentYellow),
//                       _MetricData("Revenue to Share", "GHS ${shared.toStringAsFixed(2)}", Icons.share, primaryGreen),
//                     ],
//                   ),
//                   SizedBox(height: isDesktop ? 20 : 16),
//                   // Second Row
//                   _buildMetricsRow(
//                     context,
//                     isDesktop,
//                     [
//                       _MetricData("Ecopark Share", "GHS ${ecoparkTotal.toStringAsFixed(2)}", Icons.eco, accentGreen),
//                       _MetricData("Facility Share", "GHS ${facilityTotal.toStringAsFixed(2)}", Icons.business, lightGreen),
//                       _MetricData("VAT & Levies", "GHS ${vat.toStringAsFixed(2)}", Icons.receipt_long, Colors.orange[700]!),
//                       _MetricData("Active Activities", "${controller.reportRows.length}", Icons.attractions, accentYellow),
//                     ],
//                   ),
//                 ],
//               );
//             }),

//             const SizedBox(height: 40),

//             // === INTELLIGENCE CHARTS ===
//             Row(
//               children: [
//                 const Text("Operational Intelligence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               ],
//             ),
//             const SizedBox(height: 20),

//             Obx(() {
//               if (controller.isLoading.value) {
//                 return const Center(child: CircularProgressIndicator(color: primaryGreen));
//               }

//               return Column(
//                 children: [
//                   // Charts Row 1
//                   _buildChartsRow(
//                     context,
//                     isDesktop,
//                     isTablet,
//                     [
//                       _buildChartCard(
//                         title: "Peak Hours (Busiest Times)",
//                         subtitle: "Revenue distribution by hour of day",
//                         height: 380,
//                         child: _buildHourlyChart(controller.peakHours),
//                       ),
//                       _buildChartCard(
//                         title: "Weekly Rhythm",
//                         subtitle: "Which days generate the most revenue?",
//                         height: 380,
//                         child: _buildWeeklyChart(controller.weeklyRhythm),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: isDesktop ? 20 : 16),

//                   // Charts Row 2 - Revenue Distribution Pie Chart
//                   _buildChartCard(
//                     title: "Revenue Distribution by Activity",
//                     subtitle: "Top performing activities and their contribution",
//                     height: isDesktop ? 450 : 400,
//                     child: _buildRevenueDistributionChart(controller.reportRows),
//                   ),
//                 ],
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }

//   // === HELPER WIDGETS ===

//   Widget _buildHeader(BuildContext context, ReportController controller, bool isDesktop, bool isTablet) {
//     if (!isTablet) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "Reports & Intelligence",
//             style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryGreen),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Export financial data and analyze operational trends",
//             style: TextStyle(color: Colors.grey[600], fontSize: 14),
//           ),
//           const SizedBox(height: 20),
//           _buildDatePicker(context, controller),
//           const SizedBox(height: 12),
//           _buildExportButton(controller),
//         ],
//       );
//     }

//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Reports & Intelligence",
//                 style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryGreen),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "Export financial data and analyze operational trends",
//                 style: TextStyle(color: Colors.grey[600], fontSize: 14),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 20),
//         Row(
//           children: [
//             _buildDatePicker(context, controller),
//             const SizedBox(width: 12),
//             _buildExportButton(controller),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildDatePicker(BuildContext context, ReportController controller) {
//     return Obx(() {
//       String start = DateFormat('MMM dd, yyyy').format(controller.dateRange.value.start);
//       String end = DateFormat('MMM dd, yyyy').format(controller.dateRange.value.end);
//       return OutlinedButton.icon(
//         icon: const Icon(Icons.calendar_month, color: primaryGreen),
//         label: Text(
//           "$start - $end",
//           style: const TextStyle(color: primaryGreen),
//         ),
//         style: OutlinedButton.styleFrom(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
//           backgroundColor: Colors.white,
//           side: const BorderSide(color: primaryGreen, width: 1.5),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//         onPressed: () async {
//           final picked = await showDateRangePicker(
//             context: context,
//             firstDate: DateTime(2020),
//             lastDate: DateTime.now().add(const Duration(days: 1)),
//             initialDateRange: controller.dateRange.value,
//             builder: (context, child) {
//               return Theme(
//                 data: ThemeData.light().copyWith(
//                   colorScheme: const ColorScheme.light(
//                     primary: primaryGreen,
//                     onPrimary: Colors.white,
//                   ),
//                 ),
//                 child: child!,
//               );
//             },
//           );
//           if (picked != null) controller.updateDateRange(picked);
//         },
//       );
//     });
//   }

//   Widget _buildExportButton(ReportController controller) {
//     return ElevatedButton.icon(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: primaryGreen,
//         foregroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         elevation: 2,
//       ),
//       icon: const Icon(Icons.download, size: 20),
//       label: const Text("Export CSV", style: TextStyle(fontWeight: FontWeight.w600)),
//       onPressed: () => controller.exportToCsv(),
//     );
//   }

//   Widget _buildMetricsRow(BuildContext context, bool isDesktop, List<_MetricData> metrics) {
//     if (!isDesktop) {
//       return Column(
//         children: metrics
//             .map((m) => Padding(
//                   padding: const EdgeInsets.only(bottom: 12),
//                   child: _buildMetricCard(m),
//                 ))
//             .toList(),
//       );
//     }

//     return Row(
//       children: metrics
//           .map((m) => Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.only(right: 16),
//                   child: _buildMetricCard(m),
//                 ),
//               ))
//           .toList(),
//     );
//   }

//   Widget _buildMetricCard(_MetricData data) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha:0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Text(
//                   data.title,
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 13,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: data.color.withValues(alpha:0.1),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(data.icon, color: data.color, size: 20),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             data.value,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 20,
//               color: primaryGreen,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildChartsRow(BuildContext context, bool isDesktop, bool isTablet, List<Widget> charts) {
//     if (!isTablet) {
//       return Column(
//         children: charts.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList(),
//       );
//     }

//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: charts
//           .map((c) => Expanded(
//                 child: Padding(padding: const EdgeInsets.only(right: 16), child: c),
//               ))
//           .toList(),
//     );
//   }

//   Widget _buildChartCard({required String title, required String subtitle, required Widget child, double height = 320}) {
//     return Container(
//       height: height,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha:0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//               color: primaryGreen,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             subtitle,
//             style: TextStyle(color: Colors.grey[500], fontSize: 12),
//           ),
//           const Divider(height: 30, color: Color(0xFFE0E0E0)),
//           Expanded(child: child),
//         ],
//       ),
//     );
//   }

//   // === CHART BUILDERS ===

//   Widget _buildHourlyChart(Map<int, double> data) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20, right: 10),
//       child: BarChart(
//         BarChartData(
//           alignment: BarChartAlignment.spaceAround,
//           maxY: (data.values.isEmpty ? 100 : data.values.reduce((a, b) => a > b ? a : b)) * 1.2,
//           barTouchData: BarTouchData(
//             enabled: true,
//             touchTooltipData: BarTouchTooltipData(
//               getTooltipColor: (group) => primaryGreen,
//                tooltipBorderRadius: BorderRadius.circular(8),
//               tooltipPadding: const EdgeInsets.all(8),
//               getTooltipItem: (group, groupIndex, rod, rodIndex) {
//                 return BarTooltipItem(
//                   '${group.x}:00\n',
//                   const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
//                   children: [
//                     TextSpan(
//                       text: 'GHS ${rod.toY.toStringAsFixed(2)}',
//                       style: const TextStyle(color: accentYellow, fontWeight: FontWeight.w500, fontSize: 12),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//           titlesData: FlTitlesData(
//             bottomTitles: AxisTitles(
//               axisNameWidget: const Padding(
//                 padding: EdgeInsets.only(top: 10),
//                 child: Text('Hour of Day', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
//               ),
//               axisNameSize: 30,
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 reservedSize: 30,
//                 getTitlesWidget: (val, meta) {
//                   int h = val.toInt();
//                   if (h % 3 == 0) {
//                     return Padding(
//                       padding: const EdgeInsets.only(top: 8.0),
//                       child: Text("${h}h", style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
//                     );
//                   }
//                   return const SizedBox.shrink();
//                 },
//               ),
//             ),
//             leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//             topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//             rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           ),
//           gridData: FlGridData(
//             show: true,
//             drawVerticalLine: false,
//             getDrawingHorizontalLine: (value) => FlLine(
//               color: Colors.grey.withValues(alpha:0.1),
//               strokeWidth: 1,
//             ),
//           ),
//           borderData: FlBorderData(show: false),
//           barGroups: List.generate(24, (index) {
//             return BarChartGroupData(
//               x: index,
//               barRods: [
//                 BarChartRodData(
//                   toY: data[index] ?? 0,
//                   gradient: LinearGradient(
//                     colors: [accentGreen, lightGreen],
//                     begin: Alignment.bottomCenter,
//                     end: Alignment.topCenter,
//                   ),
//                   width: 10,
//                   borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
//                 )
//               ],
//             );
//           }),
//         ),
//       ),
//     );
//   }

//   Widget _buildWeeklyChart(Map<int, double> data) {
//     List<String> days = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20, right: 10),
//       child: BarChart(
//         BarChartData(
//           alignment: BarChartAlignment.spaceAround,
//           maxY: (data.values.isEmpty ? 100 : data.values.reduce((a, b) => a > b ? a : b)) * 1.2,
//           barTouchData: BarTouchData(
//             enabled: true,
//             touchTooltipData: BarTouchTooltipData(
//               getTooltipColor: (group) => primaryGreen,
//                tooltipBorderRadius: BorderRadius.circular(8),
//               tooltipPadding: const EdgeInsets.all(8),
//               getTooltipItem: (group, groupIndex, rod, rodIndex) {
//                 return BarTooltipItem(
//                   '${days[group.x]}\n',
//                   const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
//                   children: [
//                     TextSpan(
//                       text: 'GHS ${rod.toY.toStringAsFixed(2)}',
//                       style: const TextStyle(color: accentYellow, fontWeight: FontWeight.w500, fontSize: 12),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//           titlesData: FlTitlesData(
//             bottomTitles: AxisTitles(
//               axisNameWidget: const Padding(
//                 padding: EdgeInsets.only(top: 10),
//                 child: Text('Day of Week', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
//               ),
//               axisNameSize: 30,
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 reservedSize: 30,
//                 getTitlesWidget: (val, meta) {
//                   int d = val.toInt();
//                   if (d >= 1 && d <= 7) {
//                     return Padding(
//                       padding: const EdgeInsets.only(top: 8.0),
//                       child: Text(days[d], style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
//                     );
//                   }
//                   return const SizedBox.shrink();
//                 },
//               ),
//             ),
//             leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//             topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//             rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           ),
//           gridData: FlGridData(
//             show: true,
//             drawVerticalLine: false,
//             getDrawingHorizontalLine: (value) => FlLine(
//               color: Colors.grey.withValues(alpha:0.1),
//               strokeWidth: 1,
//             ),
//           ),
//           borderData: FlBorderData(show: false),
//           barGroups: List.generate(7, (index) {
//             int day = index + 1;
//             bool isWeekend = (day == 6 || day == 7);
//             return BarChartGroupData(
//               x: day,
//               barRods: [
//                 BarChartRodData(
//                   toY: data[day] ?? 0,
//                   gradient: LinearGradient(
//                     colors: isWeekend ? [accentYellow, Colors.orange] : [accentGreen, lightGreen],
//                     begin: Alignment.bottomCenter,
//                     end: Alignment.topCenter,
//                   ),
//                   width: 18,
//                   borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
//                 )
//               ],
//             );
//           }),
//         ),
//       ),
//     );
//   }

//   Widget _buildRevenueDistributionChart(Map<String, Map<String, double>> data) {
//     if (data.isEmpty) return const Center(child: Text("No Data", style: TextStyle(color: Colors.grey)));

//     // Sort activities by gross revenue
//     var sortedEntries = data.entries.toList()..sort((a, b) => b.value['gross']!.compareTo(a.value['gross']!));
    
//     // Take top 6 activities
//     var topActivities = sortedEntries.take(6).toList();
//     double total = topActivities.fold(0, (sum, entry) => sum + entry.value['gross']!);

//     List<Color> colors = [
//       primaryGreen,
//       accentGreen,
//       lightGreen,
//       accentYellow,
//       Colors.orange,
//       Colors.teal,
//     ];

//     return Row(
//       children: [
//         // Pie Chart with Interactive Touch
//         Expanded(
//           flex: 2,
//           child: _PieChartWidget(
//             activities: topActivities,
//             colors: colors,
//             total: total,
//           ),
//         ),
//         // Legend
//         Expanded(
//           flex: 1,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: topActivities.asMap().entries.map((entry) {
//                 int idx = entry.key;
//                 var activity = entry.value;
//                 String name = activity.key;
//                 String displayName = name.length > 15 ? "${name.substring(0, 13)}.." : name;

//                 return Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 6),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 16,
//                         height: 16,
//                         decoration: BoxDecoration(
//                           color: colors[idx % colors.length],
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               displayName,
//                               style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             Text(
//                               'GHS ${activity.value['gross']!.toStringAsFixed(2)}',
//                               style: TextStyle(fontSize: 10, color: Colors.grey[600]),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // Stateful Widget for Interactive Pie Chart
// class _PieChartWidget extends StatefulWidget {
//   final List<MapEntry<String, Map<String, double>>> activities;
//   final List<Color> colors;
//   final double total;

//   const _PieChartWidget({
//     required this.activities,
//     required this.colors,
//     required this.total,
//   });

//   @override
//   State<_PieChartWidget> createState() => _PieChartWidgetState();
// }

// class _PieChartWidgetState extends State<_PieChartWidget> {
//   int touchedIndex = -1;

//   @override
//   Widget build(BuildContext context) {
//     return PieChart(
//       PieChartData(
//         pieTouchData: PieTouchData(
//           touchCallback: (FlTouchEvent event, pieTouchResponse) {
//             setState(() {
//               if (!event.isInterestedForInteractions ||
//                   pieTouchResponse == null ||
//                   pieTouchResponse.touchedSection == null) {
//                 touchedIndex = -1;
//                 return;
//               }
//               touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
//             });
//           },
//         ),
//         borderData: FlBorderData(show: false),
//         sectionsSpace: 2,
//         centerSpaceRadius: 50,
//         sections: List.generate(widget.activities.length, (i) {
//           final isTouched = i == touchedIndex;
//           final fontSize = isTouched ? 16.0 : 14.0;
//           final radius = isTouched ? 110.0 : 100.0;
//           final widgetSize = isTouched ? 60.0 : 50.0;
          
//           var entry = widget.activities[i];
//           double value = entry.value['gross']!;
//           double percentage = (value / widget.total) * 100;

//           return PieChartSectionData(
//             color: widget.colors[i % widget.colors.length],
//             value: value,
//             title: '${percentage.toStringAsFixed(1)}%',
//             radius: radius,
//             titleStyle: TextStyle(
//               fontSize: fontSize,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//               shadows: const [
//                 Shadow(color: Colors.black26, blurRadius: 2),
//               ],
//             ),
//             badgeWidget: isTouched
//                 ? Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withValues(alpha:0.2),
//                           blurRadius: 6,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           entry.key.length > 10 ? "${entry.key.substring(0, 8)}.." : entry.key,
//                           style: const TextStyle(
//                             fontSize: 10,
//                             fontWeight: FontWeight.bold,
//                             color: ReportView.primaryGreen,
//                           ),
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           'GHS ${value.toStringAsFixed(0)}',
//                           style: TextStyle(
//                             fontSize: 9,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 : null,
//             badgePositionPercentageOffset: 1.3,
//           );
//         }),
//       ),
//     );
//   }
// }

// // Helper class for metrics
// class _MetricData {
//   final String title;
//   final String value;
//   final IconData icon;
//   final Color color;

//   _MetricData(this.title, this.value, this.icon, this.color);
// }
