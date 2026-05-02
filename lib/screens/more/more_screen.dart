// lib/screens/more/more_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/language_toggle_tile.dart';
import '../../services/local_db_service.dart';
import '../expenses/expense_list_screen.dart';
import '../business_setup_screen.dart';
import '../../services/backup_service.dart';
import '../../services/csv_export_service.dart';
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
              Text(biz?.businessName ?? AppStrings.tx(context, 'My Business'),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(biz?.ownerName ?? '', style: TextStyle(color: Colors.blue.shade100, fontSize: 14)),
              if (biz?.phone != null) ...[
                const SizedBox(height: 4),
                Text(biz!.phone, style: TextStyle(color: Colors.blue.shade100, fontSize: 13)),
              ],
              if (biz?.gstNumber != null && biz!.gstNumber!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${AppStrings.tx(context, "GST")}: ${biz.gstNumber}',
                  style: TextStyle(color: Colors.blue.shade100, fontSize: 13),
                ),
              ],
            ]),
          ),

          const SizedBox(height: 24),
          _sectionTitle(AppStrings.tx(context, 'Business Tools')),
          const SizedBox(height: 12),

          _menuItem(context, AppStrings.tx(context, 'Expenses'), Icons.money_off, Colors.red, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseListScreen()));
          }),
          _menuItem(context, AppStrings.tx(context, 'Ledger'), Icons.book, Colors.purple, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LedgerScreen()));
          }),
          _menuItem(context, AppStrings.tx(context, 'Export Data (Excel/CSV)'), Icons.table_chart, Colors.green, () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (ctx) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  Text(AppStrings.tx(context, 'Export Data'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0x1A2196F3), child: Icon(Icons.receipt_long, color: Colors.blue)),
                    title: Text(AppStrings.tx(context, 'Export Order History')),
                    subtitle: Text(AppStrings.tx(context, 'CSV for CA / accounting'), style: const TextStyle(fontSize: 12)),
                    onTap: () { Navigator.pop(ctx); CsvExportService.exportOrders(context); },
                  ),
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0x1A4CAF50), child: Icon(Icons.table_chart, color: Colors.green)),
                    title: Text(AppStrings.tx(context, 'Export Sales Report')),
                    subtitle: Text(AppStrings.tx(context, 'Item-wise breakdown'), style: const TextStyle(fontSize: 12)),
                    onTap: () { Navigator.pop(ctx); CsvExportService.exportSalesReport(context); },
                  ),
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0x1A9C27B0), child: Icon(Icons.book, color: Colors.purple)),
                    title: Text(AppStrings.tx(context, 'Export Ledger')),
                    subtitle: Text(AppStrings.tx(context, 'Outstanding balances'), style: const TextStyle(fontSize: 12)),
                    onTap: () { Navigator.pop(ctx); CsvExportService.exportLedger(context); },
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
            );
          }),

          const SizedBox(height: 24),
          _sectionTitle(AppStrings.tx(context, 'Settings')),
          const SizedBox(height: 12),

          _menuItem(context, AppStrings.tx(context, 'Edit Business Profile'), Icons.edit, Colors.blue, () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => BusinessSetupScreen(existingBusiness: biz),
            ));
          }),
          _menuItem(context, AppStrings.tx(context, 'Export Backup'), Icons.cloud_upload, Colors.teal, () async {
            await BackupService.exportData(context);
          }),
          _menuItem(context, AppStrings.t(context, 'restore_data'), Icons.cloud_download, Colors.orange, () async {
            await BackupService.importData(context);
          }),
          const LanguageToggleTile(),

          const SizedBox(height: 24),
          _sectionTitle(AppStrings.tx(context, 'About')),
          const SizedBox(height: 12),
          _menuItem(context, AppStrings.t(context, 'app_version'), Icons.info_outline, Colors.grey, () {}),

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
