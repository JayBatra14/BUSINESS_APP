// lib/screens/dashboard_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_strings.dart';
import '../models/business_model.dart';
import '../models/order_model.dart';
import '../services/local_db_service.dart';
import '../services/product_service.dart';
import '../services/customer_service.dart';
import '../services/order_service.dart';
import '../services/expense_service.dart';
import 'customers/customer_list_screen.dart';
import 'products/product_list_screen.dart';
import 'orders/order_list_screen.dart';
import 'orders/create_order_screen.dart';
import 'customers/add_customer_screen.dart';
import 'products/add_product_screen.dart';
import 'more/more_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String businessId;
  const DashboardScreen({super.key, required this.businessId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _localDb = LocalDbService();
  final _productSvc = ProductService();
  final _customerSvc = CustomerService();
  final _orderSvc = OrderService();
  final _expenseSvc = ExpenseService();

  BusinessModel? _business;
  int _currentTab = 0;

  int totalCustomers = 0;
  int totalProducts = 0;
  int totalOrders = 0;
  double todaySales = 0.0;
  double todayExpenses = 0.0;
  List<double> weeklySales = [];
  List<OrderModel> recentOrders = [];
  final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final sales7 = _orderSvc.getSalesForLastDays(7);

    setState(() {
      _business = _localDb.getBusiness(widget.businessId);
      totalCustomers = _customerSvc.count;
      totalProducts = _productSvc.count;
      totalOrders = _orderSvc.count;
      todaySales = _orderSvc.getTodaySales();
      todayExpenses = _expenseSvc.getTodayExpenses();
      weeklySales = sales7;
      recentOrders = _orderSvc.getAllOrders().take(5).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildHomeTab(),
          const CustomerListScreen(),
          const ProductListScreen(),
          const OrderListScreen(),
          MoreScreen(businessId: widget.businessId),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) {
          setState(() => _currentTab = i);
          if (i == 0) _loadData(); // refresh dashboard
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard), label: AppStrings.tx(context, 'Home')),
          NavigationDestination(icon: const Icon(Icons.people_outline), selectedIcon: const Icon(Icons.people), label: AppStrings.tx(context, 'Customers')),
          NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), selectedIcon: const Icon(Icons.inventory_2), label: AppStrings.tx(context, 'Inventory')),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: AppStrings.tx(context, 'Orders')),
          NavigationDestination(icon: const Icon(Icons.more_horiz), label: AppStrings.tx(context, 'More')),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final maxY = weeklySales.isEmpty ? 1000.0 : (weeklySales.reduce((a, b) => a > b ? a : b) * 1.3);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_getGreeting(), style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              const SizedBox(height: 4),
              Text(_business?.ownerName ?? AppStrings.tx(context, 'Owner'),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5)),
              Text(_business?.businessName ?? '',
                  style: TextStyle(fontSize: 14, color: primary, fontWeight: FontWeight.w600)),
            ])),
            _buildLogoAvatar(),
          ]),

          const SizedBox(height: 30),

          // Today's sales + expenses cards
          Row(children: [
            Expanded(child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 16),
                Text(AppStrings.tx(context, "Today's Sales"), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('₹${todaySales.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ]),
            )),
            const SizedBox(width: 16),
            Expanded(child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.money_off, color: Colors.red.shade400, size: 24),
                ),
                const SizedBox(height: 16),
                Text(AppStrings.tx(context, "Today's Expenses"), style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('₹${todayExpenses.toStringAsFixed(0)}',
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 26, fontWeight: FontWeight.bold)),
              ]),
            )),
          ]),

          const SizedBox(height: 24),

          // Summary cards
          Row(children: [
            Expanded(child: _buildSummaryCard(title: AppStrings.tx(context, 'Customers'), value: '$totalCustomers', icon: Icons.people_outline, color: const Color(0xFF3B82F6))),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard(title: AppStrings.tx(context, 'Products'), value: '$totalProducts', icon: Icons.inventory_2_outlined, color: const Color(0xFF8B5CF6))),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard(title: AppStrings.tx(context, 'Orders'), value: '$totalOrders', icon: Icons.receipt_long_outlined, color: const Color(0xFF10B981))),
          ]),

          // Low stock alert
          if (_productSvc.getLowStockProducts().isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(child: Text(
                  '${_productSvc.getLowStockProducts().length} ${AppStrings.tx(context, 'products low on stock')}!',
                  style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w600, fontSize: 14),
                )),
                TextButton(
                  onPressed: () => setState(() => _currentTab = 2),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange.shade800),
                  child: Text(AppStrings.tx(context, 'View')),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 32),

          // Weekly chart
          Text(AppStrings.tx(context, 'Last 7 Days Sales'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          Container(
            height: 240, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20), 
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
            ),
            child: weeklySales.isEmpty || weeklySales.every((v) => v == 0)
                ? Center(child: Text(AppStrings.tx(context, 'No sales data yet'), style: const TextStyle(color: Color(0xFF94A3B8))))
                : BarChart(BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (rod) => primary,
                        getTooltipItem: (group, gI, rod, rI) =>
                            BarTooltipItem('₹${rod.toY.toInt()}', const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(weekDays[date.weekday - 1],
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                          );
                        },
                      )),
                    ),
                    gridData: FlGridData(
                      show: true, drawVerticalLine: false,
                      horizontalInterval: maxY / 4 == 0 ? 1 : maxY / 4,
                      getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(weeklySales.length, (i) => BarChartGroupData(x: i, barRods: [
                      BarChartRodData(toY: weeklySales[i], color: primary, width: 20,
                        borderRadius: BorderRadius.circular(4), backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxY, color: const Color(0xFFF1F5F9))),
                    ])),
                  )),
          ),

          const SizedBox(height: 32),

          // Quick actions
          Text(AppStrings.tx(context, 'Quick Actions'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildQuickAction(label: AppStrings.tx(context, 'New Sale'), icon: Icons.add_shopping_cart, color: const Color(0xFF3B82F6),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateOrderScreen()));
                _loadData();
              })),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickAction(label: AppStrings.tx(context, 'Add Customer'), icon: Icons.person_add, color: const Color(0xFF8B5CF6),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCustomerScreen()));
                _loadData();
              })),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickAction(label: AppStrings.tx(context, 'Add Product'), icon: Icons.add_box, color: const Color(0xFFF59E0B),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
                _loadData();
              })),
          ]),

          const SizedBox(height: 32),

          // Recent orders
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.tx(context, 'Recent Orders'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              TextButton(
                onPressed: () => setState(() => _currentTab = 3),
                child: Text(AppStrings.tx(context, 'View All'), style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (recentOrders.isEmpty)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFFCBD5E1)),
                SizedBox(height: 12),
                Text(AppStrings.tx(context, 'No orders yet'), style: const TextStyle(color: Color(0xFF64748B), fontSize: 16)),
              ]),
            )
          else
            ...recentOrders.map((o) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 5, offset: const Offset(0, 2))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _statusClr(o.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_statusIcn(o.status), size: 20, color: _statusClr(o.status)),
                ),
                title: Text('${o.orderNumber} • ${o.customerName ?? AppStrings.tx(context, "Walk-in")}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                subtitle: Text('${o.items.length} ${AppStrings.tx(context, "items")} • ${o.createdAt.day}/${o.createdAt.month}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                trailing: Text('₹${o.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 16)),
              ),
            )),

          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _buildLogoAvatar() {
    final logoPath = _business?.logoPath ?? '';
    if (logoPath.isNotEmpty && File(logoPath).existsSync()) {
      return CircleAvatar(radius: 28, backgroundImage: FileImage(File(logoPath)));
    }
    final initials = (_business?.businessName ?? 'B').substring(0, 1).toUpperCase();
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: Center(child: Text(initials, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildSummaryCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 5, offset: const Offset(0, 2))]
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildQuickAction({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Color _statusClr(String s) {
    switch (s) { case 'delivered': return const Color(0xFF10B981); case 'shipped': return const Color(0xFF3B82F6);
      case 'confirmed': return const Color(0xFFF59E0B); case 'cancelled': return const Color(0xFFEF4444); default: return const Color(0xFF94A3B8); }
  }
  IconData _statusIcn(String s) {
    switch (s) { case 'delivered': return Icons.check_circle; case 'shipped': return Icons.local_shipping;
      case 'confirmed': return Icons.thumb_up; case 'cancelled': return Icons.cancel; default: return Icons.hourglass_empty; }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.tx(context, 'Good Morning,');
    if (hour < 17) return AppStrings.tx(context, 'Good Afternoon,');
    return AppStrings.tx(context, 'Good Evening,');
  }
}