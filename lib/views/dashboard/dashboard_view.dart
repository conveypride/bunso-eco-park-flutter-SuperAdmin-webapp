 import 'package:bunso_ecopark_admin/controllers/dashboard_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F0),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === MODERN HEADER WITH STATS CARDS ===
            _buildHeaderSection(controller, isDesktop, isTablet, isMobile, context),
            const SizedBox(height: 24),

            // === FILTER SECTION ===
            _buildFilterSection(controller, isDesktop, isTablet, isMobile, context),
            const SizedBox(height: 30),

            Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 100),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Column(
                          children: [
                            CircularProgressIndicator(
                              color: Color(0xFF2D5016),
                              strokeWidth: 3,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Loading dashboard...",
                              style: TextStyle(
                                color: Color(0xFF2D5016),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // SECTION 1: SALES TREND
                  _buildChartContainer(
                    title: "Sales Trend",
                    subtitle: "Revenue by Date",
                    height: isDesktop ? 350 : 300,
                    icon: Icons.trending_up_rounded,
                    child: _buildLineChart(controller.dailySalesTrend),
                  ),
                  const SizedBox(height: 24),

                  // SECTION 2: DEMOGRAPHICS
                  if (isDesktop || isTablet)
                    Row(
                      children: [
                        Expanded(
                          child: _buildChartContainer(
                            title: "Gender Distribution",
                            icon: Icons.people_outline_rounded,
                            height: 300,
                            child: _buildPieChart(
                              controller.genderStats,
                              [const Color(0xFF2D5016), const Color(0xFFFFC107), Colors.grey[400]!],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildChartContainer(
                            title: "Residency Status",
                            icon: Icons.location_on_outlined,
                            height: 300,
                            child: _buildPieChart(
                              controller.residencyStats,
                              [const Color(0xFF4A7C2B), const Color(0xFFFFA726), Colors.grey[400]!],
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildChartContainer(
                          title: "Gender Distribution",
                          icon: Icons.people_outline_rounded,
                          height: 300,
                          child: _buildPieChart(
                            controller.genderStats,
                            [const Color(0xFF2D5016), const Color(0xFFFFC107), Colors.grey[400]!],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildChartContainer(
                          title: "Residency Status",
                          icon: Icons.location_on_outlined,
                          height: 300,
                          child: _buildPieChart(
                            controller.residencyStats,
                            [const Color(0xFF4A7C2B), const Color(0xFFFFA726), Colors.grey[400]!],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // SECTION 3: ACTIVITIES & PAYMENTS
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildChartContainer(
                            title: "Revenue by Activity",
                            subtitle: "Top 5 Activities",
                            icon: Icons.local_activity_outlined,
                            height: 380,
                            child: _buildBarChart(controller.activityRevenue),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 1,
                          child: _buildChartContainer(
                            title: "Payment Methods",
                            icon: Icons.payment_rounded,
                            height: 380,
                            child: _buildPieChart(
                              controller.paymentMethods,
                              [const Color(0xFF2D5016), const Color(0xFFFFC107)],
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildChartContainer(
                          title: "Revenue by Activity",
                          subtitle: "Top 5 Activities",
                          icon: Icons.local_activity_outlined,
                          height: 350,
                          child: _buildBarChart(controller.activityRevenue),
                        ),
                        const SizedBox(height: 20),
                        _buildChartContainer(
                          title: "Payment Methods",
                          icon: Icons.payment_rounded,
                          height: 300,
                          child: _buildPieChart(
                            controller.paymentMethods,
                            [const Color(0xFF2D5016), const Color(0xFFFFC107)],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // SECTION 4: LEADERBOARDS
                  if (isDesktop || isTablet)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildListCard(
                            "Top Cashiers",
                            controller.cashierPerformance,
                            isCurrency: true,
                            icon: Icons.person_outline_rounded,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildCustomerList(
                            "Top Customers",
                            controller.topCustomers,
                            icon: Icons.star_outline_rounded,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildListCard(
                          "Top Cashiers",
                          controller.cashierPerformance,
                          isCurrency: true,
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 20),
                        _buildCustomerList(
                          "Top Customers",
                          controller.topCustomers,
                          icon: Icons.star_outline_rounded,
                        ),
                      ],
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // === HEADER WITH REVENUE CARDS ===
  Widget _buildHeaderSection(
    DashboardController controller,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dashboard Overview",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D5016),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isDesktop)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D5016), Color(0xFF4A7C2B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D5016).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco_rounded, color: Color(0xFFFFC107), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "EcoPark Admin",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        // Revenue Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D5016), Color(0xFF4A7C2B), Color(0xFF5D9939)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D5016).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Color(0xFFFFC107),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Total Revenue",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Obx(() => Text(
                        "GHS ${controller.totalRevenue.value.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      )),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.trending_up, color: Color(0xFF2D5016), size: 14),
                            SizedBox(width: 4),
                            Text(
                              "+12.5%",
                              style: TextStyle(
                                color: Color(0xFF2D5016),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "vs last period",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // === FILTER SECTION ===
  Widget _buildFilterSection(
    DashboardController controller,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
    BuildContext context,
  ) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildFilterButton(controller, "Today")),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterButton(controller, "Yesterday")),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildFilterButton(controller, "This Week")),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterButton(controller, "This Month")),
            ],
          ),
          const SizedBox(height: 12),
          _buildDateRangePicker(controller, context),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildFilterButton(controller, "Today"),
        _buildFilterButton(controller, "Yesterday"),
        _buildFilterButton(controller, "This Week"),
        _buildFilterButton(controller, "This Month"),
        Container(
          height: 30,
          width: 1,
          color: Colors.grey[300],
          margin: const EdgeInsets.symmetric(horizontal: 8),
        ),
        _buildDateRangePicker(controller, context),
      ],
    );
  }

  Widget _buildDateRangePicker(DashboardController controller, BuildContext context) {
    return Obx(() {
      String start = DateFormat('MMM dd').format(controller.dateRange.value.start);
      String end = DateFormat('MMM dd').format(controller.dateRange.value.end);
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2D5016).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                initialDateRange: controller.dateRange.value,
                builder: (context, child) {
                  return Theme(
                    data: ThemeData(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF2D5016),
                        onPrimary: Colors.white,
                        surface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                controller.activeFilter.value = "Custom";
                controller.updateDateRange(picked);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF2D5016)),
                  const SizedBox(width: 10),
                  Text(
                    "$start - $end",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D5016),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // === CHART CONTAINER ===
  Widget _buildChartContainer({
    required String title,
    String? subtitle,
    required Widget child,
    double height = 300,
    IconData? icon,
  }) {
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
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D5016).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF2D5016), size: 20),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D5016),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200], thickness: 1),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  // === INTERACTIVE LINE CHART ===
  Widget _buildLineChart(Map<String, double> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text("No data available", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    List<String> keys = data.keys.toList();
    List<FlSpot> spots = [];
    for (int i = 0; i < keys.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[keys[i]]!));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (val, meta) {
                int index = val.toInt();
                if (index >= 0 && index < keys.length) {
                  if (keys.length > 10 && index % 2 != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      keys[index],
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Text(
                  'GHS ${value.toInt()}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
            left: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF2D5016),
              tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final date = keys[spot.x.toInt()];
                return LineTooltipItem(
                  '$date\nGHS ${spot.y.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(color: const Color(0xFFFFC107), strokeWidth: 2),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: const Color(0xFFFFC107),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
              );
            }).toList();
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFF2D5016),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF2D5016),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2D5016).withOpacity(0.3),
                  const Color(0xFF2D5016).withOpacity(0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === INTERACTIVE BAR CHART ===
  Widget _buildBarChart(Map<String, double> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text("No data available", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    var sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var top5 = sorted.take(5).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: top5.isEmpty ? 100 : top5.first.value * 1.2,
        barGroups: top5.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value,
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF2D5016), Color(0xFF5D9939)],
                ),
                width: 32,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: top5.first.value * 1.2,
                  color: Colors.grey[100],
                ),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (val, meta) {
                int index = val.toInt();
                if (index >= 0 && index < top5.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 70,
                      child: Text(
                        top5[index].key,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Text(
                  'GHS ${value.toInt()}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
          },
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF2D5016),
              tooltipBorderRadius: BorderRadius.circular(8),
            tooltipPadding: const EdgeInsets.all(12),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${top5[group.x.toInt()].key}\n',
                const TextStyle(
                  color: Color(0xFFFFC107),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: 'GHS ${rod.toY.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // === INTERACTIVE PIE CHART ===
  Widget _buildPieChart(Map<String, double> data, List<Color> colors) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text("No data available", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    double total = data.values.reduce((a, b) => a + b);
    int touchedIndex = -1;

    return StatefulBuilder(
      builder: (context, setState) {
        int i = 0;
        return Row(
          children: [
            Flexible(
              flex: 1,
              child: PieChart(
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
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: data.entries.map((e) {
                    final isTouched = i == touchedIndex;
                    final color = colors[i % colors.length];
                    final radius = isTouched ? 65.0 : 55.0;
                    final fontSize = isTouched ? 16.0 : 14.0;
                    final percentage = ((e.value / total) * 100).toStringAsFixed(1);
                    i++;
              
                    return PieChartSectionData(
                      value: e.value,
                      title:  '$percentage%',
                      color: color,
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      badgeWidget: isTouched
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Text(
                                '${e.value} ${e.key}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            )
                          : null,
                      badgePositionPercentageOffset: 1.3,
                    );
                  }).toList(),
                ),
              ),
            ),

const SizedBox(height: 16),
            // Legend
            Padding(
              padding: const EdgeInsets.only(left:16.0),
              child: Flexible(
                flex: 2,
                child: Wrap(
                  direction: Axis.vertical,
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: data.entries.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final color = colors[index % colors.length];
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.key,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2D5016),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // === LIST CARD ===
  Widget _buildListCard(
    String title,
    Map<String, double> data, {
    bool isCurrency = false,
    IconData? icon,
  }) {
    var sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      height: 400,
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
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D5016).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF2D5016), size: 20),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5016),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200], thickness: 1),
          const SizedBox(height: 8),
          Expanded(
            child: sorted.isEmpty
                ? Center(
                    child: Text(
                      "No data available",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (context, i) {
                      final isTop3 = i < 3;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isTop3 ? const Color(0xFF2D5016).withOpacity(0.05) : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: isTop3
                                  ? const LinearGradient(
                                      colors: [Color(0xFF2D5016), Color(0xFF5D9939)],
                                    )
                                  : null,
                              color: isTop3 ? null : Colors.grey[200],
                              shape: BoxShape.circle,
                              boxShadow: isTop3
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF2D5016).withOpacity(0.3),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                "${i + 1}",
                                style: TextStyle(
                                  color: isTop3 ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            sorted[i].key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isTop3 ? FontWeight.w600 : FontWeight.normal,
                              color: const Color(0xFF2D5016),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isTop3 ? const Color(0xFFFFC107) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isCurrency
                                  ? "GHS ${sorted[i].value.toStringAsFixed(2)}"
                                  : "${sorted[i].value.toInt()}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isTop3 ? const Color(0xFF2D5016) : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // === CUSTOMER LIST ===
  Widget _buildCustomerList(
    String title,
    List<Map<String, dynamic>> customers, {
    IconData? icon,
  }) {
    return Container(
      height: 400,
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
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF2D5016), size: 20),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5016),
                 
                ), 
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200], thickness: 1),
          const SizedBox(height: 8),
          Expanded(
            child: customers.isEmpty
                ? Center(
                    child: Text(
                      "No customers yet",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.separated(
                    itemCount: customers.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (context, i) {
                      final cust = customers[i];
                      final isTop3 = i < 3;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isTop3 ? const Color(0xFFFFC107).withOpacity(0.1) : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: isTop3
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
                                    )
                                  : null,
                              color: isTop3 ? null : const Color(0xFF2D5016).withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isTop3 ? const Color(0xFF2D5016) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Expanded(
                                child: Text(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  cust['name'][0].toUpperCase(),
                                  style: TextStyle(
                                    color: isTop3 ? const Color(0xFF2D5016) : Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            cust['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isTop3 ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xFF2D5016),
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Icon(Icons.phone, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                    maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  cust['phone'],
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: isTop3
                                  ? const LinearGradient(
                                      colors: [Color(0xFF2D5016), Color(0xFF5D9939)],
                                    )
                                  : null,
                              color: isTop3 ? null : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "GHS ${(cust['total'] as double).toStringAsFixed(2)}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isTop3 ? Colors.white : const Color(0xFF2D5016),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // === FILTER BUTTON ===
  Widget _buildFilterButton(DashboardController controller, String label) {
    return Obx(() {
      bool isActive = controller.activeFilter.value == label;
      return Container(
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF2D5016), Color(0xFF4A7C2B)],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF2D5016).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.applyQuickFilter(label),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isActive ? Colors.transparent : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? Colors.transparent : const Color(0xFF2D5016).withOpacity(0.2),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isActive ? Colors.white : const Color(0xFF2D5016),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
// import 'package:bunso_ecopark_admin/controllers/dashboard_controller.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// class DashboardView extends StatelessWidget {
//   const DashboardView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(DashboardController());

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // === HEADER ===
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text("Park Dashboard", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//                     Obx(() => Text(
//                       "Revenue: GHS ${controller.totalRevenue.value.toStringAsFixed(2)}",
//                       style: TextStyle(color: Colors.green[800], fontSize: 16, fontWeight: FontWeight.bold),
//                     )),
//                   ],
//                 ),

//                 // FILTERS ROW
//                 Row(
//                   children: [
//                     // Quick Filters
//                     _buildFilterButton(controller, "Today"),
//                     const SizedBox(width: 8),
//                     _buildFilterButton(controller, "Yesterday"),
//                     const SizedBox(width: 8),
//                     _buildFilterButton(controller, "This Week"),
//                     const SizedBox(width: 8),
//                     _buildFilterButton(controller, "This Month"),
                    
//                     const SizedBox(width: 20),
//                     Container(height: 30, width: 1, color: Colors.grey[300]), // Divider
//                     const SizedBox(width: 20),

//                     // Custom Date Picker
//                     Obx(() {
//                       String start = DateFormat('MMM dd').format(controller.dateRange.value.start);
//                       String end = DateFormat('MMM dd').format(controller.dateRange.value.end);
//                       return OutlinedButton.icon(
//                         icon: const Icon(Icons.calendar_today, size: 16),
//                         label: Text("$start - $end"),
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
//                           backgroundColor: Colors.white,
//                           side: const BorderSide(color: Colors.grey),
//                         ),
//                         onPressed: () async {
//                           final picked = await showDateRangePicker(
//                             context: context,
//                             firstDate: DateTime(2020),
//                             lastDate: DateTime.now().add(const Duration(days: 1)),
//                             initialDateRange: controller.dateRange.value,
//                           );
//                           if (picked != null) {
//                             controller.activeFilter.value = "Custom"; 
//                             controller.updateDateRange(picked);
//                           }
//                         },
//                       );
//                     }),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 30),

//             Obx(() {
//               if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());

//               return Column(
//                 children: [
//                   // SECTION 1: SALES TREND (Line Chart) 
//                   _buildChartContainer(
//                     title: "Sales Trend (Revenue by Date)",
//                     height: 300,
//                     child: _buildLineChart(controller.dailySalesTrend),
//                   ),
//                   const SizedBox(height: 20),

//                   // SECTION 2: DEMOGRAPHICS (Row of Pie Charts) 
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildChartContainer(
//                           title: "Gender Distribution",
//                           child: _buildPieChart(controller.genderStats, [Colors.blue, Colors.pink, Colors.grey]),
//                         ),
//                       ),
//                       const SizedBox(width: 20),
//                       Expanded(
//                         child: _buildChartContainer(
//                           title: "Residency Status",
//                           child: _buildPieChart(controller.residencyStats, [Colors.orange, Colors.purple, Colors.grey]),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),

//                   // SECTION 3: ACTIVITIES & PAYMENTS
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Revenue by Activity (Bar Chart) 
//                       Expanded(
//                         flex: 2,
//                         child: _buildChartContainer(
//                           title: "Revenue by Activity",
//                           height: 350,
//                           child: _buildBarChart(controller.activityRevenue),
//                         ),
//                       ),
//                       const SizedBox(width: 20),
//                       // Payment Methods
//                       Expanded(
//                         flex: 1,
//                         child: _buildChartContainer(
//                           title: "Payment Methods",
//                           height: 350,
//                           child: _buildPieChart(controller.paymentMethods, [Colors.green, Colors.teal]),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),

//                   // SECTION 4: LEADERBOARDS (Lists)
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: _buildListCard("Top Cashiers", controller.cashierPerformance, isCurrency: true),
//                       ),
//                       const SizedBox(width: 20),
//                       Expanded(
//                         child: _buildCustomerList("Top Customers", controller.topCustomers),
//                       ),
//                     ],
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

//   Widget _buildChartContainer({required String title, required Widget child, double height = 250}) {
//     return Container(
//       height: height,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//           const Divider(),
//           Expanded(child: child),
//         ],
//       ),
//     );
//   }

//   Widget _buildLineChart(Map<String, double> data) {
//     if (data.isEmpty) return const Center(child: Text("No Data"));
//     List<String> keys = data.keys.toList();
//     List<FlSpot> spots = [];
//     for (int i = 0; i < keys.length; i++) {
//       spots.add(FlSpot(i.toDouble(), data[keys[i]]!));
//     }

//     return LineChart(
//       LineChartData(
//         gridData: const FlGridData(show: false),
//         titlesData: FlTitlesData(
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               getTitlesWidget: (val, meta) {
//                 int index = val.toInt();
//                 if (index >= 0 && index < keys.length) {
//                    if (keys.length > 10 && index % 2 != 0) return const SizedBox.shrink(); 
//                    return Padding(padding: const EdgeInsets.only(top: 8), child: Text(keys[index], style: const TextStyle(fontSize: 10)));
//                 }
//                 return const SizedBox.shrink();
//               },
//             ),
//           ),
//           leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
//           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         ),
//         borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[300]!)),
//         lineBarsData: [
//           LineChartBarData(
//             spots: spots,
//             isCurved: true,
//             color: Colors.blue,
//             barWidth: 3,
//             belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
//             dotData: const FlDotData(show: true),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBarChart(Map<String, double> data) {
//     if (data.isEmpty) return const Center(child: Text("No Data"));
//     var sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value)); 
//     var top5 = sorted.take(5).toList(); 

//     return BarChart(
//       BarChartData(
//         alignment: BarChartAlignment.spaceAround,
//         barGroups: top5.asMap().entries.map((e) {
//           return BarChartGroupData(
//             x: e.key,
//             barRods: [
//               BarChartRodData(toY: e.value.value, color: const Color(0xFF2D5016), width: 20, borderRadius: BorderRadius.circular(4))
//             ],
//           );
//         }).toList(),
//         titlesData: FlTitlesData(
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               getTitlesWidget: (val, meta) {
//                 int index = val.toInt();
//                 if (index >= 0 && index < top5.length) {
//                   return Padding(
//                     padding: const EdgeInsets.only(top: 8), 
//                     child: SizedBox(width: 60, child: Text(top5[index].key, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis))
//                   );
//                 }
//                 return const SizedBox.shrink();
//               },
//             ),
//           ),
//           leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         ),
//         borderData: FlBorderData(show: false),
//         gridData: const FlGridData(show: false),
//         barTouchData: BarTouchData(
//           touchTooltipData: BarTouchTooltipData(
//              getTooltipColor: (_) => Colors.black87,
//              getTooltipItem: (group, groupIndex, rod, rodIndex) {
//                return BarTooltipItem("GHS ${rod.toY.toStringAsFixed(0)}", const TextStyle(color: Colors.white));
//              }
//           )
//         ),
//       ),
//     );
//   }

//   Widget _buildPieChart(Map<String, double> data, List<Color> colors) {
//     if (data.isEmpty) return const Center(child: Text("No Data"));
//     double total = data.values.reduce((a, b) => a + b);

//     int i = 0;
//     return PieChart(
//       PieChartData(
//         sectionsSpace: 2,
//         centerSpaceRadius: 30,
//         sections: data.entries.map((e) {
//           final isLarge = e.value / total > 0.5;
//           final color = colors[i % colors.length];
//           i++;
//           return PieChartSectionData(
//             value: e.value,
//             title: "${((e.value / total) * 100).toStringAsFixed(0)}%",
//             color: color,
//             radius: 50,
//             titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
//             badgeWidget: isLarge ? null : Container(
//               padding: const EdgeInsets.all(4),
//               decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]),
//               child: Text(e.key, style: const TextStyle(fontSize: 10)),
//             ),
//             badgePositionPercentageOffset: 1.2,
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget _buildListCard(String title, Map<String, double> data, {bool isCurrency = false}) {
//     var sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

//     return Container(
//       height: 300,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//           const Divider(),
//           Expanded(
//             child: ListView.separated(
//               itemCount: sorted.length,
//               separatorBuilder: (_, __) => const Divider(height: 1),
//               itemBuilder: (context, i) {
//                 return ListTile(
//                   contentPadding: EdgeInsets.zero,
//                   leading: CircleAvatar(backgroundColor: Colors.green[50], child: Text("${i + 1}", style: TextStyle(color: Colors.green[800]))),
//                   title: Text(sorted[i].key, style: const TextStyle(fontSize: 14)),
//                   trailing: Text(
//                     isCurrency ? "GHS ${sorted[i].value.toStringAsFixed(2)}" : "${sorted[i].value.toInt()}",
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCustomerList(String title, List<Map<String, dynamic>> customers) {
//     return Container(
//       height: 300,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//           const Divider(),
//           Expanded(
//             child: ListView.separated(
//               itemCount: customers.length,
//               separatorBuilder: (_, __) => const Divider(height: 1),
//               itemBuilder: (context, i) {
//                 final cust = customers[i];
//                 return ListTile(
//                   contentPadding: EdgeInsets.zero,
//                   title: Text(cust['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
//                   subtitle: Text(cust['phone'], style: const TextStyle(fontSize: 12)),
//                   trailing: Text(
//                     "GHS ${(cust['total'] as double).toStringAsFixed(2)}",
//                     style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterButton(DashboardController controller, String label) {
//     return Obx(() {
//       bool isActive = controller.activeFilter.value == label;
//       return TextButton(
//         onPressed: () => controller.applyQuickFilter(label),
//         style: TextButton.styleFrom(
//           backgroundColor: isActive ? const Color(0xFF2D5016) : Colors.white,
//           foregroundColor: isActive ? Colors.white : Colors.grey[700],
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//             side: BorderSide(color: isActive ? Colors.transparent : Colors.grey.shade300),
//           ),
//         ),
//         child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
//       );
//     });
//   }
// }