// lib/screens/more/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_strings.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../services/customer_service.dart';
import '../../services/expense_service.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _orderSvc = OrderService();
  final _productSvc = ProductService();
  final _customerSvc = CustomerService();
  final _expenseSvc = ExpenseService();

  // Date filter
  String _period = 'This Month';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Filter orders by selected period
  List<OrderModel> _filteredOrders() {
    final all = _orderSvc.getAllOrders();
    final now = DateTime.now();
    switch (_period) {
      case 'Today':
        final today = DateTime(now.year, now.month, now.day);
        return all.where((o) => DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day) == today).toList();
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
        return all.where((o) => o.createdAt.isAfter(start)).toList();
      case 'This Month':
        return all.where((o) => o.createdAt.year == now.year && o.createdAt.month == now.month).toList();
      case 'All Time':
        return all;
      default:
        return all;
    }
  }

  double _filteredExpenses() {
    final all = _expenseSvc.getAllExpenses();
    final now = DateTime.now();
    switch (_period) {
      case 'Today':
        final today = DateTime(now.year, now.month, now.day);
        return all.where((e) => DateTime(e.date.year, e.date.month, e.date.day) == today).fold(0.0, (s, e) => s + e.amount);
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
        return all.where((e) => e.date.isAfter(start)).fold(0.0, (s, e) => s + e.amount);
      case 'This Month':
        return all.where((e) => e.date.year == now.year && e.date.month == now.month).fold(0.0, (s, e) => s + e.amount);
      case 'All Time':
        return all.fold(0.0, (s, e) => s + e.amount);
      default:
        return all.fold(0.0, (s, e) => s + e.amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(AppStrings.tx(context, 'Reports & Analytics')),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.blue.shade100,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: AppStrings.tx(context, 'Profit & Loss')),
            Tab(text: AppStrings.tx(context, 'Top Products')),
            Tab(text: AppStrings.tx(context, 'Customer Sales')),
            Tab(text: AppStrings.tx(context, 'Dead Stock')),
          ],
        ),
      ),
      body: Column(
        children: [
          // Period filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ['Today', 'This Week', 'This Month', 'All Time'].map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(AppStrings.tx(context, p), style: const TextStyle(fontSize: 12)),
                  selected: _period == p,
                  selectedColor: Colors.blue.shade100,
                  onSelected: (_) => setState(() => _period = p),
                ),
              )).toList(),
            ),
          ),
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildProfitLoss(),
                _buildTopProducts(),
                _buildCustomerSales(),
                _buildDeadStock(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // TAB 1: PROFIT & LOSS
  // ═══════════════════════════════════════════════
  Widget _buildProfitLoss() {
    final orders = _filteredOrders();
    final totalRevenue = orders.fold(0.0, (s, o) => s + o.grandTotal);
    final totalReceived = orders.fold(0.0, (s, o) => s + o.amountPaid);
    final totalPending = orders.fold(0.0, (s, o) => s + o.balanceDue);

    // Calculate cost of goods sold
    double totalCost = 0;
    for (final o in orders) {
      for (final item in o.items) {
        final product = _productSvc.getProduct(item.productId);
        totalCost += (product?.costPrice ?? 0) * item.quantity;
      }
    }

    final totalExpenses = _filteredExpenses();
    final grossProfit = totalRevenue - totalCost;
    final netProfit = grossProfit - totalExpenses;
    final profitMargin = totalRevenue > 0 ? (netProfit / totalRevenue * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Net Profit Hero Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: netProfit >= 0
                  ? [const Color(0xFF2E7D32), const Color(0xFF43A047)]
                  : [const Color(0xFFC62828), const Color(0xFFE53935)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            Text(
              AppStrings.tx(context, netProfit >= 0 ? 'Net Profit' : 'Net Loss'),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${netProfit.abs().toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${profitMargin.toStringAsFixed(1)}% ${AppStrings.tx(context, "margin")}',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // Revenue section
        _plCard(AppStrings.tx(context, 'Revenue'), [
          _plRow(AppStrings.tx(context, 'Total Sales'), totalRevenue, Colors.blue),
          _plRow(AppStrings.tx(context, 'Received'), totalReceived, Colors.green),
          _plRow(AppStrings.tx(context, 'Pending'), totalPending, Colors.orange),
        ]),

        const SizedBox(height: 12),

        // Costs section
        _plCard(AppStrings.tx(context, 'Costs'), [
          _plRow(AppStrings.tx(context, 'Cost of Goods Sold'), totalCost, Colors.red),
          _plRow(AppStrings.tx(context, 'Operating Expenses'), totalExpenses, Colors.red),
        ]),

        const SizedBox(height: 12),

        // Profit breakdown
        _plCard(AppStrings.tx(context, 'Profit Breakdown'), [
          _plRow(AppStrings.tx(context, 'Gross Profit'), grossProfit, grossProfit >= 0 ? Colors.green : Colors.red),
          _plRow(AppStrings.tx(context, 'Net Profit'), netProfit, netProfit >= 0 ? Colors.green : Colors.red),
          _plRow(AppStrings.tx(context, 'Profit Margin'), null, Colors.blue, suffix: '${profitMargin.toStringAsFixed(1)}%'),
        ]),

        const SizedBox(height: 12),

        // Orders summary
        _plCard(AppStrings.tx(context, 'Order Summary'), [
          _plRow(AppStrings.tx(context, 'Total Orders'), null, Colors.blue, suffix: '${orders.length}'),
          _plRow(AppStrings.tx(context, 'Paid Orders'), null, Colors.green, suffix: '${orders.where((o) => o.paymentStatus == "paid").length}'),
          _plRow(AppStrings.tx(context, 'Unpaid Orders'), null, Colors.red, suffix: '${orders.where((o) => o.paymentStatus == "unpaid").length}'),
        ]),
      ]),
    );
  }

  Widget _plCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _plRow(String label, double? value, Color color, {String? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          suffix ?? '₹${value!.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════
  // TAB 2: TOP SELLING PRODUCTS
  // ═══════════════════════════════════════════════
  Widget _buildTopProducts() {
    final orders = _filteredOrders();

    // Aggregate product sales
    final Map<String, _ProductStat> stats = {};
    for (final o in orders) {
      for (final item in o.items) {
        stats.putIfAbsent(item.productId, () => _ProductStat(item.productName));
        stats[item.productId]!.qty += item.quantity;
        stats[item.productId]!.revenue += item.total;
        final product = _productSvc.getProduct(item.productId);
        stats[item.productId]!.profit += (item.unitPrice - (product?.costPrice ?? 0)) * item.quantity;
      }
    }

    final sorted = stats.entries.toList()..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));
    final topRevenue = sorted.isNotEmpty ? sorted.first.value.revenue : 1.0;

    if (sorted.isEmpty) {
      return _emptyState(AppStrings.tx(context, 'No sales data yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final entry = sorted[i];
        final stat = entry.value;
        final percentage = (stat.revenue / topRevenue * 100);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // Rank badge
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: i < 3 ? [Colors.amber, Colors.grey.shade400, Colors.brown.shade300][i] : Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: i < 3 ? Colors.white : Colors.blue.shade700,
                    fontWeight: FontWeight.bold, fontSize: 14,
                  ),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(stat.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text('${stat.qty.toStringAsFixed(0)} ${AppStrings.tx(context, "sold")}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${stat.revenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '${AppStrings.tx(context, "Profit")}: ₹${stat.profit.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 11, color: stat.profit >= 0 ? Colors.green : Colors.red),
                ),
              ]),
            ]),
            const SizedBox(height: 10),
            // Revenue bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 6,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  i == 0 ? Colors.amber.shade700 : Colors.blue.shade400,
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  // TAB 3: CUSTOMER-WISE SALES
  // ═══════════════════════════════════════════════
  Widget _buildCustomerSales() {
    final orders = _filteredOrders();

    // Aggregate customer sales
    final Map<String, _CustStat> stats = {};
    for (final o in orders) {
      final key = o.customerId ?? 'walk-in';
      final name = o.customerName ?? 'Walk-in';
      stats.putIfAbsent(key, () => _CustStat(name));
      stats[key]!.orderCount++;
      stats[key]!.totalSpent += o.grandTotal;
      stats[key]!.totalPaid += o.amountPaid;
    }

    final sorted = stats.entries.toList()..sort((a, b) => b.value.totalSpent.compareTo(a.value.totalSpent));

    if (sorted.isEmpty) {
      return _emptyState(AppStrings.tx(context, 'No sales data yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final stat = sorted[i].value;
        final pendingAmount = stat.totalSpent - stat.totalPaid;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              radius: 24,
              child: Text(stat.name[0].toUpperCase(),
                  style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(stat.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 4),
              Row(children: [
                _miniChip('${stat.orderCount} ${AppStrings.tx(context, "orders")}', Colors.blue),
                const SizedBox(width: 8),
                if (pendingAmount > 0) _miniChip('₹${pendingAmount.toStringAsFixed(0)} ${AppStrings.tx(context, "due")}', Colors.red),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹${stat.totalSpent.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(AppStrings.tx(context, 'total'), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _miniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }

  // ═══════════════════════════════════════════════
  // TAB 4: DEAD STOCK
  // ═══════════════════════════════════════════════
  Widget _buildDeadStock() {
    final allProducts = _productSvc.getAllProducts();
    final orders = _orderSvc.getAllOrders(); // all orders ever

    // Get set of product IDs that have been sold
    final soldProductIds = <String>{};
    for (final o in orders) {
      for (final item in o.items) {
        soldProductIds.add(item.productId);
      }
    }

    // Dead stock = products never sold, or filter by period
    final deadStock = allProducts.where((p) {
      if (!soldProductIds.contains(p.id)) return true; // never sold at all
      return false;
    }).toList();

    // Slow movers = products sold but very little
    final Map<String, double> soldQty = {};
    for (final o in _filteredOrders()) {
      for (final item in o.items) {
        soldQty[item.productId] = (soldQty[item.productId] ?? 0) + item.quantity;
      }
    }
    final slowMovers = allProducts.where((p) {
      final qty = soldQty[p.id] ?? 0;
      return qty > 0 && qty <= 2 && !deadStock.contains(p);
    }).toList();

    // Calculate total value locked
    final deadValue = deadStock.fold(0.0, (s, p) => s + (p.sellingPrice * p.stockQty));
    final slowValue = slowMovers.fold(0.0, (s, p) => s + (p.sellingPrice * p.stockQty));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Summary cards
        Row(children: [
          Expanded(child: _deadStockSummary(
            AppStrings.tx(context, 'Dead Stock'),
            '${deadStock.length}',
            '₹${deadValue.toStringAsFixed(0)}',
            Colors.red,
          )),
          const SizedBox(width: 12),
          Expanded(child: _deadStockSummary(
            AppStrings.tx(context, 'Slow Movers'),
            '${slowMovers.length}',
            '₹${slowValue.toStringAsFixed(0)}',
            Colors.orange,
          )),
        ]),

        const SizedBox(height: 20),

        // Dead stock list
        if (deadStock.isNotEmpty) ...[
          _sectionHeader(AppStrings.tx(context, 'Never Sold'), Colors.red),
          const SizedBox(height: 8),
          ...deadStock.map((p) => _deadStockItem(p, AppStrings.tx(context, 'Never sold'), Colors.red)),
        ],

        if (slowMovers.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionHeader(AppStrings.tx(context, 'Slow Moving'), Colors.orange),
          const SizedBox(height: 8),
          ...slowMovers.map((p) {
            final qty = soldQty[p.id] ?? 0;
            return _deadStockItem(p, '${qty.toStringAsFixed(0)} ${AppStrings.tx(context, "sold")}', Colors.orange);
          }),
        ],

        if (deadStock.isEmpty && slowMovers.isEmpty)
          _emptyState(AppStrings.tx(context, 'All products are selling well!')),
      ]),
    );
  }

  Widget _deadStockSummary(String title, String count, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text('$value ${AppStrings.tx(context, "locked")}', style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7))),
      ]),
    );
  }

  Widget _deadStockItem(ProductModel p, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.inventory_2, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Row(children: [
            Text('${AppStrings.tx(context, "Stock")}: ${p.stockQty.toStringAsFixed(0)} ${p.unit}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(width: 8),
            _miniChip(status, color),
          ]),
        ])),
        Text('₹${(p.sellingPrice * p.stockQty).toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      ]),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Row(children: [
      Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.analytics_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        ]),
      ),
    );
  }
}

// ── Helper data classes
class _ProductStat {
  final String name;
  double qty = 0;
  double revenue = 0;
  double profit = 0;
  _ProductStat(this.name);
}

class _CustStat {
  final String name;
  int orderCount = 0;
  double totalSpent = 0;
  double totalPaid = 0;
  _CustStat(this.name);
}
