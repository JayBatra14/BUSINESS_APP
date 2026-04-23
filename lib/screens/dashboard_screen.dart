// lib/screens/dashboard_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
      backgroundColor: Colors.grey.shade50,
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
        backgroundColor: Colors.white,
        indicatorColor: Colors.blue.shade100,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Customers'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final maxY = weeklySales.isEmpty ? 1000.0 : (weeklySales.reduce((a, b) => a > b ? a : b) * 1.3);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_getGreeting(), style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(_business?.ownerName ?? 'Owner',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(_business?.businessName ?? '',
                  style: TextStyle(fontSize: 13, color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
            ])),
            _buildLogoAvatar(),
          ]),

          const SizedBox(height: 20),

          // Today's sales + expenses cards
          Row(children: [
            Expanded(child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Today's Sales", style: TextStyle(color: Colors.blue.shade100, fontSize: 12)),
                const SizedBox(height: 4),
                Text('₹${todaySales.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ]),
            )),
            const SizedBox(width: 10),
            Expanded(child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Today's Expenses", style: TextStyle(color: Colors.red.shade100, fontSize: 12)),
                const SizedBox(height: 4),
                Text('₹${todayExpenses.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ]),
            )),
          ]),

          const SizedBox(height: 16),

          // Summary cards
          Row(children: [
            Expanded(child: _buildSummaryCard(title: 'Customers', value: '$totalCustomers', icon: Icons.people, color: Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryCard(title: 'Products', value: '$totalProducts', icon: Icons.inventory_2, color: Colors.orange)),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryCard(title: 'Orders', value: '$totalOrders', icon: Icons.receipt_long, color: Colors.purple)),
          ]),

          // Low stock alert
          if (_productSvc.getLowStockProducts().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  '${_productSvc.getLowStockProducts().length} products are low on stock!',
                  style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w500, fontSize: 13),
                )),
                TextButton(
                  onPressed: () => setState(() => _currentTab = 2),
                  child: const Text('View'),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 20),

          // Weekly chart
          Text('Last 7 days', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 12),
          Container(
            height: 200, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: weeklySales.isEmpty || weeklySales.every((v) => v == 0)
                ? Center(child: Text('No sales data yet', style: TextStyle(color: Colors.grey.shade400)))
                : BarChart(BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, gI, rod, rI) =>
                            BarTooltipItem('₹${rod.toY.toInt()}', const TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(weekDays[value.toInt() % 7],
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ),
                      )),
                    ),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(weeklySales.length, (i) => BarChartGroupData(x: i, barRods: [
                      BarChartRodData(toY: weeklySales[i], color: Colors.blue.shade600, width: 22,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
                    ])),
                  )),
          ),

          const SizedBox(height: 20),

          // Quick actions
          Text('Quick actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildQuickAction(label: 'New Sale', icon: Icons.add_shopping_cart, color: Colors.blue,
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateOrderScreen()));
                _loadData();
              })),
            const SizedBox(width: 10),
            Expanded(child: _buildQuickAction(label: 'Add Customer', icon: Icons.person_add, color: Colors.green,
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCustomerScreen()));
                _loadData();
              })),
            const SizedBox(width: 10),
            Expanded(child: _buildQuickAction(label: 'Add Product', icon: Icons.add_box, color: Colors.orange,
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
                _loadData();
              })),
          ]),

          const SizedBox(height: 20),

          // Recent orders
          Text('Recent orders', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 12),
          if (recentOrders.isEmpty)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(children: [
                Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text('No orders yet', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
              ]),
            )
          else
            ...recentOrders.map((o) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: _statusClr(o.status).withValues(alpha: 0.15),
                  child: Icon(_statusIcn(o.status), size: 16, color: _statusClr(o.status)),
                ),
                title: Text('${o.orderNumber} • ${o.customerName ?? "Walk-in"}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                trailing: Text('₹${o.grandTotal.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
              ),
            )),

          const SizedBox(height: 16),
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
    return CircleAvatar(
      radius: 28, backgroundColor: Colors.blue.shade100,
      child: Text(initials, style: TextStyle(color: Colors.blue.shade700, fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSummaryCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ]),
    );
  }

  Widget _buildQuickAction({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Color _statusClr(String s) {
    switch (s) { case 'delivered': return Colors.green; case 'shipped': return Colors.blue;
      case 'confirmed': return Colors.orange; case 'cancelled': return Colors.red; default: return Colors.grey; }
  }
  IconData _statusIcn(String s) {
    switch (s) { case 'delivered': return Icons.check_circle; case 'shipped': return Icons.local_shipping;
      case 'confirmed': return Icons.thumb_up; case 'cancelled': return Icons.cancel; default: return Icons.hourglass_empty; }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}