import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum DateFilter { today, thisWeek, lastWeek, thisMonth, lastMonth, custom, all }

class TransactionsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // State
  var transactions = <QueryDocumentSnapshot>[].obs;
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;

  // Pagination
  DocumentSnapshot? lastDocument;
  final int pageSize = 20; // Load 20 at a time

  // Filters
  var selectedFilter = DateFilter.all.obs;
  var customStartDate = DateTime.now().obs;
  var customEndDate = DateTime.now().obs;

  // Search
  var searchQuery = "".obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  // === FETCH TRANSACTIONS WITH PAGINATION ===
  void fetchTransactions({bool loadMore = false}) async {
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

      // Apply date filter
      final dateRange = _getDateRange();
      if (dateRange != null) {
        query = query
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange['start']!))
            .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(dateRange['end']!));
      }

      // Order by timestamp
      query = query.orderBy('timestamp', descending: true);

      // Pagination
      if (loadMore && lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      query = query.limit(pageSize);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMore.value = false;
        return;
      }

      // Check if there are more documents
      if (snapshot.docs.length < pageSize) {
        hasMore.value = false;
      }

      // Update last document for next pagination
      lastDocument = snapshot.docs.last;

      // Add to list
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

  // === SEARCH TRANSACTIONS ===
  void searchTransactions(String query) async {
    searchQuery.value = query.trim();

    if (searchQuery.value.isEmpty) {
      fetchTransactions(); // Reset if empty
      return;
    }

    try {
      isLoading.value = true;
      transactions.clear();
      hasMore.value = false; // Disable pagination for search

      // Try searching by ID first
      var snapshot = await _db
          .collection('transactions')
          .where('id', isEqualTo: searchQuery.value)
          .get();

      // If no ID match, try Phone
      if (snapshot.docs.isEmpty) {
        String phone = searchQuery.value;
        // Handle phone formats (add 233 if missing)
        if (phone.startsWith('0')) {
          phone = '233${phone.substring(1)}';
        }

        snapshot = await _db
            .collection('transactions')
            .where('customerPhone', isEqualTo: phone)
            .orderBy('timestamp', descending: true)
            .get();
      }

      transactions.value = snapshot.docs;

      if (snapshot.docs.isEmpty) {
        Get.snackbar(
          "No Results",
          "No transactions found for '$query'",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("Search Error: $e");
      Get.snackbar(
        "Search Error",
        "Could not find record: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // === CLEAR SEARCH ===
  void clearSearch() {
    searchQuery.value = "";
    fetchTransactions();
  }

  // === CHANGE DATE FILTER ===
  void changeFilter(DateFilter filter) {
    selectedFilter.value = filter;
    searchQuery.value = ""; // Clear search when filtering
    fetchTransactions();
  }

  // === SET CUSTOM DATE RANGE ===
  void setCustomDateRange(DateTime start, DateTime end) {
    customStartDate.value = start;
    customEndDate.value = end;
    selectedFilter.value = DateFilter.custom;
    searchQuery.value = ""; // Clear search
    fetchTransactions();
  }

  // === GET DATE RANGE BASED ON FILTER ===
  Map<String, DateTime>? _getDateRange() {
    final now = DateTime.now();

    switch (selectedFilter.value) {
      case DateFilter.today:
        return {
          'start': DateTime(now.year, now.month, now.day, 0, 0, 0),
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
        return null; // No filter
    }
  }

  // === LOAD MORE (Call this when user scrolls to bottom) ===
  void loadMore() {
    if (searchQuery.value.isNotEmpty) return; // Don't paginate during search
    fetchTransactions(loadMore: true);
  }

  // === REFRESH ===
  void refresh() {
    searchQuery.value = "";
    fetchTransactions();
  }

  // === GET FILTER DISPLAY NAME ===
  String getFilterDisplayName() {
    switch (selectedFilter.value) {
      case DateFilter.today:
        return "Today";
      case DateFilter.thisWeek:
        return "This Week";
      case DateFilter.lastWeek:
        return "Last Week";
      case DateFilter.thisMonth:
        return "This Month";
      case DateFilter.lastMonth:
        return "Last Month";
      case DateFilter.custom:
        return "Custom Range";
      case DateFilter.all:
        return "All Time";
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