import 'package:bunso_ecopark_admin/controllers/transactions_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final controller = Get.find<TransactionsController>();
      controller.loadMore();
    }
  }

  // Theme Colors
  static const primaryGreen = Color(0xFF2D5016);
  static const accentGreen = Color(0xFF4A7C2B);
  static const lightGreen = Color(0xFF5D9939);
  static const accentYellow = Color(0xFFFFC107);
  static const bgColor = Color(0xFFF5F7F0);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TransactionsController());
    final isDesktop = MediaQuery.of(context).size.width > 1024;
    final isTablet = MediaQuery.of(context).size.width > 768;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === HEADER & CONTROLS ===
            _buildHeader(context, controller, isDesktop, isMobile),
            const SizedBox(height: 20),

            // === DATE FILTERS ===
            _buildDateFilters(context, controller, isMobile),
            const SizedBox(height: 30),

            // === STATISTICS CARDS ===
            Obx(() {
              if (controller.isLoading.value && controller.transactions.isEmpty) {
                return const SizedBox.shrink();
              }

              // Calculate statistics
              int totalTransactions = controller.transactions.length;
              double totalAmount = 0;
              int paidCount = 0;
              int refundedCount = 0;

              for (var doc in controller.transactions) {
                final data = doc.data() as Map<String, dynamic>;
                totalAmount += (data['totalAmount'] ?? 0).toDouble();
                String status = data['status'] ?? 'Paid';
                if (status == 'Paid') paidCount++;
                if (status == 'Refunded') refundedCount++;
              }

              return Column(
                children: [
                  _buildStatsRow(
                    context,
                    isDesktop,
                    [
                      _StatData("Total Transactions", "$totalTransactions", Icons.receipt_long, accentGreen),
                      _StatData("Total Revenue", "GHS ${totalAmount.toStringAsFixed(2)}", Icons.account_balance_wallet, primaryGreen),
                      _StatData("Paid", "$paidCount", Icons.check_circle, Colors.green),
                      _StatData("Refunded", "$refundedCount", Icons.refresh, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),

            // === TRANSACTIONS TABLE/LIST ===
            Obx(() {
              if (controller.isLoading.value && controller.transactions.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(60.0),
                    child: CircularProgressIndicator(color: primaryGreen),
                  ),
                );
              }

              if (controller.transactions.isEmpty) {
                return _buildEmptyState(controller);
              }

              // For mobile, show cards; for desktop/tablet, show table
              return Column(
                children: [
                  if (isMobile)
                    _buildMobileList(controller.transactions)
                  else
                    _buildDesktopTable(controller.transactions),
                  
                  // Load More Indicator
                  Obx(() {
                    if (controller.isLoadingMore.value) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: CircularProgressIndicator(color: primaryGreen),
                        ),
                      );
                    }
                    
                    if (!controller.hasMore.value && controller.transactions.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            "No more transactions to load",
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ),
                      );
                    }
                    
                    return const SizedBox.shrink();
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // === DATE FILTERS ===
  Widget _buildDateFilters(BuildContext context, TransactionsController controller, bool isMobile) {
    return Obx(() {
      final selected = controller.selectedFilter.value;
      
      if (isMobile) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Filter by Date",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryGreen),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip("All", DateFilter.all, selected, controller),
                _buildFilterChip("Today", DateFilter.today, selected, controller),
                _buildFilterChip("This Week", DateFilter.thisWeek, selected, controller),
                _buildFilterChip("Last Week", DateFilter.lastWeek, selected, controller),
                _buildFilterChip("This Month", DateFilter.thisMonth, selected, controller),
                _buildFilterChip("Last Month", DateFilter.lastMonth, selected, controller),
                _buildCustomDateButton(context, controller),
              ],
            ),
          ],
        );
      }

      return Row(
        children: [
          const Text(
            "Filter by Date:",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("All", DateFilter.all, selected, controller),
                  const SizedBox(width: 8),
                  _buildFilterChip("Today", DateFilter.today, selected, controller),
                  const SizedBox(width: 8),
                  _buildFilterChip("This Week", DateFilter.thisWeek, selected, controller),
                  const SizedBox(width: 8),
                  _buildFilterChip("Last Week", DateFilter.lastWeek, selected, controller),
                  const SizedBox(width: 8),
                  _buildFilterChip("This Month", DateFilter.thisMonth, selected, controller),
                  const SizedBox(width: 8),
                  _buildFilterChip("Last Month", DateFilter.lastMonth, selected, controller),
                  const SizedBox(width: 8),
                  _buildCustomDateButton(context, controller),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFilterChip(String label, DateFilter filter, DateFilter selected, TransactionsController controller) {
    final isSelected = selected == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool value) {
        if (value) controller.changeFilter(filter);
      },
      backgroundColor: Colors.white,
      selectedColor: primaryGreen,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : primaryGreen,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? primaryGreen : primaryGreen.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildCustomDateButton(BuildContext context, TransactionsController controller) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == DateFilter.custom;
      return ActionChip(
        avatar: Icon(
          Icons.calendar_month,
          color: isSelected ? Colors.white : primaryGreen,
          size: 18,
        ),
        label: Text(
          isSelected 
            ? "${DateFormat('MMM dd').format(controller.customStartDate.value)} - ${DateFormat('MMM dd').format(controller.customEndDate.value)}"
            : "Custom Range",
        ),
        backgroundColor: isSelected ? primaryGreen : Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : primaryGreen,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? primaryGreen : primaryGreen.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onPressed: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            initialDateRange: DateTimeRange(
              start: controller.customStartDate.value,
              end: controller.customEndDate.value,
            ),
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
          if (picked != null) {
            controller.setCustomDateRange(picked.start, picked.end);
          }
        },
      );
    });
  }

  // === HEADER WIDGET ===
  Widget _buildHeader(BuildContext context, TransactionsController controller, bool isDesktop, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Transactions",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryGreen),
                    ),
                    Text(
                      "View and manage all transactions",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(controller),
        ],
      );
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.receipt_long, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Transactions",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryGreen),
              ),
              Text(
                "View and manage all transactions",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        _buildSearchBar(controller),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => controller.refresh(),
          icon: const Icon(Icons.refresh, color: primaryGreen),
          tooltip: "Refresh",
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(TransactionsController controller) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 350),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGreen.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        return TextField(
          onSubmitted: (value) => controller.searchTransactions(value),
          decoration: InputDecoration(
            hintText: "Search ID or Phone...",
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: primaryGreen),
            suffixIcon: controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                    onPressed: () => controller.clearSearch(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        );
      }),
    );
  }

  // === STATISTICS CARDS ===
  Widget _buildStatsRow(BuildContext context, bool isDesktop, List<_StatData> stats) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) => _buildStatCard(stats[index]),
      );
    }

    return Row(
      children: stats
          .map((s) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildStatCard(s),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildStatCard(_StatData data) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

  // === DESKTOP TABLE VIEW ===
  Widget _buildDesktopTable(List<QueryDocumentSnapshot> transactions) {
    return Container(
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(bgColor),
          headingRowHeight: 60,
          dataRowMinHeight: 70,
          dataRowMaxHeight: 80,
          columnSpacing: 30,
          horizontalMargin: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          columns: const [
            DataColumn(
              label: Text(
                "Date & Time",
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 14),
              ),
            ),
            DataColumn(
              label: Text(
                "Receipt #",
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 14),
              ),
            ),
            DataColumn(
              label: Text(
                "Customer",
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 14),
              ),
            ),
            DataColumn(
              label: Text(
                "Items",
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 14),
              ),
            ),
            DataColumn(
              label: Text(
                "Amount",
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 14),
              ),
            ),
            DataColumn(
              label: Text(
                "Status",
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 14),
              ),
            ),
            DataColumn(
              label: Text(
                "Action",
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 14),
              ),
            ),
          ],
          rows: transactions.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildTableRow(data);
          }).toList(),
        ),
      ),
    );
  }

  DataRow _buildTableRow(Map<String, dynamic> data) {
    // Format Date
    final Timestamp? ts = data['timestamp'];
    final dateStr = ts != null ? DateFormat('MMM dd, yyyy').format(ts.toDate()) : 'Unknown';
    final timeStr = ts != null ? DateFormat('h:mm a').format(ts.toDate()) : '';

    // Format Amount
    final double amount = (data['totalAmount'] ?? 0).toDouble();

    // Status Color
    final String status = data['status'] ?? 'Paid';
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle;
    if (status == 'Refunded') {
      statusColor = Colors.orange;
      statusIcon = Icons.refresh;
    }
    if (status == 'Cancelled') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }

    return DataRow(
      cells: [
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentYellow.withOpacity(0.3)),
            ),
            child: Text(
              data['id'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryGreen),
            ),
          ),
        ),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['customerName'] ?? 'Guest',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.phone, size: 11, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    data['customerPhone'] ?? 'N/A',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: lightGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${data['totalItems']} items",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryGreen),
            ),
          ),
        ),
        DataCell(
          Text(
            "GHS ${amount.toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryGreen),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: primaryGreen),
            tooltip: "View Receipt",
            style: IconButton.styleFrom(
              backgroundColor: primaryGreen.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final url = data['receiptUrl'];
              if (url != null) {
                launchUrl(Uri.parse(url));
              } else {
                Get.snackbar(
                  "Info",
                  "No PDF available for this receipt.",
                  backgroundColor: accentYellow,
                  colorText: Colors.black,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // === MOBILE CARD VIEW ===
  Widget _buildMobileList(List<QueryDocumentSnapshot> transactions) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final data = transactions[index].data() as Map<String, dynamic>;
        return _buildMobileCard(data);
      },
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> data) {
    // Format Date
    final Timestamp? ts = data['timestamp'];
    final dateStr = ts != null ? DateFormat('MMM dd, yyyy').format(ts.toDate()) : 'Unknown';
    final timeStr = ts != null ? DateFormat('h:mm a').format(ts.toDate()) : '';

    // Format Amount
    final double amount = (data['totalAmount'] ?? 0).toDouble();

    // Status Color
    final String status = data['status'] ?? 'Paid';
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle;
    if (status == 'Refunded') {
      statusColor = Colors.orange;
      statusIcon = Icons.refresh;
    }
    if (status == 'Cancelled') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentYellow.withOpacity(0.3)),
                ),
                child: Text(
                  data['id'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: primaryGreen),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Customer Info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person, color: primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['customerName'] ?? 'Guest',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['customerPhone'] ?? 'N/A',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Transaction Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(Icons.calendar_today, "$dateStr • $timeStr"),
              _buildInfoChip(Icons.shopping_bag, "${data['totalItems']} items"),
            ],
          ),
          const SizedBox(height: 16),

          // Amount & Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Amount",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "GHS ${amount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text("Receipt", style: TextStyle(fontSize: 12)),
                onPressed: () {
                  final url = data['receiptUrl'];
                  if (url != null) {
                    launchUrl(Uri.parse(url));
                  } else {
                    Get.snackbar(
                      "Info",
                      "No PDF available for this receipt.",
                      backgroundColor: accentYellow,
                      colorText: Colors.black,
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
decoration: BoxDecoration(
color: bgColor,
borderRadius: BorderRadius.circular(8),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(icon, size: 14, color: Colors.grey[700]),
const SizedBox(width: 6),
Text(
text,
style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
),
],
),
);
}

// === EMPTY STATE ===
Widget _buildEmptyState(TransactionsController controller) {
final isSearching = controller.searchQuery.value.isNotEmpty;
final isFiltered = controller.selectedFilter.value != DateFilter.all;
return Container(
  padding: const EdgeInsets.all(60),
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
  child: Center(
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSearching || isFiltered ? Icons.search_off : Icons.receipt_long,
            size: 60,
            color: primaryGreen,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isSearching
              ? "No Results Found"
              : isFiltered
                  ? "No Transactions in This Period"
                  : "No Transactions Found",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryGreen),
        ),
        const SizedBox(height: 8),
        Text(
          isSearching
              ? "Try a different search term"
              : isFiltered
                  ? "Try selecting a different date range"
                  : "Transactions will appear here once customers make purchases",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        if (isSearching || isFiltered) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.clear_all),
            label: const Text("Clear Filters"),
            onPressed: () {
              controller.clearSearch();
              controller.changeFilter(DateFilter.all);
            },
          ),
        ],
      ],
    ),
  ),
);
}
}
// Helper class for statistics
class _StatData {
final String title;
final String value;
final IconData icon;
final Color color;
_StatData(this.title, this.value, this.icon, this.color);
}
// import 'package:bunso_ecopark_admin/controllers/transactions_controller.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart'; // Add to pubspec.yaml

