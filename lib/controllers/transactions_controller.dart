 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:csv/csv.dart'; // Import CSV
import 'dart:convert'; // For utf8 encoding
import 'package:universal_html/html.dart' as html; // For Web Download

enum DateFilter { today, last7Days, thisWeek, lastWeek, thisMonth, lastMonth, custom, all }

class TransactionsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // State
  var transactions = <QueryDocumentSnapshot>[].obs;
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;

  // Pagination
  DocumentSnapshot? lastDocument;
  final int pageSize = 20;

  // Filters
  // DEFAULT SET TO LAST 7 DAYS
  var selectedFilter = DateFilter.last7Days.obs; 
  var customStartDate = DateTime.now().obs;
  var customEndDate = DateTime.now().obs;

// === NEW: STATUS FILTER ===
  var statusFilter = "All".obs; // Options: All, Paid, Refunded, Canceled

  // Search
  var searchQuery = "".obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  // === FETCH TRANSACTIONS (Handles Initial Load & Pagination) ===
  void fetchTransactions({bool loadMore = false}) async {
    // Prevent duplicate calls
    if (loadMore && !hasMore.value) return;
    if (loadMore && isLoadingMore.value) return;

    try {
      if (loadMore) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
        transactions.clear();
        lastDocument = null;
        hasMore.value = true;
      }

      Query query = _db.collection('transactions');

// 1. Apply Status Filter (NEW)
      if (statusFilter.value != "All") {
        query = query.where('status', isEqualTo: statusFilter.value);
      }
      // Apply date filter (Logic below)
      final dateRange = _getDateRange();
      if (dateRange != null) {
        query = query
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange['start']!))
            .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(dateRange['end']!));
      }

      // Order by timestamp (Newest first)
      query = query.orderBy('timestamp', descending: true);

      // Apply Pagination
      if (loadMore && lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      query = query.limit(pageSize);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMore.value = false;
        if (!loadMore) transactions.clear();
        return;
      }

      // Check if we reached the end
      if (snapshot.docs.length < pageSize) {
        hasMore.value = false;
      }

      // Update cursor
      lastDocument = snapshot.docs.last;

      // Update List
      if (loadMore) {
        transactions.addAll(snapshot.docs);
      } else {
        transactions.value = snapshot.docs;
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not load transactions: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print("Fetch Error: $e");
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }



