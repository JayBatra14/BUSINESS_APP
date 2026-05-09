// lib/screens/products/product_list_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import 'add_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _svc = ProductService();
  final _searchCtrl = TextEditingController();
  List<ProductModel> _all = [];
  List<ProductModel> _filtered = [];
  bool _searching = false;
  String _selectedCat = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _all = _svc.getAllProducts();
      _applyFilter();
    });
  }

  void _applyFilter() {
    var list = _all;
    if (_selectedCat != 'All') {
      list = list.where((p) => p.category == _selectedCat).toList();
    }
    final q = _searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          (p.sku ?? '').toLowerCase().contains(q)).toList();
    }
    _filtered = list;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ['All', ..._svc.getAllCategories()];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl, autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppStrings.tx(context, 'Search products...'), hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() => _applyFilter()),
              )
            : Text(AppStrings.tx(context, 'Products')),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) { _searchCtrl.clear(); _applyFilter(); }
            }),
          ),
        ],
      ),
      body: Column(children: [
        // Category chips
        if (cats.length > 1)
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: cats.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat == 'All' ? AppStrings.tx(context, 'All') : cat),
                  selected: _selectedCat == cat,
                  selectedColor: Colors.blue.shade100,
                  onSelected: (_) => setState(() { _selectedCat = cat; _applyFilter(); }),
                ),
              )).toList(),
            ),
          ),
        // Low stock warning
        if (_svc.getLowStockProducts().isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 18),
              const SizedBox(width: 8),
              Text('${_svc.getLowStockProducts().length} ${AppStrings.tx(context, 'products low on stock')}',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
          ),
        // Product list
        Expanded(
          child: _filtered.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _productCard(_filtered[i]),
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
          _load();
        },
        backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white,
        icon: const Icon(Icons.add_box), label: Text(AppStrings.tx(context, 'Add Product')),
      ),
    );
  }

  Widget _productCard(ProductModel p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.inventory_2, color: Colors.blue.shade700),
        ),
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('₹${p.sellingPrice.toStringAsFixed(0)} • ${p.category}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Row(children: [
            Text('${AppStrings.tx(context, "Stock")}: ${p.stockQty == p.stockQty.truncateToDouble() ? p.stockQty.toInt() : p.stockQty} ${p.unit}',
                style: TextStyle(
                  color: p.isLowStock ? Colors.red.shade700 : Colors.grey.shade500,
                  fontSize: 12, fontWeight: p.isLowStock ? FontWeight.bold : FontWeight.normal,
                )),
            if (p.isLowStock) ...[
              const SizedBox(width: 6),
              Icon(Icons.warning_amber, color: Colors.red.shade700, size: 14),
            ],
          ]),
        ]),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddProductScreen(existingProduct: p),
              ));
              _load();
            } else if (v == 'delete') {
              _svc.deleteProduct(p.id!);
              _load();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppStrings.tx(context, 'Product deleted')), backgroundColor: Colors.red));
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(AppStrings.tx(context, 'Edit'))),
            PopupMenuItem(value: 'delete', child: Text(AppStrings.tx(context, 'Delete'))),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(AppStrings.tx(context, 'No products yet'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
      const SizedBox(height: 8),
      Text(AppStrings.tx(context, 'Tap + to add your first product'), style: TextStyle(color: Colors.grey.shade400)),
    ]),
  );
}
