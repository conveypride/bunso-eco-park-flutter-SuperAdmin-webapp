import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SalesChart extends StatelessWidget {
  final Map<String, double> hourlyData;

  const SalesChart({super.key, required this.hourlyData});

  @override
  Widget build(BuildContext context) {
    // 1. Prepare Data for the Chart
    // We want to show hours from 8 AM (8) to 6 PM (18)
    List<BarChartGroupData> barGroups = [];
    
    for (int i = 8; i <= 18; i++) {
      // Format key to match controller output (e.g., "10 AM")
      String key = _formatHour(i);
      double value = hourlyData[key] ?? 0.0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: const Color(0xFF2D5016), // Brand Green
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _getMaxY(), // Dynamic max height
                color: Colors.grey[100],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Hourly Sales Performance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        'GHS ${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        // Show label every 2 hours to avoid clutter
                        if (value.toInt() % 2 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _formatHour(value.toInt()),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide Y-axis numbers
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Convert int (13) to String ("1 PM")
  String _formatHour(int hour) {
    if (hour == 12) return "12 PM";
    if (hour > 12) return "${hour - 12} PM";
    return "$hour AM";
  }

  // Helper: Find highest value to scale the chart background
  double _getMaxY() {
    if (hourlyData.isEmpty) return 1000;
    double max = hourlyData.values.reduce((a, b) => a > b ? a : b);
    return max == 0 ? 1000 : max * 1.2; // Add 20% buffer
  }
}