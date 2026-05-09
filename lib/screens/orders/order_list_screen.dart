// lib/screens/orders/order_list_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/csv_export_service.dart';
import 'create_order_screen.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final _svc = OrderService();
  List<OrderModel> _orders = [];
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      if (_statusFilter == 'All') {
        _orders = _svc.getAllOrders();
      } else {
        _orders = _svc.getOrdersByStatus(_statusFilter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(AppStrings.tx(context, 'Orders')),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            tooltip: AppStrings.tx(context, 'Export'),
            onSelected: (value) async {
              if (value == 'orders') {
                await CsvExportService.exportOrders(context);
              } else if (value == 'sales') {
                await CsvExportService.exportSalesReport(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'orders',
                child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.blue),
                  title: Text(AppStrings.tx(context, 'Export Order History')),
                  subtitle: Text(AppStrings.tx(context, 'CSV for CA / accounting'), style: const TextStyle(fontSize: 11)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'sales',
                child: ListTile(
                  leading: const Icon(Icons.table_chart, color: Colors.green),
                  title: Text(AppStrings.tx(context, 'Export Sales Report')),
                  subtitle: Text(AppStrings.tx(context, 'Item-wise breakdown'), style: const TextStyle(fontSize: 11)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('orders').listenable(),
        builder: (context, box, _) {
          if (_statusFilter == 'All') {
            _orders = _svc.getAllOrders();
          } else {
            _orders = _svc.getOrdersByStatus(_statusFilter);
          }
          return Column(children: [
        // Status filter chips
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: ['All', 'pending', 'confirmed', 'shipped', 'delivered', 'cancelled']
                .map((s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  s == 'All'
                      ? AppStrings.tx(context, 'All')
                      : AppStrings.tx(context, s),
                ),
                selected: _statusFilter == s,
                selectedColor: _chipColor(s),
                onSelected: (_) => setState(() { _statusFilter = s; _load(); }),
              ),
            )).toList(),
          ),
        ),
        // Summary bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _miniStat(AppStrings.tx(context, 'Today'), '₹${_svc.getTodaySales().toStringAsFixed(0)}'),
            _miniStat(AppStrings.tx(context, 'Orders'), '${_orders.length}'),
            _miniStat(AppStrings.tx(context, 'Revenue'), '₹${_svc.totalRevenue.toStringAsFixed(0)}'),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _orders.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _orders.length,
                  itemBuilder: (_, i) => _orderCard(_orders[i]),
                ),
        ),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateOrderScreen()));
          _load();
        },
        backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart), label: Text(AppStrings.tx(context, 'New Sale')),
      ),
    );
  }

  Widget _orderCard(OrderModel o) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: o.id!),
          ));
          _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: _statusClr(o.status).withValues(alpha: 0.15),
                child: Icon(_statusIcn(o.status), color: _statusClr(o.status), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(o.customerName ?? AppStrings.tx(context, 'Walk-in'),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${o.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                _statusBadge(o.status),
              ]),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text('${o.createdAt.day}/${o.createdAt.month}/${o.createdAt.year}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              const Spacer(),
              _payBadge(o.paymentStatus),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _statusBadge(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: _statusClr(s).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(AppStrings.tx(context, s),
        style: TextStyle(fontSize: 10, color: _statusClr(s), fontWeight: FontWeight.w600)),
  );

  Widget _payBadge(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: s == 'paid' ? Colors.green.shade50 : s == 'partial' ? Colors.orange.shade50 : Colors.red.shade50,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(AppStrings.tx(context, s).toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
            color: s == 'paid' ? Colors.green.shade700 : s == 'partial' ? Colors.orange.shade700 : Colors.red.shade700)),
  );

  Widget _miniStat(String l, String v) => Column(children: [
    Text(v, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
    Text(l, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
  ]);

  Color _chipColor(String s) {
    switch (s) {
      case 'delivered': return Colors.green.shade100;
      case 'cancelled': return Colors.red.shade100;
      default: return Colors.blue.shade100;
    }
  }

  Color _statusClr(String s) {
    switch (s) {
      case 'delivered': return Colors.green;
      case 'shipped': return Colors.blue;
      case 'confirmed': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _statusIcn(String s) {
    switch (s) {
      case 'delivered': return Icons.check_circle;
      case 'shipped': return Icons.local_shipping;
      case 'confirmed': return Icons.thumb_up;
      case 'cancelled': return Icons.cancel;
      default: return Icons.hourglass_empty;
    }
  }

  Widget _emptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(AppStrings.tx(context, 'No orders yet'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
    ]),
  );
}