// class TransactionsView extends StatelessWidget {
//   const TransactionsView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(TransactionsController());

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // === HEADER & SEARCH ===
//             Row(
//               children: [
//                 const Text("Transactions", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//                 const Spacer(),
//                 // Search Box
//                 Container(
//                   width: 300,
//                   decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
//                   child: TextField(
//                     onSubmitted: (value) => controller.searchTransactions(value),
//                     decoration: const InputDecoration(
//                       hintText: "Search ID or Phone...",
//                       prefixIcon: Icon(Icons.search),
//                       border: InputBorder.none,
//                       contentPadding: EdgeInsets.all(16),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 IconButton(
//                   onPressed: () => controller.fetchTransactions(),
//                   icon: const Icon(Icons.refresh),
//                   tooltip: "Refresh List",
//                 )
//               ],
//             ),
//             const SizedBox(height: 20),

//             // === DATA TABLE ===
//             Expanded(
//               child: Card(
//                 elevation: 2,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 child: Obx(() {
//                   if (controller.isLoading.value) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (controller.transactions.isEmpty) {
//                     return const Center(child: Text("No transactions found."));
//                   }

//                   return SizedBox(
//                     width: double.infinity,
//                     child: SingleChildScrollView(
//                       child: DataTable(
//                         headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
//                         columns: const [
//                           DataColumn(label: Text("Date")),
//                           DataColumn(label: Text("Receipt #")),
//                           DataColumn(label: Text("Customer")),
//                           DataColumn(label: Text("Items")),
//                           DataColumn(label: Text("Amount")),
//                           DataColumn(label: Text("Status")),
//                           DataColumn(label: Text("Action")),
//                         ],
//                         rows: controller.transactions.map((doc) {
//                           final data = doc.data() as Map<String, dynamic>;
//                           return _buildRow(data);
//                         }).toList(),
//                       ),
//                     ),
//                   );
//                 }),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   DataRow _buildRow(Map<String, dynamic> data) {
//     // Format Date
//     final Timestamp? ts = data['timestamp'];
//     final dateStr = ts != null 
//         ? DateFormat('MMM dd, h:mm a').format(ts.toDate()) 
//         : 'Unknown';

