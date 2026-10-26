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

/// Same article (article, color, brand, category, type) with all its sizes
/// rolled into one printed line.
class _PrintGroup {
  final List<StockReportRow> items;
  _PrintGroup(this.items);

  StockReportRow get first => items.first;
  int get qty => items.fold(0, (a, r) => a + r.quantity);

  String get barcode =>
      items.length == 1 ? first.barcode : '${items.length} barcodes';

  /// "7 (3), 8 (5), 9 (2)" — size with its pairs, smallest size first.
  String get sizes {
    final sorted = [...items]
      ..sort((a, b) {
        final x = double.tryParse(a.size ?? '');
        final y = double.tryParse(b.size ?? '');
        if (x != null && y != null) return x.compareTo(y);
        return (a.size ?? '').compareTo(b.size ?? '');
      });
    return sorted.map((r) => '${r.size ?? '-'} (${r.quantity})').join(', ');
  }

  String get price {
    final prices = items.map((r) => r.salePrice);
    final lo = prices.reduce((a, b) => a < b ? a : b);
    final hi = prices.reduce((a, b) => a > b ? a : b);
    return lo == hi
        ? lo.toStringAsFixed(0)
        : '${lo.toStringAsFixed(0)} - ${hi.toStringAsFixed(0)}';
  }
}

List<_PrintGroup> _groupRows(List<StockReportRow> rows) {
  final map = <String, List<StockReportRow>>{};
  for (final r in rows) {
    final key = [r.article, r.color, r.brand, r.category, r.type].join('|');
    map.putIfAbsent(key, () => []).add(r);
  }
  return [for (final items in map.values) _PrintGroup(items)];
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
    final groups = _groupRows(rows);
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
            '#', 'Barcode', 'Article', 'Brand', 'Sizes (pairs)', 'Color',
            'Category', 'Type', 'Qty', 'Sale Price'
          ],
          columnWidths: {
            0: const pw.FixedColumnWidth(22),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(3.2),
          },
          cellAlignments: {
            8: pw.Alignment.centerRight,
            9: pw.Alignment.centerRight,
          },
          data: [
            for (var i = 0; i < groups.length; i++)
              [
                '${i + 1}',
                groups[i].barcode,
                groups[i].first.article ?? '-',
                groups[i].first.brand ?? '-',
                groups[i].sizes,
                groups[i].first.color ?? '-',
                groups[i].first.category ?? '-',
                groups[i].first.type ?? '-',
                '${groups[i].qty}',
                groups[i].price,
              ],
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Articles: ${groups.length}    Products: ${rows.length}    Total Pairs: $totalQty    '
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
