// lib/screens/customers/customer_detail_screen.dart

import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../models/order_model.dart';
import '../../services/customer_service.dart';
import '../../services/order_service.dart';
import 'add_customer_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _custSvc = CustomerService();
  final _orderSvc = OrderService();
  CustomerModel? _customer;
  List<OrderModel> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _customer = _custSvc.getCustomer(widget.customerId);
      _orders = _orderSvc.getOrdersByCustomer(widget.customerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: const Center(child: Text('Customer not found')),
      );
    }
    final c = _customer!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(c.name),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddCustomerScreen(existingCustomer: c),
              ));
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 28, backgroundColor: Colors.white,
                  child: Text(c.name[0].toUpperCase(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  if (c.email != null && c.email!.isNotEmpty)
                    Text(c.email!, style: TextStyle(color: Colors.blue.shade100, fontSize: 13)),
                ])),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                _statChip('Orders', '${_orders.length}', Icons.receipt_long),
                const SizedBox(width: 12),
                _statChip('Balance', '₹${c.balance.toStringAsFixed(0)}',
                    c.balance > 0 ? Icons.arrow_upward : Icons.check_circle),
              ]),
            ]),
          ),

          const SizedBox(height: 20),
          _sectionTitle('Phone Numbers'),
          const SizedBox(height: 8),
          ...c.phoneNumbers.map((p) => Card(
            child: ListTile(
              leading: Icon(Icons.phone, color: Colors.blue.shade700),
              title: Text(p),
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied: $p')));
                },
              ),
            ),
          )),

          const SizedBox(height: 20),
          _sectionTitle('Addresses'),
          const SizedBox(height: 8),
          if (c.addresses.isEmpty)
            _emptyCard('No addresses added'),
          ...c.addresses.map((a) => Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.location_on, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(a.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(a.type.toUpperCase(),
                      style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                  ),
                  if (a.isDefault) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text('DEFAULT', style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ]),
                const SizedBox(height: 8),
                Text(a.fullAddress, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ]),
            ),
          )),

          if (c.gstin != null && c.gstin!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionTitle('GSTIN'),
            const SizedBox(height: 8),
            Card(child: ListTile(
              leading: Icon(Icons.receipt, color: Colors.blue.shade700),
              title: Text(c.gstin!),
            )),
          ],

          const SizedBox(height: 20),
          _sectionTitle('Recent Orders'),
          const SizedBox(height: 8),
          if (_orders.isEmpty)
            _emptyCard('No orders yet')
          else
            ...(_orders.take(10).map((o) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(o.status).withValues(alpha: 0.15),
                  child: Icon(_statusIcon(o.status), color: _statusColor(o.status), size: 18),
                ),
                title: Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('₹${o.grandTotal.toStringAsFixed(0)} • ${o.status}'),
                trailing: Text(_formatDate(o.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ),
            ))),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _statChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text('$label: $value', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800));

  Widget _emptyCard(String msg) => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
    child: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400)),
  );

  Color _statusColor(String s) {
    switch (s) {
      case 'delivered': return Colors.green;
      case 'shipped': return Colors.blue;
      case 'confirmed': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'delivered': return Icons.check_circle;
      case 'shipped': return Icons.local_shipping;
      case 'confirmed': return Icons.thumb_up;
      case 'cancelled': return Icons.cancel;
      default: return Icons.hourglass_empty;
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _confirmDelete() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Customer?'),
      content: const Text('This will permanently delete this customer.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            _custSvc.deleteCustomer(widget.customerId);
            Navigator.pop(ctx);
            Navigator.pop(context);
          },
          child: Text('Delete', style: TextStyle(color: Colors.red.shade700)),
        ),
      ],
    ));
  }
}