// === EXPORT TO EXCEL (CSV) ===
  void exportToExcel() {
    if (transactions.isEmpty) {
      Get.snackbar("Export Failed", "No data to export", backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    List<List<dynamic>> rows = [];

    // 1. Add Header Row
    rows.add([
      "Date",
      "Time",
      "Receipt ID",
      "Customer Name",
      "Phone",
      "Items Count",
      "Total Amount (GHS)",
      "Status",
      "Cashier"
    ]);

    // 2. Add Data Rows
    for (var doc in transactions) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? ts = data['timestamp'];
      final DateTime date = ts != null ? ts.toDate() : DateTime.now();

      rows.add([
        "${date.year}-${date.month}-${date.day}", // Date
        "${date.hour}:${date.minute}",             // Time
        data['id'] ?? '-',
        data['customerName'] ?? 'Guest',
        data['customerPhone'] ?? '-',
        data['totalItems'] ?? 0,
        data['totalAmount'] ?? 0.0,
        data['status'] ?? 'Paid',
        data['cashierName'] ?? 'Unknown'
      ]);
    }

    // 3. Convert to CSV String
    String csv = const ListToCsvConverter().convert(rows);

    // 4. Trigger Download (Web specific)
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "transactions_export_${DateTime.now().millisecondsSinceEpoch}.csv")
      ..click();
    
    html.Url.revokeObjectUrl(url);

    Get.snackbar("Success", "Export downloaded successfully!", backgroundColor: Colors.green, colorText: Colors.white);
  }

  // === LOAD MORE (Connect this to your ScrollController) ===
  void loadMore() {
    // Disable pagination if searching (results are usually small)
    if (searchQuery.value.isNotEmpty) return; 
    
    fetchTransactions(loadMore: true);
  }

  // === REFRESH (Connect this to RefreshIndicator) ===
  void refresh() {
    searchQuery.value = "";
    fetchTransactions();
  }

  // === SEARCH TRANSACTIONS ===
  void searchTransactions(String query) async {
    searchQuery.value = query.trim();

    if (searchQuery.value.isEmpty) {
      fetchTransactions();
      return;
    }

    try {
      isLoading.value = true;
      transactions.clear();
      hasMore.value = false; 

      // 1. Search by ID
      var snapshot = await _db
          .collection('transactions')
          .where('id', isEqualTo: searchQuery.value)
          .get();

      // 2. If no ID, Search by Phone
      if (snapshot.docs.isEmpty) {
        String phone = searchQuery.value;
        // if (phone.startsWith('0')) {
        //   phone = '233${phone.substring(1)}';
        // }

        snapshot = await _db
            .collection('transactions')
            .where('customerPhone', isEqualTo: phone)
            .orderBy('timestamp', descending: true)
            .get();
      }

      transactions.value = snapshot.docs;

      if (snapshot.docs.isEmpty) {
        Get.snackbar("No Results", "No transactions found for '$query'", backgroundColor: Colors.orange, colorText: Colors.white);
      }
    } catch (e) {
      print("Search Error: $e");
      Get.snackbar("Search Error", "$e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // === HELPER METHODS ===

  void clearSearch() {
    searchQuery.value = "";
    fetchTransactions();
  }

  void changeFilter(DateFilter filter) {
    selectedFilter.value = filter;
    searchQuery.value = ""; 
    fetchTransactions();
  }

// === NEW HELPER: CHANGE STATUS ===
  void changeStatusFilter(String? status) {
    if (status != null) {
      statusFilter.value = status;
      fetchTransactions(); // Reload data
    }
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    customStartDate.value = start;
    customEndDate.value = end;
    selectedFilter.value = DateFilter.custom;
    searchQuery.value = "";
    fetchTransactions();
  }

  // === DATE RANGE LOGIC ===
  Map<String, DateTime>? _getDateRange() {
    final now = DateTime.now();

    switch (selectedFilter.value) {
      case DateFilter.today:
        return {
          'start': DateTime(now.year, now.month, now.day, 0, 0, 0),
          'end': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };

      case DateFilter.last7Days:
        final start = now.subtract(const Duration(days: 7));
        return {
          'start': DateTime(start.year, start.month, start.day, 0, 0, 0),
          'end': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };

      case DateFilter.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return {
          'start': DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0),
          'end': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };

      case DateFilter.lastWeek:
        final startOfLastWeek = now.subtract(Duration(days: now.weekday + 6));
        final endOfLastWeek = startOfLastWeek.add(const Duration(days: 6));
        return {
          'start': DateTime(startOfLastWeek.year, startOfLastWeek.month, startOfLastWeek.day, 0, 0, 0),
          'end': DateTime(endOfLastWeek.year, endOfLastWeek.month, endOfLastWeek.day, 23, 59, 59),
        };

      case DateFilter.thisMonth:
        return {
          'start': DateTime(now.year, now.month, 1, 0, 0, 0),
          'end': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };

      case DateFilter.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
        return {
          'start': DateTime(lastMonth.year, lastMonth.month, 1, 0, 0, 0),
          'end': DateTime(lastDayOfLastMonth.year, lastDayOfLastMonth.month, lastDayOfLastMonth.day, 23, 59, 59),
        };

      case DateFilter.custom:
        return {
          'start': DateTime(customStartDate.value.year, customStartDate.value.month, customStartDate.value.day, 0, 0, 0),
          'end': DateTime(customEndDate.value.year, customEndDate.value.month, customEndDate.value.day, 23, 59, 59),
        };

      case DateFilter.all:
        return null; 
    }
  }

  String getFilterDisplayName() {
    switch (selectedFilter.value) {
      case DateFilter.today: return "Today";
      case DateFilter.last7Days: return "Last 7 Days";
      case DateFilter.thisWeek: return "This Week";
      case DateFilter.lastWeek: return "Last Week";
      case DateFilter.thisMonth: return "This Month";
      case DateFilter.lastMonth: return "Last Month";
      case DateFilter.custom: return "Custom Range";
      case DateFilter.all: return "All Time";
    }
  }

 


}
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';

// class TransactionsController extends GetxController {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;

//   // State
//   var transactions = <QueryDocumentSnapshot>[].obs;
//   var isLoading = true.obs;
  
//   // Search Text Controller
//   var searchController = "".obs;

//   @override
//   void onInit() {
//     super.onInit();
//     fetchTransactions();
//   }

//   // 1. Fetch Latest 50 Transactions
//   void fetchTransactions() async {
//     try {
//       isLoading.value = true;
//       final snapshot = await _db.collection('transactions')
//           .orderBy('timestamp', descending: true)
//           .limit(50)
//           .get();

//       transactions.value = snapshot.docs;
//     } catch (e) {
//       Get.snackbar("Error", "Could not load transactions: $e");
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   // 2. Search Function (By ID or Phone)
//   void searchTransactions(String query) async {
//     if (query.isEmpty) {
//       fetchTransactions(); // Reset if empty
//       return;
//     }

//     try {
//       isLoading.value = true;
      
//       // Firestore doesn't support substring search well. 
//       // We search for exact matches on ID or Phone.
      
//       // Try searching by ID first
//       var snapshot = await _db.collection('transactions')
//           .where('id', isEqualTo: query.trim())
//           .get();

//       // If no ID match, try Phone
//       if (snapshot.docs.isEmpty) {
//         // Handle phone formats (add 233 if missing)
//         String phone = query.trim();
//         if (phone.startsWith('0')) phone = '233${phone.substring(1)}';

//         snapshot = await _db.collection('transactions')
//             .where('customerPhone', isEqualTo: phone)
//             .orderBy('timestamp', descending: true)
//             .get();
//       }

//       transactions.value = snapshot.docs;

//     } catch (e) {
//       print(e);
//       Get.snackbar("Search Error", "Could not find record: $e");
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   // 3. Filter Logic (Optional helper to sort locally if needed)
//   List<QueryDocumentSnapshot> get filteredList {
//     return transactions;
//   }
// }