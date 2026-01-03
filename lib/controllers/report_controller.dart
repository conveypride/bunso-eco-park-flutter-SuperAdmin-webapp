import 'dart:js_interop'; // Required for new web support
import 'package:web/web.dart' as web; // Replaces dart:html

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ReportController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = true.obs;
  var dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)), 
    end: DateTime.now()
  ).obs;

  // Cache for Activity Splits (Loaded from Settings)
  Map<String, double> activitySplits = {}; 

  // === EXPORT DATA ===
  var reportRows = <String, Map<String, double>>{}.obs;
  var totalGross = 0.0.obs;

  // === CHART DATA ===
  var peakHours = <int, double>{}.obs; 
  var weeklyRhythm = <int, double>{}.obs; 
  var ticketTiers = <String, Map<String, int>>{}.obs; 

  @override
  void onInit() {
    super.onInit();
    fetchReportData();
  }

  void updateDateRange(DateTimeRange newRange) {
    dateRange.value = newRange;
    fetchReportData();
  }

  Future<void> fetchReportData() async {
    try {
      isLoading.value = true;
      // 1. Fetch Split Settings
      await _fetchActivitySettings();
      
      // 2. Fetch Transactions
      final snapshot = await _db.collection('transactions')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.value.start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.value.end))
          .get();

      Map<String, Map<String, double>> tempRows = {};
      Map<int, double> tempHours = {};
      Map<int, double> tempWeek = {};
      Map<String, Map<String, int>> tempTiers = {};
      double tGross = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] != 'Paid') continue;

        DateTime date = (data['timestamp'] as Timestamp).toDate();
        double txnTotal = (data['totalAmount'] as num).toDouble();
        
        // Charts Data
        tempHours[date.hour] = (tempHours[date.hour] ?? 0) + txnTotal;
        tempWeek[date.weekday] = (tempWeek[date.weekday] ?? 0) + txnTotal;

        // Process Items
        List items = data['items'] ?? [];
        for (var item in items) {
          String name = item['name'] ?? 'Unknown';
          String tier = item['tier'] ?? 'Standard'; 
          int qty = (item['quantity'] as num).toInt();
          double unitPrice = (item['unitPrice'] as num).toDouble();
          double lineTotal = unitPrice * qty;

          tGross += lineTotal;

          // Populate Report Rows
          if (!tempRows.containsKey(name)) {
            tempRows[name] = {
              "gross": 0, "net": 0, "dev": 0, "shared": 0, "vat": 0
            };
          }
          tempRows[name]!['gross'] = tempRows[name]!['gross']! + lineTotal;

          // Populate Tiers
          if (!tempTiers.containsKey(name)) tempTiers[name] = {};
          tempTiers[name]![tier] = (tempTiers[name]![tier] ?? 0) + qty;
        }
      }

      // APPLY MATH FORMULAS
      tempRows.forEach((key, row) {
        double g = row['gross']!;
        
        double dev = g * 0.05;
        double net = (100 / 121.9) * g; 
        double vat = g - net;          
        double shared = g - dev - vat; 

        row['net'] = net;
        row['dev'] = dev;
        row['vat'] = vat;
        row['shared'] = shared;
      });

      reportRows.value = tempRows;
      totalGross.value = tGross;
      peakHours.value = tempHours;
      weeklyRhythm.value = tempWeek;
      ticketTiers.value = tempTiers;

    } catch (e) {
      print("Report Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchActivitySettings() async {
    try {
      final snapshot = await _db.collection('activities').get();
      activitySplits.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        String name = data['name'];
        double ecoparkPct = (data['ecoparkPercent'] ?? 80).toDouble(); 
        activitySplits[name] = ecoparkPct; 
      }
    } catch (e) {
      print("Error fetching settings: $e");
    }
  }

  // === EXPORT TO CSV FUNCTION (UPDATED) ===
  // === EXPORT TO CSV FUNCTION (TOTAL AT BOTTOM) ===
  void exportToCsv() {
    // 1. Init Accumulators
    double sumGross = 0;
    double sumNet = 0;
    double sumDev = 0;
    double sumShared = 0;
    double sumEcoShare = 0;
    double sumFacShare = 0;
    double sumVat = 0;

    // 2. Prepare Data Rows
    List<List<dynamic>> bodyRows = [];

    reportRows.forEach((activity, data) {
      double ecoPct = activitySplits[activity] ?? 80.0; 
      double facPct = 100.0 - ecoPct;

      double revenueToShare = data['shared']!;
      double ecoparkAmount = revenueToShare * (ecoPct / 100);
      double facilityAmount = revenueToShare * (facPct / 100);

      // Add to Totals
      sumGross += data['gross']!;
      sumNet += data['net']!;
      sumDev += data['dev']!;
      sumShared += data['shared']!;
      sumEcoShare += ecoparkAmount;
      sumFacShare += facilityAmount;
      sumVat += data['vat']!;

      bodyRows.add([
        activity,
        data['gross']!.toStringAsFixed(2),
        data['net']!.toStringAsFixed(2),
        data['dev']!.toStringAsFixed(2),
        data['shared']!.toStringAsFixed(2),
        "$ecoPct%", 
        "$facPct%", 
        ecoparkAmount.toStringAsFixed(2),
        facilityAmount.toStringAsFixed(2),
        data['vat']!.toStringAsFixed(2),
      ]);
    });

    // 3. Construct Final List
    List<List<dynamic>> fullCsvData = [];

    // A. Add Header
    fullCsvData.add([
      "ACTIVITY", "GROSS (VAT INC)", "NET (W/O VAT)", "5% DEV", 
      "REVENUE TO SHARE", "ECOPARK %", "FACILITY %", "ECOPARK SHARE", 
      "FACILITY SHARE", "VAT & LEVIES"
    ]);

    // B. Add Body Rows (Activities)
    fullCsvData.addAll(bodyRows);

    // C. Add Empty Row (Spacer for readability)
    fullCsvData.add([]); 

    // D. Add Total Row (AT THE BOTTOM)
    fullCsvData.add([
      "TOTAL", 
      sumGross.toStringAsFixed(2),
      sumNet.toStringAsFixed(2),
      sumDev.toStringAsFixed(2),
      sumShared.toStringAsFixed(2),
      "", "", // Empty for percentages columns
      sumEcoShare.toStringAsFixed(2),
      sumFacShare.toStringAsFixed(2),
      sumVat.toStringAsFixed(2),
    ]);

    String csvContent = const ListToCsvConverter().convert(fullCsvData);
    
    // 4. Trigger Download
    final fileName = "Bunso_Report_${DateFormat('yyyy_MM_dd').format(dateRange.value.start)}.csv";
    
    final blob = web.Blob(
      [csvContent.toJS].toJS, 
      web.BlobPropertyBag(type: 'text/csv;charset=utf-8')
    );

    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = fileName;
    anchor.click();
    
    web.URL.revokeObjectURL(url);

    Get.snackbar("Export Ready", "CSV file generated (Total at bottom).");
  }
}

