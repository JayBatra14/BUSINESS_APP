// lib/services/pdf_invoice_service.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import '../models/business_model.dart';

class PdfInvoiceService {
  static Future<Uint8List> generateInvoice(OrderModel order, BusinessModel business) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    final primaryColor = PdfColor.fromHex('#263238'); // Dark sleek color
    final accentColor = PdfColor.fromHex('#4FC3F7'); // Light blue accent

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        ),
        header: (context) => _buildHeader(business, order, primaryColor, fontBold),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildAddresses(business, order),
          pw.SizedBox(height: 30),
          _buildTable(order, primaryColor),
          pw.SizedBox(height: 20),
          _buildTotals(order, primaryColor, business),
          pw.SizedBox(height: 40),
          _buildFooter(order),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(BusinessModel business, OrderModel order, PdfColor primaryColor, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(business.businessName, style: pw.TextStyle(color: primaryColor, fontWeight: pw.FontWeight.bold, fontSize: 24)),
                pw.SizedBox(height: 4),
                if (business.phone.isNotEmpty) pw.Text('Phone: ${business.phone}', style: const pw.TextStyle(fontSize: 10)),
                if (business.email != null && business.email!.isNotEmpty) pw.Text('Email: ${business.email}', style: const pw.TextStyle(fontSize: 10)),
                if (business.gstNumber != null && business.gstNumber!.isNotEmpty) pw.Text('GSTIN: ${business.gstNumber}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('INVOICE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                pw.SizedBox(height: 4),
                pw.Text('# ${order.orderNumber}', style: const pw.TextStyle(fontSize: 12)),
                pw.Text('Date: ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey300),
      ],
    );
  }

  static pw.Widget _buildAddresses(BusinessModel business, OrderModel order) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Billed To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text(order.customerName ?? 'Walk-in Customer', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              if (order.billingAddress != null) ...[
                pw.Text(order.billingAddress!.fullAddress, style: const pw.TextStyle(fontSize: 10)),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        if (order.shippingAddress != null)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Shipped To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 4),
                pw.Text(order.customerName ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.Text(order.shippingAddress!.fullAddress, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          )
        else
          pw.Expanded(child: pw.SizedBox()), // Empty space if no shipping
      ],
    );
  }

  static pw.Widget _buildTable(OrderModel order, PdfColor primaryColor) {
    final headers = ['Item', 'Qty', 'Unit Price', 'Disc%', 'Tax%', 'Total'];

    final data = order.items.map((item) {
      return [
        item.productName,
        '${item.quantity}',
        '${item.unitPrice.toStringAsFixed(2)}',
        '${item.discount.toStringAsFixed(1)}%',
        '${item.taxPercent.toStringAsFixed(1)}%',
        '${item.total.toStringAsFixed(2)}',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: primaryColor),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
      rowDecoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
      ),
    );
  }

  static pw.Widget _buildTotals(OrderModel order, PdfColor primaryColor, BusinessModel business) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Amount in Words:', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
                pw.Text(_numberToWords(order.grandTotal.toInt()), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                if (business.upiId != null && business.upiId!.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Text('Scan to Pay via UPI', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.BarcodeWidget(
                    data: 'upi://pay?pa=${business.upiId}&pn=${Uri.encodeComponent(business.businessName)}&am=${order.grandTotal.toStringAsFixed(2)}&cu=INR',
                    barcode: pw.Barcode.qrCode(),
                    width: 80,
                    height: 80,
                  ),
                ],
              ],
            ),
          ),
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildTotalRow('Subtotal', order.subtotal),
                if (order.totalDiscount > 0) _buildTotalRow('Discount', -order.totalDiscount),
                if (order.totalTax > 0) _buildTotalRow('Tax', order.totalTax),
                pw.Divider(color: PdfColors.grey400),
                _buildTotalRow('Grand Total', order.grandTotal, isBold: true, color: primaryColor),
                pw.SizedBox(height: 4),
                _buildTotalRow('Paid', order.amountPaid),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  color: order.balanceDue > 0 ? PdfColors.red100 : PdfColors.green100,
                  child: _buildTotalRow('Balance Due', order.balanceDue, isBold: true, color: order.balanceDue > 0 ? PdfColors.red800 : PdfColors.green800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, double value, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? PdfColors.black)),
          pw.Text(value.toStringAsFixed(2), style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? PdfColors.black)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(OrderModel order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (order.notes != null && order.notes!.isNotEmpty) ...[
          pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(order.notes!, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 20),
        ],
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text('Thank you for your business!', style: pw.TextStyle(color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
        ),
      ],
    );
  }

  static String _numberToWords(int number) {
    if (number == 0) return 'Zero Rupees Only';
    final units = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    final tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
    
    String convertUnderHundred(int n) {
      if (n < 20) return units[n];
      return '${tens[n ~/ 10]} ${units[n % 10]}'.trim();
    }
    
    String convert(int n) {
      if (n < 100) return convertUnderHundred(n);
      if (n < 1000) return '${units[n ~/ 100]} Hundred ${convertUnderHundred(n % 100)}'.trim();
      if (n < 100000) return '${convertUnderHundred(n ~/ 1000)} Thousand ${convert(n % 1000)}'.trim();
      if (n < 10000000) return '${convertUnderHundred(n ~/ 100000)} Lakh ${convert(n % 100000)}'.trim();
      return '${convertUnderHundred(n ~/ 10000000)} Crore ${convert(n % 10000000)}'.trim();
    }
    return '${convert(number)} Rupees Only';
  }
}
