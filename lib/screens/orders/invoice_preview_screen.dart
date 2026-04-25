// lib/screens/orders/invoice_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/order_model.dart';
import '../../services/pdf_invoice_service.dart';
import '../../services/local_db_service.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final OrderModel order;
  const InvoicePreviewScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Get active business
    final localDb = LocalDbService();
    final activeId = localDb.getActiveBusinessId();
    final business = localDb.getBusiness(activeId!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        build: (format) => PdfInvoiceService.generateInvoice(order, business!),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}
