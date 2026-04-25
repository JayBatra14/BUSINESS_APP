// lib/screens/products/add_product_screen.dart

import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../widgets/barcode_scanner_screen.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? existingProduct;
  const AddProductScreen({super.key, this.existingProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _svc = ProductService();
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _hsnCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _lowStockCtrl = TextEditingController(text: '5');

  String _category = 'General';
  String _unit = 'pcs';

  final _categories = ['General', 'Electronics', 'Clothing', 'Food', 'Medicine', 'Grocery', 'Hardware', 'Stationery', 'Other'];
  final _units = ['pcs', 'kg', 'gm', 'litre', 'ml', 'box', 'pack', 'dozen', 'meter', 'sq.ft'];

  bool get _isEdit => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.existingProduct!;
      _nameCtrl.text = p.name;
      _skuCtrl.text = p.sku ?? '';
      _priceCtrl.text = p.sellingPrice.toString();
      _costCtrl.text = (p.costPrice ?? 0).toString();
      _stockCtrl.text = p.stockQty.toString();
      _taxCtrl.text = p.taxPercent.toString();
      _hsnCtrl.text = p.hsnCode ?? '';
      _barcodeCtrl.text = p.barcode ?? '';
      _descCtrl.text = p.description ?? '';
      _lowStockCtrl.text = p.lowStockAlert.toString();
      _category = p.category;
      _unit = p.unit;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _skuCtrl.dispose(); _priceCtrl.dispose();
    _costCtrl.dispose(); _stockCtrl.dispose(); _taxCtrl.dispose();
    _hsnCtrl.dispose(); _barcodeCtrl.dispose(); _descCtrl.dispose();
    _lowStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final product = ProductModel(
      name: _nameCtrl.text.trim(),
      sku: _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
      category: _category,
      sellingPrice: double.tryParse(_priceCtrl.text) ?? 0,
      costPrice: double.tryParse(_costCtrl.text) ?? 0,
      stockQty: double.tryParse(_stockCtrl.text) ?? 0,
      unit: _unit,
      taxPercent: double.tryParse(_taxCtrl.text) ?? 0,
      hsnCode: _hsnCtrl.text.trim().isEmpty ? null : _hsnCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      lowStockAlert: double.tryParse(_lowStockCtrl.text) ?? 5,
      createdAt: widget.existingProduct?.createdAt ?? DateTime.now(),
    );

    if (_isEdit) {
      await _svc.updateProduct(widget.existingProduct!.id!, product);
    } else {
      await _svc.addProduct(product);
    }

    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Product updated!' : 'Product added!'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add Product'),
        backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sec('Product Details'),
            const SizedBox(height: 12),
            _f(_nameCtrl, 'Product Name *', 'e.g. Samsung Galaxy M34', Icons.inventory_2,
                v: (s) => s!.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            _f(_skuCtrl, 'SKU / Item Code', 'e.g. SKU-001', Icons.qr_code),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _dd('Category', Icons.category),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v!),
              )),
              const SizedBox(width: 12),
              Expanded(child: DropdownButtonFormField<String>(
                initialValue: _unit,
                decoration: _dd('Unit', Icons.straighten),
                items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setState(() => _unit = v!),
              )),
            ]),
            const SizedBox(height: 12),
            _f(_descCtrl, 'Description (optional)', 'Product details...', Icons.description, lines: 2),

            const SizedBox(height: 24),
            _sec('Pricing'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _f(_priceCtrl, 'Selling Price *', '₹', Icons.currency_rupee,
                  kb: TextInputType.number, v: (s) => s!.isEmpty ? 'Required' : null)),
              const SizedBox(width: 12),
              Expanded(child: _f(_costCtrl, 'Cost Price', '₹', Icons.money,
                  kb: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _f(_taxCtrl, 'Tax / GST %', '0', Icons.percent,
                  kb: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _f(_hsnCtrl, 'HSN Code', 'Optional', Icons.tag)),
            ]),

            const SizedBox(height: 24),
            _sec('Stock'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _f(_stockCtrl, 'Current Stock *', '0', Icons.warehouse,
                  kb: TextInputType.number, v: (s) => s!.isEmpty ? 'Required' : null)),
              const SizedBox(width: 12),
              Expanded(child: _f(_lowStockCtrl, 'Low Stock Alert', '5', Icons.warning_amber,
                  kb: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            _f(_barcodeCtrl, 'Barcode (optional)', 'Scan or type', Icons.barcode_reader, 
              suffix: IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                onPressed: () async {
                  final code = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()));
                  if (code != null) setState(() => _barcodeCtrl.text = code);
                },
              )),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(_isEdit ? 'Update Product' : 'Save Product',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _f(TextEditingController c, String l, String h, IconData ic,
      {String? Function(String?)? v, TextInputType kb = TextInputType.text, int lines = 1, Widget? suffix}) {
    return TextFormField(
      controller: c, keyboardType: kb, maxLines: lines, validator: v,
      decoration: InputDecoration(
        labelText: l, hintText: h,
        prefixIcon: Icon(ic, color: Colors.blue.shade700),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2)),
        filled: true, fillColor: Colors.grey.shade50,
      ),
    );
  }

  InputDecoration _dd(String l, IconData ic) => InputDecoration(
    labelText: l, prefixIcon: Icon(ic, color: Colors.blue.shade700),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    filled: true, fillColor: Colors.grey.shade50,
  );

  Widget _sec(String t) => Text(t, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade700));
}
