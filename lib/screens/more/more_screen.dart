// lib/screens/more/more_screen.dart

import 'package:flutter/material.dart';
import '../../services/local_db_service.dart';
import '../expenses/expense_list_screen.dart';
import '../business_setup_screen.dart';
import '../../services/backup_service.dart';
import 'ledger_screen.dart';

class MoreScreen extends StatelessWidget {
  final String businessId;
  const MoreScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    final biz = LocalDbService().getBusiness(businessId);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Business card
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade500]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(biz?.businessName ?? 'My Business',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(biz?.ownerName ?? '', style: TextStyle(color: Colors.blue.shade100, fontSize: 14)),
              if (biz?.phone != null) ...[
                const SizedBox(height: 4),
                Text(biz!.phone, style: TextStyle(color: Colors.blue.shade100, fontSize: 13)),
              ],
              if (biz?.gstNumber != null && biz!.gstNumber!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('GST: ${biz.gstNumber}', style: TextStyle(color: Colors.blue.shade100, fontSize: 13)),
              ],
            ]),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Business Tools'),
          const SizedBox(height: 12),

          _menuItem(context, 'Expenses', Icons.money_off, Colors.red, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseListScreen()));
          }),
          _menuItem(context, 'Ledger', Icons.book, Colors.purple, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LedgerScreen()));
          }),

          const SizedBox(height: 24),
          _sectionTitle('Settings'),
          const SizedBox(height: 12),

          _menuItem(context, 'Edit Business Profile', Icons.edit, Colors.blue, () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => BusinessSetupScreen(existingBusiness: biz),
            ));
          }),
          _menuItem(context, 'Export Backup', Icons.cloud_upload, Colors.teal, () async {
            await BackupService.exportData(context);
          }),
          _menuItem(context, 'Restore Data', Icons.cloud_download, Colors.orange, () async {
            await BackupService.importData(context);
          }),

          const SizedBox(height: 24),
          _sectionTitle('About'),
          const SizedBox(height: 12),
          _menuItem(context, 'App Version 1.0.0', Icons.info_outline, Colors.grey, () {}),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _menuItem(BuildContext ctx, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800));
}
