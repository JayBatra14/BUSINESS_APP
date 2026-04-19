import 'package:flutter/material.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameController = TextEditingController();
  final _ownerNameController    = TextEditingController();
  final _phoneController        = TextEditingController();
  final _emailController        = TextEditingController();
  final _gstController          = TextEditingController();
  final _addressController      = TextEditingController();
  final _cityController         = TextEditingController();
  final _pincodeController      = TextEditingController();

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _saveBusinessDetails() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business details saved successfully!'),
          backgroundColor: Colors.green,
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

              _sectionHeader('Business Information'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _businessNameController,
                label: 'Business Name',
                hint: 'e.g. Sharma Electronics',
                icon: Icons.store,
                validator: (val) =>
                    val!.isEmpty ? 'Please enter business name' : null,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _ownerNameController,
                label: 'Owner Name',
                hint: 'e.g. Ramesh Sharma',
                icon: Icons.person,
                validator: (val) =>
                    val!.isEmpty ? 'Please enter owner name' : null,
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
                label: 'Mobile Number',
                hint: 'e.g. 9876543210',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (val) =>
                    val!.length != 10 ? 'Enter valid 10 digit number' : null,
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
                label: 'Street Address',
                hint: 'e.g. Shop No. 5, Main Market',
                icon: Icons.location_on,
                maxLines: 2,
                validator: (val) =>
                    val!.isEmpty ? 'Please enter address' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: 'e.g. Agra',
                      icon: Icons.location_city,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _pincodeController,
                      label: 'Pincode',
                      hint: 'e.g. 282001',
                      icon: Icons.pin_drop,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveBusinessDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Business Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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