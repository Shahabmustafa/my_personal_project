import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../model/sale_invoice_model.dart';

/// Builds a thermal-receipt-sized PDF for a saved sale invoice and sends it
/// to the system print dialog (works with thermal/POS printers on
/// Android, iOS, web and desktop). Call [SaleInvoicePrintService.printInvoice]
/// right after a sale invoice is saved.
class SaleInvoicePrintService {
  SaleInvoicePrintService._(); // non-instantiable

  static const String _defaultShopName = 'Safi Shoe';

  /// Opens the system print dialog with an 80mm receipt-width PDF.
  static Future<void> printInvoice(
    SaleInvoiceModel invoice, {
    String? shopName,
  }) async {
    await Printing.layoutPdf(
      name: 'Invoice_${invoice.invoiceNumber}',
      format: PdfPageFormat.roll80,
      onLayout: (format) => _buildPdf(format, invoice, shopName ?? _defaultShopName),
    );
  }

  // ── PDF builder ──────────────────────────────────────────────────────
  static Future<Uint8List> _buildPdf(
    PdfPageFormat format,
    SaleInvoiceModel invoice,
    String shopName,
  ) async {
    final doc = pw.Document();

    final boldFont = pw.Font.helveticaBold();
    final regularFont = pw.Font.helvetica();

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Text(
                shopName,
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
            ),
            pw.SizedBox(height: 6),
            _dashedDivider(),
            pw.SizedBox(height: 4),

            _kv('Invoice #', invoice.invoiceNumber, regularFont, boldFont),
            _kv('Date', _formatDateTime(invoice.createdAt), regularFont, boldFont),
            if (invoice.salesmanName != null && invoice.salesmanName!.isNotEmpty)
              _kv('Salesman', invoice.salesmanName!, regularFont, boldFont),
            _kv('Payment', invoice.paymentTypeLabel.toUpperCase(), regularFont, boldFont),

            pw.SizedBox(height: 4),
            _dashedDivider(),
            pw.SizedBox(height: 4),

            // Item lines
            for (final item in invoice.items) ...[
              pw.Text(
                item.productName ?? '-',
                style: pw.TextStyle(font: boldFont, fontSize: 9),
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    [
                      if ((item.sizeName ?? '').isNotEmpty) 'Size: ${item.sizeName}',
                      if ((item.colorName ?? '').isNotEmpty) item.colorName!,
                    ].join('  '),
                    style: pw.TextStyle(font: regularFont, fontSize: 8, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    '${item.quantity} x ${item.salePrice.toStringAsFixed(0)}',
                    style: pw.TextStyle(font: regularFont, fontSize: 8),
                  ),
                ],
              ),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  item.totalPrice.toStringAsFixed(0),
                  style: pw.TextStyle(font: boldFont, fontSize: 9),
                ),
              ),
              pw.SizedBox(height: 4),
            ],

            _dashedDivider(),
            pw.SizedBox(height: 4),

            _kv('Sub Total', invoice.subtotal.toStringAsFixed(0), regularFont, boldFont),
            if (invoice.totalDiscount > 0)
              _kv('Discount', '-${invoice.totalDiscount.toStringAsFixed(0)}', regularFont, boldFont),

            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text(
                  invoice.totalAmount.toStringAsFixed(0),
                  style: pw.TextStyle(font: boldFont, fontSize: 12),
                ),
              ],
            ),

            pw.SizedBox(height: 8),
            _dashedDivider(),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                'Thank you for shopping with us!',
                style: pw.TextStyle(font: regularFont, fontSize: 8, color: PdfColors.grey700),
              ),
            ),
          ],
        ),
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  static pw.Widget _kv(String label, String value, pw.Font regular, pw.Font bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: regular, fontSize: 8, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 8)),
        ],
      ),
    );
  }

  static pw.Widget _dashedDivider() => pw.Text(
        '--------------------------------',
        style: pw.TextStyle(font: pw.Font.courier(), fontSize: 8, color: PdfColors.grey600),
      );

  static String _formatDateTime(DateTime dt) {
    final d = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final t = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }
}