class ListToCsvConverter {
  const ListToCsvConverter();
  String convert(List<List<dynamic>> rows) {
    return rows.map((row) => row.map((e) => '"$e"').join(",")).join("\n");
  }
}
// import 'dart:convert';
// import 'dart:html' as html; // UNCOMMENT THIS FOR WEB DEPLOYMENT
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// class ReportController extends GetxController {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;

//   var isLoading = true.obs;
//   var dateRange = DateTimeRange(
//     start: DateTime.now().subtract(const Duration(days: 30)), 
//     end: DateTime.now()
//   ).obs;



//   // Cache for Activity Splits (Loaded from Settings)
//   Map<String, double> activitySplits = {}; // Name -> Ecopark % (0.0 - 1.0)

//   // === EXPORT DATA ===
//   // Map<ActivityName, {Gross, Net, Dev, ...}>
//   var reportRows = <String, Map<String, double>>{}.obs;
//   var totalGross = 0.0.obs;

//   // === CHART DATA ===
//   var peakHours = <int, double>{}.obs; // Hour (0-23) -> Revenue
//   var weeklyRhythm = <int, double>{}.obs; // Day (1-7) -> Revenue
//   var ticketTiers = <String, Map<String, int>>{}.obs; // Activity -> {Adult: 10, Child: 5}

//   @override
//   void onInit() {
//     super.onInit();
//     fetchReportData();
//   }

//   void updateDateRange(DateTimeRange newRange) {
//     dateRange.value = newRange;
//     fetchReportData();
//   }

//   Future<void> fetchReportData() async {
//     try {
//       isLoading.value = true;
//       // 1. Fetch Split Settings first (to be ready for export)
//       await _fetchActivitySettings();
//       // 2. Fetch Transactions
//       final snapshot = await _db.collection('transactions')
//           .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.value.start))
//           .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.value.end))
//           .get();
//      // ... (Reset temp variables logic same as before) ...
//       Map<String, Map<String, double>> tempRows = {};
//       Map<int, double> tempHours = {};
//       Map<int, double> tempWeek = {};
//       Map<String, Map<String, int>> tempTiers = {};
//       double tGross = 0;

//       for (var doc in snapshot.docs) {
//         final data = doc.data();
//         if (data['status'] != 'Paid') continue;

//         DateTime date = (data['timestamp'] as Timestamp).toDate();
//         double txnTotal = (data['totalAmount'] as num).toDouble();
        
//         // Charts Data
//         tempHours[date.hour] = (tempHours[date.hour] ?? 0) + txnTotal;
//         tempWeek[date.weekday] = (tempWeek[date.weekday] ?? 0) + txnTotal;

