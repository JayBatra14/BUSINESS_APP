// lib/screens/orders/create_order_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../models/order_model.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';
import '../../models/address_model.dart';
import '../../services/order_service.dart';
import '../../services/customer_service.dart';
import '../../services/product_service.dart';
import '../../widgets/barcode_scanner_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _orderSvc = OrderService();
  final _custSvc = CustomerService();
  final _prodSvc = ProductService();
  bool _saving = false;

  // Customer selection
  CustomerModel? _selectedCustomer;
  AddressModel? _billingAddr;
  AddressModel? _shippingAddr;

  // Cart items
  final List<_CartItem> _cart = [];

  // Payment
  String _payMethod = 'cash';
  final _paidCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  double get _subtotal => _cart.fold(0, (s, i) => s + i.subtotal);
  double get _totalDiscount => _cart.fold(0, (s, i) => s + i.discountAmt);
  double get _totalTax => _cart.fold(0, (s, i) => s + i.taxAmt);
  double get _grandTotal => _subtotal - _totalDiscount + _totalTax;

  @override
  void dispose() {
    _paidCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _selectCustomer() {
    final customers = _custSvc.getAllCustomers();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String q = '';
        return StatefulBuilder(builder: (ctx, setBS) {
          final filtered = q.isEmpty ? customers : customers.where((c) =>
              c.name.toLowerCase().contains(q.toLowerCase()) ||
              c.phoneNumbers.any((p) => p.contains(q))).toList();
          return DraggableScrollableSheet(
            initialChildSize: 0.7, minChildSize: 0.3, maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollCtrl) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: AppStrings.tx(context, 'Search customer...'), prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true, fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (v) => setBS(() => q = v),
                ),
                const SizedBox(height: 12),
                // Walk-in option
                ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person_outline)),
                  title: Text(AppStrings.tx(context, 'Walk-in Customer')),
                  onTap: () {
                    setState(() { _selectedCustomer = null; _billingAddr = null; _shippingAddr = null; });
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(c.name[0].toUpperCase(), style: TextStyle(color: Colors.blue.shade700)),
                        ),
                        title: Text(c.name),
                        subtitle: Text(c.primaryPhone),
                        onTap: () {
                          setState(() {
                            _selectedCustomer = c;
                            _billingAddr = c.defaultBillingAddress;
                            _shippingAddr = c.defaultShippingAddress;
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ]),
            ),
          );
        });
      },
    );
  }

  void _selectAddress(bool isBilling) {
    if (_selectedCustomer == null || _selectedCustomer!.addresses.isEmpty) return;
    final addrs = _selectedCustomer!.addresses.where((a) =>
        a.type == 'both' || a.type == (isBilling ? 'billing' : 'shipping')).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(isBilling ? AppStrings.tx(context, 'Select Billing Address') : AppStrings.tx(context, 'Select Delivery Address'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...addrs.map((a) => Card(
            child: ListTile(
              leading: Icon(Icons.location_on, color: Colors.blue.shade700),
              title: Text(a.label),
              subtitle: Text(a.fullAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () {
                setState(() { if (isBilling) _billingAddr = a; else _shippingAddr = a; });
                Navigator.pop(ctx);
              },
            ),
          )),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _addProduct() {
    final products = _prodSvc.getAllProducts();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        String q = '';
        return StatefulBuilder(builder: (ctx, setBS) {
          final filtered = q.isEmpty ? products : products.where((p) =>
              p.name.toLowerCase().contains(q.toLowerCase())).toList();
          return DraggableScrollableSheet(
            initialChildSize: 0.7, minChildSize: 0.3, maxChildSize: 0.9, expand: false,
            builder: (_, scrollCtrl) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: AppStrings.tx(context, 'Search product...'), prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true, fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (v) => setBS(() => q = v),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Text(AppStrings.tx(context, 'No products found'), style: TextStyle(color: Colors.grey.shade400)))
                      : ListView.builder(
                          controller: scrollCtrl,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final p = filtered[i];
                            final inCart = _cart.any((c) => c.product.id == p.id);
                            return ListTile(
                              leading: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.inventory_2, color: Colors.blue.shade700, size: 20),
                              ),
                              title: Text(p.name),
                              subtitle: Text('₹${p.sellingPrice.toStringAsFixed(0)} • ${AppStrings.tx(context, "Stock")}: ${p.stockQty == p.stockQty.truncateToDouble() ? p.stockQty.toInt() : p.stockQty}'),
                              trailing: inCart
                                  ? Icon(Icons.check_circle, color: Colors.green.shade700)
                                  : Icon(Icons.add_circle_outline, color: Colors.blue.shade700),
                              onTap: inCart ? null : () {
                                setState(() => _cart.add(_CartItem(product: p)));
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                ),
              ]),
            ),
          );
        });
      },
    );
  }

  Future<void> _saveOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.tx(context, 'Add at least one product')), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _saving = true);

    final paid = double.tryParse(_paidCtrl.text) ?? 0;
    final payStatus = paid >= _grandTotal ? 'paid' : paid > 0 ? 'partial' : 'unpaid';

    final order = OrderModel(
      orderNumber: _orderSvc.getNextOrderNumber(),
      customerId: _selectedCustomer?.id,
      customerName: _selectedCustomer?.name ?? AppStrings.tx(context, 'Walk-in'),
      billingAddress: _billingAddr,
      shippingAddress: _shippingAddr,
      items: _cart.map((c) => OrderItemModel(
        productId: c.product.id!,
        productName: c.product.name,
        quantity: c.qty,
        unit: c.product.unit,
        unitPrice: c.price,
        discount: c.discount,
        taxPercent: c.product.taxPercent,
      )).toList(),
      subtotal: _subtotal,
      totalDiscount: _totalDiscount,
      totalTax: _totalTax,
      grandTotal: _grandTotal,
      amountPaid: paid,
      paymentStatus: payStatus,
      paymentMethod: _payMethod,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    await _orderSvc.createOrder(order);
    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.tx(context, 'Order created!')), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tx(context, 'New Sale / Order')),
        backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Customer selection
          _sec(AppStrings.tx(context, 'Customer')),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectCustomer,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(children: [
                Icon(_selectedCustomer != null ? Icons.person : Icons.person_add, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(child: Text(
                  _selectedCustomer?.name ?? AppStrings.tx(context, 'Select Customer (or Walk-in)'),
                  style: TextStyle(color: _selectedCustomer != null ? Colors.black : Colors.grey.shade500),
                )),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
              ]),
            ),
          ),

          // Billing & Shipping address
          if (_selectedCustomer != null && _selectedCustomer!.addresses.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _addrChip(AppStrings.tx(context, 'Billing'), _billingAddr, () => _selectAddress(true))),
              const SizedBox(width: 8),
              Expanded(child: _addrChip(AppStrings.tx(context, 'Delivery'), _shippingAddr, () => _selectAddress(false))),
            ]),
          ],

          const SizedBox(height: 20),
          Row(children: [
            _sec(AppStrings.tx(context, 'Items')),
            const Spacer(),
            IconButton(
              onPressed: () async {
                final code = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()));
                if (code != null) {
                  final products = _prodSvc.getAllProducts();
                  try {
                    final matched = products.firstWhere((p) => p.barcode == code);
                    setState(() => _cart.add(_CartItem(product: matched)));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${matched.name}'), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.tx(context, 'Product not found for this barcode')), backgroundColor: Colors.red));
                    }
                  }
                }
              },
              icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
            ),
            TextButton.icon(
              onPressed: _addProduct,
              icon: const Icon(Icons.add, size: 18), label: Text(AppStrings.tx(context, 'Add')),
            ),
          ]),
          const SizedBox(height: 8),
          if (_cart.isEmpty)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Icon(Icons.shopping_cart_outlined, color: Colors.grey.shade400, size: 40),
                const SizedBox(height: 8),
                Text(AppStrings.tx(context, 'No items added'), style: TextStyle(color: Colors.grey.shade500)),
              ]),
            ),
          ...List.generate(_cart.length, (i) => _cartItemCard(i)),

          const SizedBox(height: 20),
          // Totals
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(children: [
              _totalRow(AppStrings.tx(context, 'Subtotal'), _subtotal),
              if (_totalDiscount > 0) _totalRow(AppStrings.tx(context, 'Discount'), -_totalDiscount, isRed: true),
              if (_totalTax > 0) _totalRow(AppStrings.tx(context, 'Tax (GST)'), _totalTax),
              const Divider(),
              _totalRow(AppStrings.tx(context, 'Grand Total'), _grandTotal, isBold: true),
            ]),
          ),

          const SizedBox(height: 20),
          _sec(AppStrings.tx(context, 'Payment')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextFormField(
              controller: _paidCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppStrings.tx(context, 'Amount Paid'), hintText: '0',
                prefixIcon: Icon(Icons.currency_rupee, color: Colors.blue.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true, fillColor: Colors.grey.shade50,
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(
              initialValue: _payMethod,
              decoration: InputDecoration(
                labelText: AppStrings.tx(context, 'Method'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true, fillColor: Colors.grey.shade50,
              ),
              items: [
                DropdownMenuItem(value: 'cash', child: Text(AppStrings.tx(context, 'Cash'))),
                DropdownMenuItem(value: 'upi', child: Text('UPI')),
                DropdownMenuItem(value: 'card', child: Text(AppStrings.tx(context, 'Card'))),
                DropdownMenuItem(value: 'bank_transfer', child: Text(AppStrings.tx(context, 'Bank'))),
              ],
              onChanged: (v) => setState(() => _payMethod = v!),
            )),
          ]),

          const SizedBox(height: 12),
          TextFormField(
            controller: _notesCtrl, maxLines: 2,
            decoration: InputDecoration(
              labelText: AppStrings.tx(context, 'Notes (optional)'), hintText: AppStrings.tx(context, 'Order notes...'),
              prefixIcon: Icon(Icons.note, color: Colors.blue.shade700),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true, fillColor: Colors.grey.shade50,
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(AppStrings.tx(context, 'Create Order'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _cartItemCard(int i) {
    final item = _cart[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            Expanded(child: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600))),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red.shade400, size: 20),
              onPressed: () => setState(() => _cart.removeAt(i)),
            ),
          ]),
          Row(children: [
            // Qty
            SizedBox(width: 80, child: TextFormField(
              initialValue: item.qty == item.qty.truncateToDouble() ? item.qty.toInt().toString() : item.qty.toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: AppStrings.tx(context, 'Qty'), isDense: true, border: const OutlineInputBorder()),
              onChanged: (v) => setState(() => item.qty = double.tryParse(v) ?? 1),
            )),
            const SizedBox(width: 8),
            // Price
            SizedBox(width: 100, child: TextFormField(
              initialValue: item.price.toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: AppStrings.tx(context, 'Price'), isDense: true, border: const OutlineInputBorder()),
              onChanged: (v) => setState(() => item.price = double.tryParse(v) ?? item.product.sellingPrice),
            )),
            const SizedBox(width: 8),
            // Discount
            SizedBox(width: 70, child: TextFormField(
              initialValue: '0',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: AppStrings.tx(context, 'Disc%'), isDense: true, border: const OutlineInputBorder()),
              onChanged: (v) => setState(() => item.discount = double.tryParse(v) ?? 0),
            )),
            const Spacer(),
            Text('₹${item.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
        ]),
      ),
    );
  }

  Widget _addrChip(String label, AddressModel? addr, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(addr?.label ?? AppStrings.tx(context, 'Select'), style: TextStyle(fontSize: 13, color: addr != null ? Colors.black : Colors.grey.shade400)),
        ]),
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool isBold = false, bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(label, style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        )),
        const Spacer(),
        Text('₹${amount.abs().toStringAsFixed(2)}', style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: isBold ? 18 : 14,
          color: isRed ? Colors.red.shade700 : Colors.black,
        )),
      ]),
    );
  }

  Widget _sec(String t) => Text(t, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade700));
}

class _CartItem {
  final ProductModel product;
  double qty;
  double price;
  double discount;

  _CartItem({required this.product, this.qty = 1, this.discount = 0})
      : price = product.sellingPrice;

  double get subtotal => qty * price;
  double get discountAmt => subtotal * (discount / 100);
  double get taxableAmt => subtotal - discountAmt;
  double get taxAmt => taxableAmt * (product.taxPercent / 100);
  double get total => taxableAmt + taxAmt;
}
