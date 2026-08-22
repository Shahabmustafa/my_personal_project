import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:safishoe_app/features/warehouse/stock_inventory/data/models/warehouse_stock_model.dart';

/// Handles thermal label PDF generation and printing.
/// Call [BarcodePrintService.printLabel] from anywhere in the app.
class BarcodePrintService {
  BarcodePrintService._(); // non-instantiable

  // ── Label dimensions (58mm × 40mm — standard thermal label) ─────────
  static const double _labelWidthMm = 58;
  static const double _labelHeightMm = 40;

  // ── Shop name printed on every label ────────────────────────────────
  static const String _shopName = 'Safi Shoe';

  /// Opens the system print dialog with a thermal-sized PDF label.
  static Future<void> printLabel(WarehouseStockModel stock) async {
    await Printing.layoutPdf(
      name: 'Barcode_${stock.barcode}',
      format: PdfPageFormat(
        _labelWidthMm * PdfPageFormat.mm,
        _labelHeightMm * PdfPageFormat.mm,
      ),
      onLayout: (format) => _buildPdf(format, stock),
    );
  }

  // ── PDF builder ──────────────────────────────────────────────────────
  static Future<Uint8List> _buildPdf(
      PdfPageFormat format,
      WarehouseStockModel stock,
      ) async {
    final doc = pw.Document();

    // Use built-in fonts — no network call, works on web + mobile + desktop
    final boldFont = pw.Font.helveticaBold();
    final regularFont = pw.Font.helvetica();
    final monoFont = pw.Font.courier();

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        build: (pw.Context ctx) => pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Shop name
            pw.Text(
              _shopName,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 12,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 4),

            // Code128 barcode bars
            pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: stock.barcode,
              width: double.infinity,
              height: 28,
              drawText: false,
              color: PdfColors.black,
            ),
            pw.SizedBox(height: 2),

            // Barcode digits
            pw.Text(
              stock.barcode,
              style: pw.TextStyle(
                font: monoFont,
                fontSize: 7,
                letterSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: 4),

            pw.Divider(color: PdfColors.grey400, thickness: 0.5),
            pw.SizedBox(height: 3),

            // Size & Color
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _detail('Size', stock.sizeName ?? '—', regularFont, boldFont),
                _detail('Color', stock.colorName ?? '—', regularFont, boldFont),
              ],
            ),
            pw.SizedBox(height: 3),

            // Category & Type
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _detail('Category', stock.categoryName ?? '—', regularFont, boldFont),
                _detail('Type', stock.typeName ?? '—', regularFont, boldFont),
              ],
            ),
          ],
        ),
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  // ── Label detail row helper ──────────────────────────────────────────
  static pw.Widget _detail(
      String label,
      String value,
      pw.Font regular,
      pw.Font bold,
      ) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            font: regular,
            fontSize: 7,
            color: PdfColors.grey700,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(font: bold, fontSize: 7),
        ),
      ],
    );
  }
}