//     // Format Amount
//     final double amount = (data['totalAmount'] ?? 0).toDouble();

//     // Status Color
//     final String status = data['status'] ?? 'Paid';
//     Color statusColor = Colors.green;
//     if (status == 'Refunded') statusColor = Colors.orange;
//     if (status == 'Cancelled') statusColor = Colors.red;

//     return DataRow(cells: [
//       DataCell(Text(dateStr, style: const TextStyle(fontSize: 13))),
//       DataCell(Text(data['id'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
//       DataCell(Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(data['customerName'] ?? 'Guest', style: const TextStyle(fontWeight: FontWeight.w500)),
//           Text(data['customerPhone'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
//         ],
//       )),
//       DataCell(Text("${data['totalItems']} items")),
//       DataCell(Text("GHS ${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold))),
//       DataCell(
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           decoration: BoxDecoration(
//             color: statusColor.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(4),
//             border: Border.all(color: statusColor),
//           ),
//           child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
//         ),
//       ),
//       DataCell(
//         // View PDF Button
//         IconButton(
//           icon: const Icon(Icons.picture_as_pdf, color: Colors.grey),
//           tooltip: "View Receipt",
//           onPressed: () {
//             final url = data['receiptUrl'];
//             if (url != null) {
//               launchUrl(Uri.parse(url));
//             } else {
//               Get.snackbar("Info", "No PDF available for this receipt.");
//             }
//           },
//         ),
//       ),
//     ]);
//   }
// }