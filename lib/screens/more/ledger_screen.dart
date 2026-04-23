// lib/screens/more/ledger_screen.dart

import 'package:flutter/material.dart';
import '../../services/customer_service.dart';
import '../../models/customer_model.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> with SingleTickerProviderStateMixin {
  final _custSvc = CustomerService();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allCustomers = _custSvc.getAllCustomers();
    final withBalance = allCustomers.where((c) => c.balance != 0).toList();
    final youWillGet = withBalance.where((c) => c.balance > 0).toList();
    final youWillGive = withBalance.where((c) => c.balance < 0).toList();
    final totalReceivable = youWillGet.fold(0.0, (s, c) => s + c.balance);
    final totalPayable = youWillGive.fold(0.0, (s, c) => s + c.balance.abs());

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Ledger'),
        backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'You Will Get'),
            Tab(text: 'You Will Give'),
          ],
        ),
      ),
      body: Column(children: [
        // Summary cards
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: _summaryCard('You Will Get', totalReceivable, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _summaryCard('You Will Give', totalPayable, Colors.red)),
          ]),
        ),
        Expanded(
          child: TabBarView(controller: _tabCtrl, children: [
            _buildList(youWillGet, Colors.green),
            _buildList(youWillGive, Colors.red),
          ]),
        ),
      ]),
    );
  }

  Widget _summaryCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('₹${amount.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _buildList(List<CustomerModel> customers, Color color) {
    if (customers.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check_circle_outline, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('All clear!', style: TextStyle(fontSize: 16, color: Colors.grey.shade400)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: customers.length,
      itemBuilder: (_, i) {
        final c = customers[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Text(c.name[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(c.primaryPhone, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            trailing: Text('₹${c.balance.abs().toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          ),
        );
      },
    );
  }
}
