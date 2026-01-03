import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DashboardController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = true.obs;
  
  // Track active filter for UI styling
  var activeFilter = "Last 7 Days".obs;
  
  var dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)), 
    end: DateTime.now()
  ).obs;

  // === DATA OBSERVABLES ===
  // 1. Financials
  var totalRevenue = 0.0.obs;
  var paymentMethods = <String, double>{}.obs; 
  var dailySalesTrend = <String, double>{}.obs; 
  
  // 2. Demographics
  var genderStats = <String, double>{}.obs; 
  var residencyStats = <String, double>{}.obs; 

  // 3. Performance
  var activityRevenue = <String, double>{}.obs; 
  var cashierPerformance = <String, double>{}.obs; 
  var topCustomers = <Map<String, dynamic>>[].obs; 

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  void updateDateRange(DateTimeRange newRange) {
    dateRange.value = newRange;
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;
      
      final snapshot = await _db.collection('transactions')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.value.start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.value.end))
          .get();

      // Reset Counters
      double tempTotalRev = 0;
      Map<String, double> tempPayment = {};
      Map<String, double> tempGender = {"Male": 0, "Female": 0}; 
      Map<String, double> tempResidency = {"Resident": 0, "Non-Resident": 0};  
      Map<String, double> tempDailyTrend = {};
      Map<String, double> tempCashier = {};
      Map<String, double> tempActivityRev = {};
      Map<String, double> customerSpending = {}; 

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] != 'Paid') continue;

        double amount = (data['totalAmount'] as num).toDouble();
        tempTotalRev += amount;

        // 1. Payment Method
        String pMethod = data['paymentMethod'] ?? 'Unknown';
        tempPayment[pMethod] = (tempPayment[pMethod] ?? 0) + amount;

        // 2. Gender (Smart Parsing)
        String rawGender = data['customerGender'] ?? ''; 
        if (rawGender.contains(':')) {
           tempGender['Male'] = (tempGender['Male']! + _extractCount(rawGender, 'Male'));
           tempGender['Female'] = (tempGender['Female']! + _extractCount(rawGender, 'Female'));
        } else if (rawGender == 'Male') {
           tempGender['Male'] = tempGender['Male']! + 1;
        } else if (rawGender == 'Female') {
           tempGender['Female'] = tempGender['Female']! + 1;
        }

        // 3. Residency (Smart Parsing)
        String rawRes = data['residencyStatus'] ?? '';
        if (rawRes.contains(':')) {
           tempResidency['Resident'] = (tempResidency['Resident']! + _extractCount(rawRes, 'Res'));
           tempResidency['Non-Resident'] = (tempResidency['Non-Resident']! + _extractCount(rawRes, 'Non-Res'));
        } else if (rawRes.contains('Non')) {
           tempResidency['Non-Resident'] = tempResidency['Non-Resident']! + 1;
        } else {
           tempResidency['Resident'] = tempResidency['Resident']! + 1;
        }

        // 4. Daily Trend
        DateTime date = (data['timestamp'] as Timestamp).toDate();
        String dayKey = DateFormat('MM/dd').format(date);
        tempDailyTrend[dayKey] = (tempDailyTrend[dayKey] ?? 0) + amount;

        // 5. Cashier Performance
        String cashier = data['cashierName'] ?? 'Unknown';
        tempCashier[cashier] = (tempCashier[cashier] ?? 0) + amount;

        // 6. Top Customers
        String custName = data['customerName'] ?? 'Guest';
        String custPhone = data['customerPhone'] ?? 'N/A';
        String custKey = "$custName|$custPhone";
        customerSpending[custKey] = (customerSpending[custKey] ?? 0) + amount;

        // 7. Activity Revenue
        List items = data['items'] ?? [];
        for (var item in items) {
          String name = item['name'];
          double lineTotal = (item['unitPrice'] * item['quantity']).toDouble();
          tempActivityRev[name] = (tempActivityRev[name] ?? 0) + lineTotal;
        }
      }

      // === Process Top Customers List ===
      var sortedCust = customerSpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      topCustomers.value = sortedCust.take(10).map((e) {
        var parts = e.key.split('|');
        return {'name': parts[0], 'phone': parts[1], 'total': e.value};
      }).toList();

      // === Assign to Observables ===
      totalRevenue.value = tempTotalRev;
      paymentMethods.value = tempPayment;
      genderStats.value = tempGender;
      residencyStats.value = tempResidency;
      dailySalesTrend.value = Map.fromEntries(tempDailyTrend.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
      cashierPerformance.value = tempCashier;
      activityRevenue.value = tempActivityRev;

    } catch (e) {
      print("Analytics Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void applyQuickFilter(String type) {
    activeFilter.value = type;
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (type) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'Yesterday':
        start = DateTime(now.year, now.month, now.day - 1);
        end = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
        break;
      case 'This Week':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        break;
       case 'Last 7 Days':
        start = now.subtract(const Duration(days: 7));
        break; 
      default: // "Last 7 Days"
        start = now.subtract(const Duration(days: 7));
    }

    dateRange.value = DateTimeRange(start: start, end: end);
    fetchDashboardData();
  }

  // Regex Helper
  int _extractCount(String text, String key) {
    try {
      final regex = RegExp("$key:\\s*(\\d+)");
      final match = regex.firstMatch(text);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    } catch (e) {
      return 0;
    }
    return 0;
  }
}