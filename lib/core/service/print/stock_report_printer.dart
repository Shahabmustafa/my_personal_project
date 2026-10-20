import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


/// Ek printed stock-report ki line.
class StockReportRow {
  final String barcode;
  final String? article, brand, size, color, category, type;
  final int quantity;
  final double salePrice;
  const StockReportRow({
    required this.barcode,
    this.article,
    this.brand,
    this.size,
    this.color,
    this.category,
    this.type,
    required this.quantity,
    required this.salePrice,
  });
}

/// A4 stock report (current filters ke rows) — browser/OS print dialog kholta hai.
class StockReportPrinter {
  StockReportPrinter._();

  static Future<void> print({
    required List<StockReportRow> rows,
    String title = 'Stock Inventory',
    required List<String> filterLabels,
  }) async {
    final bold = pw.Font.helveticaBold();
    final regular = pw.Font.helvetica();
    final totalQty = rows.fold<int>(0, (a, r) => a + r.quantity);
    final totalValue =
        rows.fold<double>(0, (a, r) => a + r.quantity * r.salePrice);
    final now = DateTime.now();
    final stamp = '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-${now.year}';

    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      header: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(font: bold, fontSize: 16)),
              pw.Text(stamp, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            filterLabels.isEmpty
                ? 'Filters: All stock'
                : 'Filters: ${filterLabels.join('  |  ')}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 8),
        ],
      ),
      footer: (c) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${c.pageNumber} / ${c.pagesCount}',
            style: const pw.TextStyle(fontSize: 8)),
      ),
      build: (_) => [
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
              font: bold, fontSize: 8, color: PdfColors.white),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1565C0)),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          oddRowDecoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F7FC)),
          headers: const [
            '#', 'Barcode', 'Article', 'Brand', 'Size', 'Color', 'Category',
            'Type', 'Qty', 'Sale Price'
          ],
          cellAlignments: {
            8: pw.Alignment.centerRight,
            9: pw.Alignment.centerRight,
          },
          data: [
            for (var i = 0; i < rows.length; i++)
              [
                '${i + 1}',
                rows[i].barcode,
                rows[i].article ?? '-',
                rows[i].brand ?? '-',
                rows[i].size ?? '-',
                rows[i].color ?? '-',
                rows[i].category ?? '-',
                rows[i].type ?? '-',
                '${rows[i].quantity}',
                rows[i].salePrice.toStringAsFixed(0),
              ],
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Products: ${rows.length}    Total Pairs: $totalQty    '
            'Total Sale Price: Rs. ${totalValue.round()}',
            style: pw.TextStyle(font: bold, fontSize: 10),
          ),
        ),
      ],
    ));

    await Printing.layoutPdf(
      name: '$title $stamp',
      onLayout: (_) => doc.save(),
    );
  }
}
