// lib/screens/business_setup_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/business_model.dart';
import '../services/local_db_service.dart';
import 'dashboard_screen.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _localDb = LocalDbService();
  bool _isSaving = false;
  File? _selectedLogoFile;

  // Controllers
  final _businessNameController = TextEditingController();
  final _ownerNameController    = TextEditingController();
  final _phoneController        = TextEditingController();
  final _altPhoneController     = TextEditingController();
  final _emailController        = TextEditingController();
  final _gstController          = TextEditingController();
  final _addressController      = TextEditingController();
  final _cityController         = TextEditingController();
  final _stateController        = TextEditingController();
  final _pincodeController      = TextEditingController();

  String _selectedBusinessType = 'Shop';
  final List<String> _businessTypes = [
    'Shop',
    'Restaurant',
    'Service',
    'Wholesale',
    'Medical',
    'Other',
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  // ── Pick logo from gallery
  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _selectedLogoFile = File(picked.path));
    }
  }

  // ── Save business to Firebase
Future<void> _saveBusinessDetails() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isSaving = true);

  final business = BusinessModel(
    businessName:   _businessNameController.text.trim(),
    ownerName:      _ownerNameController.text.trim(),
    businessType:   _selectedBusinessType,
    phone:          _phoneController.text.trim(),
    alternatePhone: _altPhoneController.text.trim().isEmpty
        ? null : _altPhoneController.text.trim(),
    email:     _emailController.text.trim().isEmpty
        ? null : _emailController.text.trim(),
    gstNumber: _gstController.text.trim().isEmpty
        ? null : _gstController.text.trim(),
    address:   _addressController.text.trim(),
    city:      _cityController.text.trim(),
    state:     _stateController.text.trim(),
    pincode:   _pincodeController.text.trim(),
    createdAt: DateTime.now(),
  );

  // Save locally — no internet needed, no Firebase bills!
  final businessId = await _localDb.saveBusiness(
    business: business,
    logoFile: _selectedLogoFile,
  );

  setState(() => _isSaving = false);

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Business saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(businessId: businessId),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Business'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Logo picker
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.blue.shade700, width: 2),
                      image: _selectedLogoFile != null
                          ? DecorationImage(
                              image: FileImage(_selectedLogoFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedLogoFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  color: Colors.blue.shade700, size: 28),
                              const SizedBox(height: 4),
                              Text('Add Logo',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade700)),
                            ],
                          )
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _sectionHeader('Business Information'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _businessNameController,
                label: 'Business Name *',
                hint: 'e.g. Sharma Electronics',
                icon: Icons.store,
                validator: (val) =>
                    val!.isEmpty ? 'Business name is required' : null,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _ownerNameController,
                label: 'Owner Name *',
                hint: 'e.g. Ramesh Sharma',
                icon: Icons.person,
                validator: (val) =>
                    val!.isEmpty ? 'Owner name is required' : null,
              ),
              const SizedBox(height: 12),

              // Business type dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedBusinessType,
                decoration: InputDecoration(
                  labelText: 'Business Type',
                  prefixIcon:
                      Icon(Icons.category, color: Colors.blue.shade700),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.blue.shade700, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: _businessTypes
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedBusinessType = val!),
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _gstController,
                label: 'GST Number (optional)',
                hint: 'e.g. 07AAAPL1234C1ZV',
                icon: Icons.receipt_long,
              ),

              const SizedBox(height: 24),
              _sectionHeader('Contact Details'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _phoneController,
                label: 'Mobile Number *',
                hint: 'e.g. 9876543210',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (val) => val!.length != 10
                    ? 'Enter valid 10 digit number'
                    : null,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _altPhoneController,
                label: 'Alternate Number (optional)',
                hint: 'e.g. 9876543211',
                icon: Icons.phone_forwarded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _emailController,
                label: 'Email (optional)',
                hint: 'e.g. sharma@gmail.com',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 24),
              _sectionHeader('Business Address'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _addressController,
                label: 'Street Address *',
                hint: 'e.g. Shop No. 5, Main Market',
                icon: Icons.location_on,
                maxLines: 2,
                validator: (val) =>
                    val!.isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _cityController,
                label: 'City *',
                hint: 'e.g. Agra',
                icon: Icons.location_city,
                validator: (val) =>
                    val!.isEmpty ? 'City is required' : null,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _stateController,
                label: 'State *',
                hint: 'e.g. Uttar Pradesh',
                icon: Icons.map,
                validator: (val) =>
                    val!.isEmpty ? 'State is required' : null,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _pincodeController,
                label: 'Pincode *',
                hint: 'e.g. 282001',
                icon: Icons.pin_drop,
                keyboardType: TextInputType.number,
                validator: (val) => val!.length != 6
                    ? 'Enter valid 6 digit pincode'
                    : null,
              ),

              const SizedBox(height: 32),

              // Save button — shows loading spinner while saving
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveBusinessDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Save & Continue',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade700,
      ),
    );
  }
}