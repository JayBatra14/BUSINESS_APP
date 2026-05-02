// lib/services/csv_export_service.dart

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/order_model.dart';
import '../models/customer_model.dart';
import '../services/order_service.dart';
import '../services/customer_service.dart';

class CsvExportService {

  // ── Export Order History as CSV
  static Future<void> exportOrders(BuildContext context) async {
    try {
      final orders = OrderService().getAllOrders();

      final List<List<dynamic>> rows = [
        // Header row
        [
          'Order No.',
          'Date',
          'Customer',
          'Items',
          'Subtotal (₹)',
          'Discount (₹)',
          'Tax (₹)',
          'Grand Total (₹)',
          'Paid (₹)',
          'Balance Due (₹)',
          'Payment Status',
          'Payment Method',
          'Order Status',
          'Notes',
        ],
        // Data rows
        ...orders.map((o) => [
          o.orderNumber,
          '${o.createdAt.day}/${o.createdAt.month}/${o.createdAt.year}',
          o.customerName ?? 'Walk-in',
          o.items.map((i) => '${i.productName} x${i.quantity}').join('; '),
          o.subtotal.toStringAsFixed(2),
          o.totalDiscount.toStringAsFixed(2),
          o.totalTax.toStringAsFixed(2),
          o.grandTotal.toStringAsFixed(2),
          o.amountPaid.toStringAsFixed(2),
          o.balanceDue.toStringAsFixed(2),
          o.paymentStatus.toUpperCase(),
          o.paymentMethod ?? '-',
          o.status.toUpperCase(),
          o.notes ?? '',
        ]),
      ];

      await _shareCSV(context, rows, 'order_history');
    } catch (e) {
      _showError(context, 'Order export failed: $e');
    }
  }

  // ── Export Ledger (Outstanding Balances) as CSV
  static Future<void> exportLedger(BuildContext context) async {
    try {
      final customers = CustomerService().getAllCustomers();
      final withBalance = customers.where((c) => c.balance != 0).toList()
        ..sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));

      final totalReceivable = withBalance
          .where((c) => c.balance > 0)
          .fold(0.0, (s, c) => s + c.balance);
      final totalPayable = withBalance
          .where((c) => c.balance < 0)
          .fold(0.0, (s, c) => s + c.balance.abs());

      final List<List<dynamic>> rows = [
        // Summary header
        ['LEDGER SUMMARY'],
        ['Total Receivable (You Will Get)', '₹${totalReceivable.toStringAsFixed(2)}'],
        ['Total Payable (You Will Give)', '₹${totalPayable.toStringAsFixed(2)}'],
        ['Net Balance', '₹${(totalReceivable - totalPayable).toStringAsFixed(2)}'],
        [],
        // Detail header
        [
          'Customer Name',
          'Phone',
          'Email',
          'GSTIN',
          'Balance (₹)',
          'Status',
        ],
        // Data rows
        ...withBalance.map((c) => [
          c.name,
          c.primaryPhone,
          c.email ?? '-',
          c.gstin ?? '-',
          c.balance.toStringAsFixed(2),
          c.balance > 0 ? 'You will get' : 'You will give',
        ]),
      ];

      await _shareCSV(context, rows, 'ledger');
    } catch (e) {
      _showError(context, 'Ledger export failed: $e');
    }
  }

  // ── Export Detailed Sales Report (item-wise) as CSV
  static Future<void> exportSalesReport(BuildContext context) async {
    try {
      final orders = OrderService().getAllOrders();

      final List<List<dynamic>> rows = [
        // Header row
        [
          'Order No.',
          'Date',
          'Customer',
          'Product',
          'Qty',
          'Unit',
          'Unit Price (₹)',
          'Discount %',
          'Tax %',
          'Item Total (₹)',
          'Payment Status',
        ],
      ];

      for (final o in orders) {
        for (final item in o.items) {
          rows.add([
            o.orderNumber,
            '${o.createdAt.day}/${o.createdAt.month}/${o.createdAt.year}',
            o.customerName ?? 'Walk-in',
            item.productName,
            item.quantity,
            item.unit,
            item.unitPrice.toStringAsFixed(2),
            item.discount.toStringAsFixed(1),
            item.taxPercent.toStringAsFixed(1),
            item.total.toStringAsFixed(2),
            o.paymentStatus.toUpperCase(),
          ]);
        }
      }

      await _shareCSV(context, rows, 'sales_report');
    } catch (e) {
      _showError(context, 'Sales report export failed: $e');
    }
  }

  // ── Shared helper: convert rows to CSV, write file, share
  static Future<void> _shareCSV(
    BuildContext context,
    List<List<dynamic>> rows,
    String filePrefix,
  ) async {
    final csvData = Csv().encode(rows);
    final directory = await getTemporaryDirectory();
    final dateStr = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')[0];
    final file = File('${directory.path}/${filePrefix}_$dateStr.csv');
    await file.writeAsString(csvData);

    final xFile = XFile(file.path);
    await Share.shareXFiles([xFile], text: 'Business App - ${filePrefix.replaceAll('_', ' ').toUpperCase()}');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV file ready to share!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  static void _showError(BuildContext context, String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }
}
