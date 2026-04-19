// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import '../services/local_db_service.dart';
import '../models/business_model.dart';

class DashboardScreen extends StatefulWidget {
  final String businessId;

  const DashboardScreen({super.key, required this.businessId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _localDb = LocalDbService();
  BusinessModel? _business;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  void _loadBusiness() {
    final business = _localDb.getBusiness(widget.businessId);
    setState(() => _business = business);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_business?.businessName ?? 'Dashboard'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${_business?.ownerName ?? ''}!',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _business?.businessName ?? '',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              _business?.city ?? '',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 32),
            const Text(
              'Dashboard coming next!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}