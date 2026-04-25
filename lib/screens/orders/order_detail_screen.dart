// lib/screens/orders/order_detail_screen.dart

import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import 'invoice_preview_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _svc = OrderService();
  OrderModel? _order;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _order = _svc.getOrder(widget.orderId));

  @override
  Widget build(BuildContext context) {
    if (_order == null) {
      return Scaffold(appBar: AppBar(title: const Text('Order')), body: const Center(child: Text('Not found')));
    }
    final o = _order!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(o.orderNumber),
        backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => InvoicePreviewScreen(order: o),
              ));
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') {
                await _svc.deleteOrder(widget.orderId);
                if (mounted) Navigator.pop(context);
              } else {
                await _svc.updateOrderStatus(widget.orderId, v);
                _load();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'confirmed', child: Text('Mark Confirmed')),
              const PopupMenuItem(value: 'shipped', child: Text('Mark Shipped')),
              const PopupMenuItem(value: 'delivered', child: Text('Mark Delivered')),
              const PopupMenuItem(value: 'cancelled', child: Text('Cancel Order')),
              const PopupMenuItem(value: 'delete', child: Text('Delete Order')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Status & payment header
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _statusClr(o.status), borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(_statusIcn(o.status), color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(o.status[0].toUpperCase() + o.status.substring(1),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              Text('${o.createdAt.day}/${o.createdAt.month}/${o.createdAt.year}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
            ]),
          ),

          const SizedBox(height: 20),
          // Customer info
          _sec('Customer'),
          const SizedBox(height: 8),
          Card(child: ListTile(
            leading: Icon(Icons.person, color: Colors.blue.shade700),
            title: Text(o.customerName ?? 'Walk-in'),
          )),

          // Billing address
          if (o.billingAddress != null) ...[
            const SizedBox(height: 12),
            _sec('Billing Address'),
            const SizedBox(height: 8),
            Card(child: ListTile(
              leading: Icon(Icons.location_on, color: Colors.blue.shade700),
              title: Text(o.billingAddress!.label),
              subtitle: Text(o.billingAddress!.fullAddress),
            )),
          ],

          // Shipping address
          if (o.shippingAddress != null) ...[
            const SizedBox(height: 12),
            _sec('Delivery Address'),
            const SizedBox(height: 8),
            Card(child: ListTile(
              leading: Icon(Icons.local_shipping, color: Colors.blue.shade700),
              title: Text(o.shippingAddress!.label),
              subtitle: Text(o.shippingAddress!.fullAddress),
            )),
          ],

          const SizedBox(height: 20),
          _sec('Items (${o.items.length})'),
          const SizedBox(height: 8),
          ...o.items.map((item) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${item.quantity} ${item.unit} × ₹${item.unitPrice.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  if (item.discount > 0)
                    Text('Discount: ${item.discount}%', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                ])),
                Text('₹${item.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
            ),
          )),

          const SizedBox(height: 20),
          // Totals
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(children: [
              _row('Subtotal', o.subtotal),
              if (o.totalDiscount > 0) _row('Discount', -o.totalDiscount, isRed: true),
              if (o.totalTax > 0) _row('Tax (GST)', o.totalTax),
              const Divider(),
              _row('Grand Total', o.grandTotal, isBold: true),
              const Divider(),
              _row('Paid', o.amountPaid, isGreen: true),
              _row('Balance Due', o.balanceDue, isBold: true, isRed: o.balanceDue > 0),
            ]),
          ),

          // Record payment button
          if (o.balanceDue > 0) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _showPaymentDialog(o),
                icon: const Icon(Icons.payment),
                label: const Text('Record Payment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                  side: BorderSide(color: Colors.green.shade700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          if (o.notes != null && o.notes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sec('Notes'),
            const SizedBox(height: 8),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(o.notes!))),
          ],

          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  void _showPaymentDialog(OrderModel o) {
    final ctrl = TextEditingController(text: o.balanceDue.toStringAsFixed(0));
    String method = 'cash';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: ctrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: method,
            decoration: const InputDecoration(labelText: 'Method'),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Cash')),
              DropdownMenuItem(value: 'upi', child: Text('UPI')),
              DropdownMenuItem(value: 'card', child: Text('Card')),
              DropdownMenuItem(value: 'bank_transfer', child: Text('Bank')),
            ],
            onChanged: (v) => setD(() => method = v!),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(ctrl.text) ?? 0;
              if (amt > 0) {
                await _svc.recordPayment(widget.orderId, amt, method);
                Navigator.pop(ctx);
                _load();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ));
  }

  Widget _row(String l, double v, {bool isBold = false, bool isRed = false, bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(l, style: TextStyle(color: Colors.grey.shade700, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        const Spacer(),
        Text('₹${v.abs().toStringAsFixed(2)}', style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: isBold ? 18 : 14,
          color: isRed ? Colors.red.shade700 : isGreen ? Colors.green.shade700 : Colors.black,
        )),
      ]),
    );
  }

  Widget _sec(String t) => Text(t, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800));

  Color _statusClr(String s) {
    switch (s) { case 'delivered': return Colors.green; case 'shipped': return Colors.blue;
      case 'confirmed': return Colors.orange; case 'cancelled': return Colors.red; default: return Colors.grey; }
  }

  IconData _statusIcn(String s) {
    switch (s) { case 'delivered': return Icons.check_circle; case 'shipped': return Icons.local_shipping;
      case 'confirmed': return Icons.thumb_up; case 'cancelled': return Icons.cancel; default: return Icons.hourglass_empty; }
  }
}