//         // 3. Process Items for Report & Tiers
//         List items = data['items'] ?? [];
//         for (var item in items) {
//           String name = item['name'] ?? 'Unknown';
//           String tier = item['tier'] ?? 'Standard'; // Adult/Child
//           int qty = (item['quantity'] as num).toInt();
//           double unitPrice = (item['unitPrice'] as num).toDouble();
//           double lineTotal = unitPrice * qty;

//           tGross += lineTotal;

//           // A. Populate Report Rows
//           if (!tempRows.containsKey(name)) {
//             tempRows[name] = {
//               "gross": 0, "net": 0, "dev": 0, "shared": 0, "vat": 0
//             };
//           }
//           tempRows[name]!['gross'] = tempRows[name]!['gross']! + lineTotal;

//           // B. Populate Tier Stats
//           if (!tempTiers.containsKey(name)) tempTiers[name] = {};
//           tempTiers[name]![tier] = (tempTiers[name]![tier] ?? 0) + qty;
//         }
//       }

//      //  APPLY NEW MATH FORMULAS
//       // Gross = Total
//       // Dev = Gross * 0.05
//       // Net = (100/121.9) * Gross
//       // VAT = Gross - Net
//       // Shared = Gross - Dev - VAT
       

//        tempRows.forEach((key, row) {
//         double g = row['gross']!;
        
//         double dev = g * 0.05;
//         double net = (100 / 121.9) * g; // New Formula
//         double vat = g - net;           // New Formula
//         double shared = g - dev - vat;  // New Formula

//         row['net'] = net;
//         row['dev'] = dev;
//         row['vat'] = vat;
//         row['shared'] = shared;
//       });

//       reportRows.value = tempRows;
//       totalGross.value = tGross;
//       peakHours.value = tempHours;
//       weeklyRhythm.value = tempWeek;
//       ticketTiers.value = tempTiers;

//     } catch (e) {
//       print("Report Error: $e");
//     } finally {
//       isLoading.value = false;
//     }
//   }

// // Fetch splits from 'activities' collection
//   Future<void> _fetchActivitySettings() async {
//     try {
//       final snapshot = await _db.collection('activities').get();
//       activitySplits.clear();
//       for (var doc in snapshot.docs) {
//         final data = doc.data();
//         String name = data['name'];
//         // Default to 80% if not set
//         double ecoparkPct = (data['ecoparkPercent'] ?? 80).toDouble(); 
//         activitySplits[name] = ecoparkPct; 
//       }
//     } catch (e) {
//       print("Error fetching settings: $e");
//     }
//   }

//   // === EXPORT TO CSV FUNCTION ===
//    void exportToCsv() {
//     List<List<dynamic>> rows = [];
//     rows.add([
//       "ACTIVITY", "GROSS (VAT INC)", "NET (W/O VAT)", "5% DEV", 
//       "REVENUE TO SHARE", "ECOPARK %", "FACILITY %", "ECOPARK SHARE", 
//       "FACILITY SHARE", "VAT & LEVIES"
//     ]);

//     reportRows.forEach((activity, data) {
//       // Lookup percentage from settings (default 80 if missing)
//       double ecoPct = activitySplits[activity] ?? 80.0; 
//       double facPct = 100.0 - ecoPct;

//       double revenueToShare = data['shared']!;
//       double ecoparkAmount = revenueToShare * (ecoPct / 100);
//       double facilityAmount = revenueToShare * (facPct / 100);

//       rows.add([
//         activity,
//         data['gross']!.toStringAsFixed(2),
//         data['net']!.toStringAsFixed(2),
//         data['dev']!.toStringAsFixed(2),
//         data['shared']!.toStringAsFixed(2),
//         "$ecoPct%", // New Column
//         "$facPct%", // New Column
//         ecoparkAmount.toStringAsFixed(2),
//         facilityAmount.toStringAsFixed(2),
//         data['vat']!.toStringAsFixed(2),
//       ]);
//     });

//     String csvContent = const ListToCsvConverter().convert(rows);
    
//     // Trigger Download (Web specific)
//     // Uncomment for Web:
//     final bytes = utf8.encode(csvContent);
//     final blob = html.Blob([bytes]);
//     final url = html.Url.createObjectUrlFromBlob(blob);
//     final anchor = html.AnchorElement(href: url)
//       ..setAttribute("download", "Bunso_Report_${DateFormat('yyyy_MM').format(dateRange.value.start)}.csv")
//       ..click();
//     html.Url.revokeObjectUrl(url);

//     Get.snackbar("Export Ready", "CSV file generated (Check downloads)");
//     debugPrint(csvContent); // For debug
//   }
// }

// // Simple CSV Converter Helper (No external package needed for simple text)
// class ListToCsvConverter {
//   const ListToCsvConverter();
//   String convert(List<List<dynamic>> rows) {
//     return rows.map((row) => row.map((e) => '"$e"').join(",")).join("\n");
//   }
// }