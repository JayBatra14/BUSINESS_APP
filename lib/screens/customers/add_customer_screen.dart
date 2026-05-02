// lib/screens/customers/add_customer_screen.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../l10n/app_strings.dart';
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
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings.tx(context, 'Customer updated!')),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, widget.existingCustomer!.id);
      }
    } else {
      final id = await _customerService.addCustomer(customer);
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings.tx(context, 'Customer added!')),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? AppStrings.tx(context, 'Edit Customer') : AppStrings.tx(context, 'Add Customer')),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _section(AppStrings.tx(context, 'Basic Information')),
            const SizedBox(height: 12),
            _field(_nameCtrl, AppStrings.tx(context, 'Customer Name *'), 'e.g. Rajesh Kumar', Icons.person,
                validator: (v) => v!.isEmpty ? AppStrings.tx(context, 'Required') : null),
            const SizedBox(height: 12),
            _field(_emailCtrl, AppStrings.tx(context, 'Email (optional)'), 'rajesh@gmail.com', Icons.email,
                keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(_gstinCtrl, AppStrings.tx(context, 'GSTIN (optional)'), '07AAAPL1234C1ZV', Icons.receipt),

            const SizedBox(height: 24),
            Row(children: [
              _section(AppStrings.tx(context, 'Phone Numbers')),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _phoneCtrs.add(TextEditingController())),
                icon: const Icon(Icons.add, size: 18),
                label: Text(AppStrings.tx(context, 'Add')),
              ),
            ]),
            const SizedBox(height: 8),
            ...List.generate(_phoneCtrs.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Expanded(child: _field(
                  _phoneCtrs[i],
                  i == 0 ? AppStrings.tx(context, 'Primary Phone *') : '${AppStrings.tx(context, "Phone")} ${i + 1}',
                  '9876543210', Icons.phone,
                  keyboard: TextInputType.phone,
                  validator: i == 0 ? (v) => v!.length != 10 ? AppStrings.tx(context, 'Enter 10 digits') : null : null,
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
              _section(AppStrings.tx(context, 'Addresses')),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _addrForms.add(_AddrForm())),
                icon: const Icon(Icons.add_location, size: 18),
                label: Text(AppStrings.tx(context, 'Add')),
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
                  Text(AppStrings.tx(context, 'No addresses added'), style: TextStyle(color: Colors.grey.shade500)),
                ]),
              ),
            ...List.generate(_addrForms.length, (i) => _addrCard(i)),

            const SizedBox(height: 24),
            _section(AppStrings.tx(context, 'Notes (optional)')),
            const SizedBox(height: 12),
            _field(_notesCtrl, AppStrings.tx(context, 'Notes'), AppStrings.tx(context, 'Additional info...'), Icons.note, maxLines: 3),

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
                    : Text(_isEdit ? AppStrings.tx(context, 'Update Customer') : AppStrings.tx(context, 'Save Customer'),
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
            Text('${AppStrings.tx(context, "Address")} ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: Icon(Icons.delete, color: Colors.red.shade400, size: 20),
              onPressed: () => setState(() { _addrForms[i].dispose(); _addrForms.removeAt(i); })),
          ]),
          const SizedBox(height: 12),
          _field(a.label, AppStrings.tx(context, 'Label'), AppStrings.tx(context, 'Home, Office...'), Icons.label),
          const SizedBox(height: 10),
          _field(a.line1, AppStrings.tx(context, 'Address Line 1 *'), AppStrings.tx(context, 'Street, shop no.'), Icons.location_on,
              validator: (v) => v!.isEmpty ? AppStrings.tx(context, 'Required') : null),
          const SizedBox(height: 10),
          _field(a.line2, AppStrings.tx(context, 'Address Line 2'), AppStrings.tx(context, 'Landmark'), Icons.location_city),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _field(a.city, AppStrings.tx(context, 'City *'), AppStrings.tx(context, 'City'), Icons.location_city,
                validator: (v) => v!.isEmpty ? AppStrings.tx(context, 'Required') : null)),
            const SizedBox(width: 10),
            Expanded(child: _field(a.state, AppStrings.tx(context, 'State *'), AppStrings.tx(context, 'State'), Icons.map,
                validator: (v) => v!.isEmpty ? AppStrings.tx(context, 'Required') : null)),
          ]),
          const SizedBox(height: 10),
          _field(a.pincode, AppStrings.tx(context, 'Pincode *'), '282001', Icons.pin_drop,
              keyboard: TextInputType.number,
              validator: (v) => v!.length != 6 ? AppStrings.tx(context, '6 digits') : null),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: a.type,
            decoration: InputDecoration(
              labelText: AppStrings.tx(context, 'Type'), prefixIcon: Icon(Icons.category, color: Colors.blue.shade700),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true, fillColor: Colors.grey.shade50,
            ),
            items: [
              DropdownMenuItem(value: 'both', child: Text(AppStrings.tx(context, 'Billing & Shipping'))),
              DropdownMenuItem(value: 'billing', child: Text(AppStrings.tx(context, 'Billing Only'))),
              DropdownMenuItem(value: 'shipping', child: Text(AppStrings.tx(context, 'Shipping Only'))),
            ],
            onChanged: (v) => setState(() => a.type = v!),
          ),
          SwitchListTile(
            title: Text(AppStrings.tx(context, 'Default Address'), style: const TextStyle(fontSize: 14)),
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
