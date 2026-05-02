// lib/screens/more/ledger_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../services/customer_service.dart';
import '../../services/csv_export_service.dart';
import '../../models/customer_model.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  final _custSvc = CustomerService();

  @override
  Widget build(BuildContext context) {
    final allCustomers = _custSvc.getAllCustomers();
    final withBalance = allCustomers.where((c) => c.balance != 0).toList()
      ..sort((a, b) => b.balance.abs().compareTo(a.balance.abs())); // Sort by largest balance
    
    final totalReceivable = withBalance.where((c) => c.balance > 0).fold(0.0, (s, c) => s + c.balance);
    final totalPayable = withBalance.where((c) => c.balance < 0).fold(0.0, (s, c) => s + c.balance.abs());

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(AppStrings.tx(context, 'Ledger')),
        backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: AppStrings.tx(context, 'Export Ledger'),
            onPressed: () async {
              await CsvExportService.exportLedger(context);
            },
          ),
        ],
      ),
      body: Column(children: [
        // Summary cards
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: _summaryCard(AppStrings.tx(context, 'You Will Get'), totalReceivable, Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: _summaryCard(AppStrings.tx(context, 'You Will Give'), totalPayable, Colors.red)),
          ]),
        ),
        
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(AppStrings.tx(context, 'Outstanding Balances'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
        ),
        
        Expanded(
          child: _buildList(withBalance),
        ),
      ]),
    );
  }

  Widget _summaryCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('₹${amount.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _buildList(List<CustomerModel> customers) {
    if (customers.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check_circle_outline, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(AppStrings.tx(context, 'All accounts are clear!'), style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: customers.length,
      itemBuilder: (_, i) {
        final c = customers[i];
        final isReceivable = c.balance > 0;
        final color = isReceivable ? Colors.green : Colors.red;
        final labelText = isReceivable ? AppStrings.tx(context, 'You will get') : AppStrings.tx(context, 'You will give');
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 24,
              child: Text(c.name[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            subtitle: Text(c.primaryPhone, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${c.balance.abs().toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                Text(labelText, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      },
    );
  }
}
