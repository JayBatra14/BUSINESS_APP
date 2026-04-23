// lib/screens/customers/add_customer_screen.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/customer_model.dart';
import '../../models/address_model.dart';
import '../../services/customer_service.dart';

class AddCustomerScreen extends StatefulWidget {
  final CustomerModel? existingCustomer;
  const AddCustomerScreen({super.key, this.existingCustomer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerService = CustomerService();
  final _uuid = const Uuid();
  bool _isSaving = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final List<TextEditingController> _phoneCtrs = [TextEditingController()];
  final List<_AddrForm> _addrForms = [];

  bool get _isEdit => widget.existingCustomer != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final c = widget.existingCustomer!;
      _nameCtrl.text = c.name;
      _emailCtrl.text = c.email ?? '';
      _gstinCtrl.text = c.gstin ?? '';
      _notesCtrl.text = c.notes ?? '';
      _phoneCtrs.clear();
      for (final p in c.phoneNumbers) {
        _phoneCtrs.add(TextEditingController(text: p));
      }
      if (_phoneCtrs.isEmpty) _phoneCtrs.add(TextEditingController());
      for (final a in c.addresses) {
        _addrForms.add(_AddrForm.from(a));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _gstinCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _phoneCtrs) c.dispose();
    for (final a in _addrForms) a.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final phones = _phoneCtrs.map((c) => c.text.trim()).where((p) => p.isNotEmpty).toList();
    final addrs = _addrForms.map((a) => a.toModel(_uuid)).toList();

    final customer = CustomerModel(
      name: _nameCtrl.text.trim(),
      phoneNumbers: phones,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      gstin: _gstinCtrl.text.trim().isEmpty ? null : _gstinCtrl.text.trim(),
      addresses: addrs,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      balance: widget.existingCustomer?.balance ?? 0.0,
      createdAt: widget.existingCustomer?.createdAt ?? DateTime.now(),
    );

    if (_isEdit) {
      await _customerService.updateCustomer(widget.existingCustomer!.id!, customer);
    } else {
      await _customerService.addCustomer(customer);
    }

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Customer updated!' : 'Customer added!'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Customer' : 'Add Customer'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _section('Basic Information'),
            const SizedBox(height: 12),
            _field(_nameCtrl, 'Customer Name *', 'e.g. Rajesh Kumar', Icons.person,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            _field(_emailCtrl, 'Email (optional)', 'rajesh@gmail.com', Icons.email,
                keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(_gstinCtrl, 'GSTIN (optional)', '07AAAPL1234C1ZV', Icons.receipt),

            const SizedBox(height: 24),
            Row(children: [
              _section('Phone Numbers'),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _phoneCtrs.add(TextEditingController())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ]),
            const SizedBox(height: 8),
            ...List.generate(_phoneCtrs.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Expanded(child: _field(
                  _phoneCtrs[i],
                  i == 0 ? 'Primary Phone *' : 'Phone ${i + 1}',
                  '9876543210', Icons.phone,
                  keyboard: TextInputType.phone,
                  validator: i == 0 ? (v) => v!.length != 10 ? 'Enter 10 digits' : null : null,
                )),
                if (_phoneCtrs.length > 1)
                  IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red.shade400),
                    onPressed: () => setState(() {
                      _phoneCtrs[i].dispose();
                      _phoneCtrs.removeAt(i);
                    }),
                  ),
              ]),
            )),

            const SizedBox(height: 24),
            Row(children: [
              _section('Addresses'),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _addrForms.add(_AddrForm())),
                icon: const Icon(Icons.add_location, size: 18),
                label: const Text('Add'),
              ),
            ]),
            const SizedBox(height: 8),
            if (_addrForms.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  Icon(Icons.location_off, color: Colors.grey.shade400, size: 32),
                  const SizedBox(height: 8),
                  Text('No addresses added', style: TextStyle(color: Colors.grey.shade500)),
                ]),
              ),
            ...List.generate(_addrForms.length, (i) => _addrCard(i)),

            const SizedBox(height: 24),
            _section('Notes (optional)'),
            const SizedBox(height: 12),
            _field(_notesCtrl, 'Notes', 'Additional info...', Icons.note, maxLines: 3),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(_isEdit ? 'Update Customer' : 'Save Customer',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _addrCard(int i) {
    final a = _addrForms[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.location_on, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 8),
            Text('Address ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: Icon(Icons.delete, color: Colors.red.shade400, size: 20),
              onPressed: () => setState(() { _addrForms[i].dispose(); _addrForms.removeAt(i); })),
          ]),
          const SizedBox(height: 12),
          _field(a.label, 'Label', 'Home, Office...', Icons.label),
          const SizedBox(height: 10),
          _field(a.line1, 'Address Line 1 *', 'Street, shop no.', Icons.location_on,
              validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 10),
          _field(a.line2, 'Address Line 2', 'Landmark', Icons.location_city),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _field(a.city, 'City *', 'City', Icons.location_city,
                validator: (v) => v!.isEmpty ? 'Required' : null)),
            const SizedBox(width: 10),
            Expanded(child: _field(a.state, 'State *', 'State', Icons.map,
                validator: (v) => v!.isEmpty ? 'Required' : null)),
          ]),
          const SizedBox(height: 10),
          _field(a.pincode, 'Pincode *', '282001', Icons.pin_drop,
              keyboard: TextInputType.number,
              validator: (v) => v!.length != 6 ? '6 digits' : null),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: a.type,
            decoration: InputDecoration(
              labelText: 'Type', prefixIcon: Icon(Icons.category, color: Colors.blue.shade700),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true, fillColor: Colors.grey.shade50,
            ),
            items: const [
              DropdownMenuItem(value: 'both', child: Text('Billing & Shipping')),
              DropdownMenuItem(value: 'billing', child: Text('Billing Only')),
              DropdownMenuItem(value: 'shipping', child: Text('Shipping Only')),
            ],
            onChanged: (v) => setState(() => a.type = v!),
          ),
          SwitchListTile(
            title: const Text('Default Address', style: TextStyle(fontSize: 14)),
            value: a.isDefault, onChanged: (v) => setState(() => a.isDefault = v),
            contentPadding: EdgeInsets.zero,
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String lbl, String hint, IconData icon,
      {String? Function(String?)? validator, TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl, keyboardType: keyboard, maxLines: maxLines, validator: validator,
      decoration: InputDecoration(
        labelText: lbl, hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: true, fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _section(String t) => Text(t, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade700));
}

class _AddrForm {
  final label = TextEditingController();
  final line1 = TextEditingController();
  final line2 = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final pincode = TextEditingController();
  String type = 'both';
  bool isDefault = false;

  _AddrForm();
  _AddrForm.from(AddressModel a) {
    label.text = a.label; line1.text = a.addressLine1;
    line2.text = a.addressLine2 ?? ''; city.text = a.city;
    state.text = a.state; pincode.text = a.pincode;
    type = a.type; isDefault = a.isDefault;
  }

  AddressModel toModel(Uuid uuid) => AddressModel(
    id: uuid.v4(), label: label.text.trim().isEmpty ? 'Address' : label.text.trim(),
    addressLine1: line1.text.trim(),
    addressLine2: line2.text.trim().isEmpty ? null : line2.text.trim(),
    city: city.text.trim(), state: state.text.trim(),
    pincode: pincode.text.trim(), type: type, isDefault: isDefault,
  );

  void dispose() { label.dispose(); line1.dispose(); line2.dispose(); city.dispose(); state.dispose(); pincode.dispose(); }
}
