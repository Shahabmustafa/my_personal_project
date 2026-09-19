import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../features/branch/sale_exchange/data/model/sale_exchange_model.dart';
import '../../../features/branch/sale_invoice/data/model/sale_invoice_model.dart';
import '../../../features/branch/sale_return/data/model/sale_return_model.dart';

/// Builds and prints thermal-receipt-sized PDFs for sale invoices and sale
/// returns, styled for a footwear shop (size/color per line, exchange
/// policy footer).
///
/// On web there's no way to talk to a printer directly, so it always opens
/// the browser's print dialog. On desktop it tries to match [PrinterLookupItem.label]
/// against an installed OS printer and prints straight to it with no dialog;
/// if no match is found it falls back to the picker dialog.
class ThermalPrintService {
  ThermalPrintService._();

  static const String _defaultShopName = 'Safi Shoe';

  static final _boldFont = pw.Font.helveticaBold();
  static final _regularFont = pw.Font.helvetica();

  // ═══════════════════════════════════════════════════════════════════════
  // SALE INVOICE
  // ═══════════════════════════════════════════════════════════════════════

  static Future<void> printSaleInvoice(
    SaleInvoiceModel invoice, {
    PrinterLookupItem? printer,
    String? shopName,
  }) async {
    final doc = await _buildDoc(
      shopName: shopName ?? _defaultShopName,
      printer: printer,
      title: 'SALE INVOICE',
      documentNumberLabel: 'Invoice #',
      documentNumber: invoice.invoiceNumber,
      date: invoice.createdAt,
      customerName: invoice.customerName,
      salesmanName: invoice.salesmanName,
      lines: invoice.items
          .map((i) => _ReceiptLine(
                name: i.productName ?? '-',
                sizeName: i.sizeName,
                colorName: i.colorName,
                quantity: i.quantity,
                unitPrice: i.salePrice,
                discount: i.discount,
                total: i.totalPrice,
              ))
          .toList(),
      subtotal: invoice.subtotal,
      totalDiscount: invoice.totalDiscount,
      extraDiscount: invoice.invoiceDiscount,
      extraDiscountLabel: 'Invoice Discount',
      grandTotalLabel: 'TOTAL',
      grandTotal: invoice.totalAmount,
      payments: invoice.payments.map((p) => _ReceiptPayment(p.paymentType, p.amount)).toList(),
      paymentsHeading: 'PAID VIA',
      footerNotes: _footwearNotes,
    );

    await _dispatch(doc, jobName: 'Invoice_${invoice.invoiceNumber}', printer: printer);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SALE RETURN
  // ═══════════════════════════════════════════════════════════════════════

  static Future<void> printSaleReturn(
    SaleReturnModel saleReturn, {
    PrinterLookupItem? printer,
    String? shopName,
  }) async {
    final doc = await _buildDoc(
      shopName: shopName ?? _defaultShopName,
      printer: printer,
      title: 'SALE RETURN',
      documentNumberLabel: 'Return #',
      documentNumber: saleReturn.returnNumber,
      date: saleReturn.createdAt,
      customerName: saleReturn.customerName,
      salesmanName: saleReturn.salesmanName,
      lines: saleReturn.items
          .map((i) => _ReceiptLine(
                name: i.productName ?? '-',
                sizeName: i.sizeName,
                colorName: i.colorName,
                quantity: i.quantity,
                unitPrice: i.salePrice,
                discount: i.discount,
                total: i.totalPrice,
              ))
          .toList(),
      subtotal: saleReturn.subtotal,
      totalDiscount: saleReturn.totalDiscount,
      extraDiscount: 0,
      extraDiscountLabel: '',
      grandTotalLabel: 'REFUND AMOUNT',
      grandTotal: saleReturn.totalAmount,
      payments: saleReturn.payments.map((p) => _ReceiptPayment(p.paymentType, p.amount)).toList(),
      paymentsHeading: 'REFUNDED VIA',
      footerNotes: const ['Returned pairs are subject to inspection before refund.'],
    );

    await _dispatch(doc, jobName: 'Return_${saleReturn.returnNumber}', printer: printer);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STOCK SLIP (Head Office -> Branch assignment / Branch -> Branch transfer)
  // ═══════════════════════════════════════════════════════════════════════

  /// Delivery slip for stock moving between locations. Quantities only —
  /// purchase/sale prices are internal and deliberately left off.
  static Future<void> printStockSlip({
    required String title,
    required String documentNumberLabel,
    required String documentNumber,
    required DateTime date,
    String? fromName,
    required String toName,
    required List<StockSlipLine> lines,
    PrinterLookupItem? printer,
    String? shopName,
    String footerNote =
        'Stock stays pending until the receiving branch accepts it.',
  }) async {
    final doc = pw.Document();
    final logo = await _fetchLogo(printer?.imageUrl);
    final totalPairs = lines.fold<int>(0, (s, l) => s + l.quantity);

    pw.Widget th(String t, int flex, {pw.TextAlign align = pw.TextAlign.left}) =>
        pw.Expanded(
            flex: flex,
            child: pw.Text(t,
                style: pw.TextStyle(font: _boldFont, fontSize: 8), textAlign: align));
    pw.Widget td(String t, int flex, {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) =>
        pw.Expanded(
            flex: flex,
            child: pw.Text(t,
                style: pw.TextStyle(font: bold ? _boldFont : _regularFont, fontSize: 8),
                textAlign: align));

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (logo != null)
              pw.Center(
                child: pw.Container(
                  width: 55,
                  height: 55,
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
              ),
            pw.Center(
              child: pw.Text(
                (shopName ?? _defaultShopName).toUpperCase(),
                style: pw.TextStyle(font: _boldFont, fontSize: 14, letterSpacing: 1.5),
              ),
            ),
            if (printer != null && printer.address.isNotEmpty)
              pw.Center(
                child: pw.Text(printer.address,
                    style: pw.TextStyle(font: _regularFont, fontSize: 8.5, color: PdfColors.grey700)),
              ),
            if (printer != null && printer.phoneNumber.isNotEmpty)
              pw.Center(
                child: pw.Text(printer.phoneNumber,
                    style: pw.TextStyle(font: _regularFont, fontSize: 8.5, color: PdfColors.grey700)),
              ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(title,
                  style: pw.TextStyle(font: _boldFont, fontSize: 10.5, letterSpacing: 1.5)),
            ),
            pw.SizedBox(height: 4),
            _dashedDivider(),
            pw.SizedBox(height: 4),

            _kv(documentNumberLabel, documentNumber),
            _kv('Date', _formatDateTime(date)),
            if (fromName != null && fromName.isNotEmpty) _kv('From', fromName),
            _kv('To', toName),

            pw.SizedBox(height: 4),
            _dashedDivider(),
            pw.SizedBox(height: 4),

            pw.Row(children: [
              th('ITEM', 4),
              th('COLOR', 2, align: pw.TextAlign.center),
              th('SIZE', 2, align: pw.TextAlign.center),
              th('QTY', 1, align: pw.TextAlign.right),
            ]),
            _dashedDivider(),
            pw.SizedBox(height: 2),
            for (final l in lines)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    td(l.name, 4),
                    td(l.colorName ?? '-', 2, align: pw.TextAlign.center),
                    td(l.sizeName ?? '-', 2, align: pw.TextAlign.center),
                    td('${l.quantity}', 1, align: pw.TextAlign.right, bold: true),
                  ],
                ),
              ),

            _dashedDivider(),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL PAIRS', style: pw.TextStyle(font: _boldFont, fontSize: 12)),
                pw.Text('$totalPairs', style: pw.TextStyle(font: _boldFont, fontSize: 12)),
              ],
            ),

            pw.SizedBox(height: 14),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Sent by: ________',
                    style: pw.TextStyle(font: _regularFont, fontSize: 7.5, color: PdfColors.grey700)),
                pw.Text('Received by: ________',
                    style: pw.TextStyle(font: _regularFont, fontSize: 7.5, color: PdfColors.grey700)),
              ],
            ),
            pw.SizedBox(height: 8),
            _dashedDivider(),
            pw.SizedBox(height: 6),
            pw.Text(footerNote,
                style: pw.TextStyle(font: _regularFont, fontSize: 6.5, color: PdfColors.grey700)),
          ],
        ),
      ),
    );

    await _dispatch(doc, jobName: 'Stock_$documentNumber', printer: printer);
  }

  static const _footwearNotes = [
    '1) No warranty without original invoice.',
    '2) No exchange on worn or used footwear.',
    '3) Exchange within 7 days with tag intact.',
  ];

  // ═══════════════════════════════════════════════════════════════════════
  // SALE EXCHANGE (returned items + new items on one receipt)
  // ═══════════════════════════════════════════════════════════════════════

  static Future<void> printSaleExchange(
    SaleExchangeModel exchange, {
    PrinterLookupItem? printer,
    String? shopName,
  }) async {
    final doc = await _buildExchangeDoc(
      shopName: shopName ?? _defaultShopName,
      printer: printer,
      exchange: exchange,
    );
    await _dispatch(doc, jobName: 'Exchange_${exchange.exchangeNumber}', printer: printer);
  }

  static Future<pw.Document> _buildExchangeDoc({
    required String shopName,
    required PrinterLookupItem? printer,
    required SaleExchangeModel exchange,
  }) async {
    final doc = pw.Document();
    final hasCustomer = (exchange.customerName ?? '').isNotEmpty;
    final hasSalesman = (exchange.salesmanName ?? '').isNotEmpty;
    final logo = await _fetchLogo(printer?.imageUrl);

    final returnLines = exchange.returnItems
        .map((i) => _ReceiptLine(
              name: i.productName ?? '-',
              sizeName: i.sizeName,
              colorName: i.colorName,
              quantity: i.quantity,
              unitPrice: i.salePrice,
              discount: i.discount,
              total: i.totalPrice,
            ))
        .toList();
    final newLines = exchange.newItems
        .map((i) => _ReceiptLine(
              name: i.productName ?? '-',
              sizeName: i.sizeName,
              colorName: i.colorName,
              quantity: i.quantity,
              unitPrice: i.salePrice,
              discount: i.discount,
              total: i.totalPrice,
            ))
        .toList();

    final diffLabel = exchange.differenceAmount > 0
        ? 'COLLECT FROM CUSTOMER'
        : exchange.differenceAmount < 0
            ? 'REFUND TO CUSTOMER'
            : 'EVEN EXCHANGE';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (logo != null)
              pw.Center(
                child: pw.Container(
                  width: 55,
                  height: 55,
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
              ),
            pw.Center(
              child: pw.Text(
                shopName.toUpperCase(),
                style: pw.TextStyle(font: _boldFont, fontSize: 14, letterSpacing: 1.5),
              ),
            ),
            if (printer != null && printer.address.isNotEmpty)
              pw.Center(
                child: pw.Text(printer.address,
                    style: pw.TextStyle(font: _regularFont, fontSize: 8.5, color: PdfColors.grey700)),
              ),
            if (printer != null && printer.phoneNumber.isNotEmpty)
              pw.Center(
                child: pw.Text(printer.phoneNumber,
                    style: pw.TextStyle(font: _regularFont, fontSize: 8.5, color: PdfColors.grey700)),
              ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text('SALE EXCHANGE',
                  style: pw.TextStyle(font: _boldFont, fontSize: 10.5, letterSpacing: 1.5)),
            ),
            pw.SizedBox(height: 4),
            _dashedDivider(),
            pw.SizedBox(height: 4),

            _kv('Exchange #', exchange.exchangeNumber),
            if ((exchange.originalInvoiceNumber ?? '').isNotEmpty)
              _kv('Against Invoice', exchange.originalInvoiceNumber!),
            _kv('Date', _formatDateTime(exchange.createdAt)),
            if (hasCustomer) _kv('Customer', exchange.customerName!),
            if (hasSalesman) _kv('Salesman', exchange.salesmanName!),

            if (returnLines.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              _dashedDivider(),
              pw.SizedBox(height: 4),
              pw.Text('RETURNED ITEMS',
                  style: pw.TextStyle(font: _boldFont, fontSize: 8, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              _itemsHeader(),
              _dashedDivider(),
              pw.SizedBox(height: 2),
              for (final line in returnLines) _itemRow(line),
              pw.SizedBox(height: 4),
              _kv('Return Sub Total', _fmt(exchange.returnSubtotal)),
              if (exchange.returnDiscount > 0) _kv('Return Discount', '-${_fmt(exchange.returnDiscount)}'),
              _kv('Return Total', _fmt(exchange.returnTotal)),
            ],

            pw.SizedBox(height: 4),
            _dashedDivider(),
            pw.SizedBox(height: 4),
            pw.Text('NEW ITEMS',
                style: pw.TextStyle(font: _boldFont, fontSize: 7.5, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            _itemsHeader(),
            _dashedDivider(),
            pw.SizedBox(height: 2),
            for (final line in newLines) _itemRow(line),
            pw.SizedBox(height: 4),
            _kv('New Sub Total', _fmt(exchange.newSubtotal)),
            if (exchange.newDiscount > 0) _kv('New Discount', '-${_fmt(exchange.newDiscount)}'),
            _kv('New Total', _fmt(exchange.newTotal)),

            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(diffLabel, style: pw.TextStyle(font: _boldFont, fontSize: 10)),
                pw.Text(_fmt(exchange.differenceAmount.abs()),
                    style: pw.TextStyle(font: _boldFont, fontSize: 12)),
              ],
            ),

            if (exchange.payments.any((p) => p.amount > 0.01)) ...[
              pw.SizedBox(height: 6),
              _dashedDivider(),
              pw.SizedBox(height: 4),
              pw.Text('PAYMENT',
                  style: pw.TextStyle(font: _boldFont, fontSize: 8, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              for (final p in exchange.payments.where((p) => p.amount > 0.01))
                _kv(
                    '${p.direction == 'refund' ? 'Refunded' : 'Collected'} (${_payLabel(p.paymentType)})',
                    _fmt(p.amount)),
            ],

            pw.SizedBox(height: 8),
            _dashedDivider(),
            pw.SizedBox(height: 6),

            pw.Text('Exchanged pairs are subject to inspection before acceptance.',
                style: pw.TextStyle(font: _regularFont, fontSize: 6.5, color: PdfColors.grey700)),

            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(
                'Thank you for shopping with us!',
                style: pw.TextStyle(font: _regularFont, fontSize: 9, color: PdfColors.grey700),
              ),
            ),
          ],
        ),
      ),
    );

    return doc;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Shared PDF builder
  // ═══════════════════════════════════════════════════════════════════════

  static Future<pw.Document> _buildDoc({
    required String shopName,
    required PrinterLookupItem? printer,
    required String title,
    required String documentNumberLabel,
    required String documentNumber,
    required DateTime date,
    required String? customerName,
    required String? salesmanName,
    required List<_ReceiptLine> lines,
    required double subtotal,
    required double totalDiscount,
    required double extraDiscount,
    required String extraDiscountLabel,
    required String grandTotalLabel,
    required double grandTotal,
    required List<_ReceiptPayment> payments,
    required String paymentsHeading,
    required List<String> footerNotes,
  }) async {
    final doc = pw.Document();
    final hasCustomer = customerName != null && customerName.isNotEmpty;
    final hasSalesman = salesmanName != null && salesmanName.isNotEmpty;
    final logo = await _fetchLogo(printer?.imageUrl);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (logo != null)
              pw.Center(
                child: pw.Container(
                  width: 55,
                  height: 55,
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
              ),
            pw.Center(
              child: pw.Text(
                shopName.toUpperCase(),
                style: pw.TextStyle(font: _boldFont, fontSize: 14, letterSpacing: 1.5),
              ),
            ),
            if (printer != null && printer.address.isNotEmpty)
              pw.Center(
                child: pw.Text(printer.address,
                    style: pw.TextStyle(font: _regularFont, fontSize: 8.5, color: PdfColors.grey700)),
              ),
            if (printer != null && printer.phoneNumber.isNotEmpty)
              pw.Center(
                child: pw.Text(printer.phoneNumber,
                    style: pw.TextStyle(font: _regularFont, fontSize: 8.5, color: PdfColors.grey700)),
              ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(title,
                  style: pw.TextStyle(font: _boldFont, fontSize: 10.5, letterSpacing: 1.5)),
            ),
            pw.SizedBox(height: 4),
            _dashedDivider(),
            pw.SizedBox(height: 4),

            _kv(documentNumberLabel, documentNumber),
            _kv('Date', _formatDateTime(date)),
            if (hasCustomer) _kv('Customer', customerName),
            if (hasSalesman) _kv('Salesman', salesmanName),

            pw.SizedBox(height: 4),
            _dashedDivider(),
            pw.SizedBox(height: 4),

            _itemsHeader(),
            _dashedDivider(),
            pw.SizedBox(height: 2),
            for (final line in lines) _itemRow(line),

            _dashedDivider(),
            pw.SizedBox(height: 4),

            _kv('Sub Total', _fmt(subtotal)),
            if (totalDiscount > 0) _kv('Discount', '-${_fmt(totalDiscount)}'),
            if (extraDiscount > 0) _kv(extraDiscountLabel, '-${_fmt(extraDiscount)}'),

            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(grandTotalLabel, style: pw.TextStyle(font: _boldFont, fontSize: 14)),
                pw.Text(_fmt(grandTotal), style: pw.TextStyle(font: _boldFont, fontSize: 14)),
              ],
            ),

            if (payments.any((p) => p.amount > 0.01)) ...[
              pw.SizedBox(height: 6),
              _dashedDivider(),
              pw.SizedBox(height: 4),
              pw.Text(paymentsHeading,
                  style: pw.TextStyle(font: _boldFont, fontSize: 8, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              for (final p in payments.where((p) => p.amount > 0.01)) _kv(_payLabel(p.method), _fmt(p.amount)),
            ],

            pw.SizedBox(height: 8),
            _dashedDivider(),
            pw.SizedBox(height: 6),

            for (final note in footerNotes)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Text(note, style: pw.TextStyle(font: _regularFont, fontSize: 7.5, color: PdfColors.grey700)),
              ),

            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(
                'Thank you for shopping with us!',
                style: pw.TextStyle(font: _regularFont, fontSize: 9, color: PdfColors.grey700),
              ),
            ),
          ],
        ),
      ),
    );

    return doc;
  }

  static pw.Widget _itemsHeader() => pw.Row(children: [
        pw.Expanded(
            flex: 3,
            child: pw.Text('ITEM',
                style: pw.TextStyle(font: _boldFont, fontSize: 8))),
        pw.Expanded(
            flex: 2,
            child: pw.Text('COLOR',
                style: pw.TextStyle(font: _boldFont, fontSize: 8),
                textAlign: pw.TextAlign.center)),
        pw.Expanded(
            flex: 2,
            child: pw.Text('SIZE',
                style: pw.TextStyle(font: _boldFont, fontSize: 8),
                textAlign: pw.TextAlign.center)),
        pw.Expanded(
            flex: 1,
            child: pw.Text('QTY',
                style: pw.TextStyle(font: _boldFont, fontSize: 8),
                textAlign: pw.TextAlign.center)),
        pw.Expanded(
            flex: 2,
            child: pw.Text('DIS',
                style: pw.TextStyle(font: _boldFont, fontSize: 8),
                textAlign: pw.TextAlign.center)),
        pw.Expanded(
            flex: 2,
            child: pw.Text('TOTAL',
                style: pw.TextStyle(font: _boldFont, fontSize: 8),
                textAlign: pw.TextAlign.right)),
      ]);

  static pw.Widget _itemRow(_ReceiptLine line) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
                flex: 3,
                child: pw.Text(line.name,
                    style: pw.TextStyle(font: _regularFont, fontSize: 8), maxLines: 2)),
            pw.Expanded(
                flex: 2,
                child: pw.Text(line.colorName ?? '-',
                    style: pw.TextStyle(font: _regularFont, fontSize: 8),
                    textAlign: pw.TextAlign.center)),
            pw.Expanded(
                flex: 2,
                child: pw.Text(line.sizeName ?? '-',
                    style: pw.TextStyle(font: _regularFont, fontSize: 8),
                    textAlign: pw.TextAlign.center)),
            pw.Expanded(
                flex: 1,
                child: pw.Text('${line.quantity}',
                    style: pw.TextStyle(font: _regularFont, fontSize: 8),
                    textAlign: pw.TextAlign.center)),
            pw.Expanded(
                flex: 2,
                child: pw.Text(line.discount > 0 ? line.discount.toStringAsFixed(0) : '-',
                    style: pw.TextStyle(font: _regularFont, fontSize: 8),
                    textAlign: pw.TextAlign.center)),
            pw.Expanded(
                flex: 2,
                child: pw.Text(line.total.toStringAsFixed(0),
                    style: pw.TextStyle(font: _boldFont, fontSize: 8),
                    textAlign: pw.TextAlign.right)),
          ],
        ),
      );

  static pw.Widget _kv(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: pw.TextStyle(font: _regularFont, fontSize: 8.5, color: PdfColors.grey700)),
            pw.Text(value, style: pw.TextStyle(font: _boldFont, fontSize: 8.5)),
          ],
        ),
      );

  static pw.Widget _dashedDivider() => pw.Container(
        width: double.infinity,
        height: 0.7,
        margin: const pw.EdgeInsets.symmetric(vertical: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(
              color: PdfColors.grey600,
              width: 0.7,
              style: pw.BorderStyle.dashed,
            ),
          ),
        ),
      );

  static String _formatDateTime(DateTime dt) {
    final d = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final t = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }

  static String _fmt(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

  static String _payLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      default:
        return method;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Dispatch: web -> print dialog, desktop -> direct silent print
  // ═══════════════════════════════════════════════════════════════════════

  static Future<void> _dispatch(
    pw.Document doc, {
    required String jobName,
    required PrinterLookupItem? printer,
  }) async {
    final bytes = Uint8List.fromList(await doc.save());

    if (kIsWeb) {
      await Printing.layoutPdf(name: jobName, onLayout: (_) async => bytes);
      return;
    }

    final matched = await _resolveDesktopPrinter(printer?.label);
    if (matched == null) {
      // No configured/matching printer found on this machine — fall back
      // to the picker dialog instead of failing silently.
      await Printing.layoutPdf(name: jobName, onLayout: (_) async => bytes);
      return;
    }

    try {
      await Printing.directPrintPdf(
        printer: matched,
        name: jobName,
        onLayout: (_) async => bytes,
      );
    } catch (e) {
      debugPrint('Direct print failed, falling back to dialog: $e');
      await Printing.layoutPdf(name: jobName, onLayout: (_) async => bytes);
    }
  }

  static Future<Printer?> _resolveDesktopPrinter(String? label) async {
    if (label == null || label.isEmpty) return null;
    final printers = await Printing.listPrinters();
    if (printers.isEmpty) return null;

    final needle = label.toLowerCase();
    for (final p in printers) {
      if (p.name.toLowerCase() == needle) return p;
    }
    for (final p in printers) {
      if (p.name.toLowerCase().contains(needle) || needle.contains(p.name.toLowerCase())) {
        return p;
      }
    }
    return null;
  }

  /// Printer head ka logo (Supabase Storage public URL) download karke
  /// receipt mein embed karne ke liye — fail ho to (koi URL nahi, network
  /// error, invalid image) chup chaap null return karta hai, print rukta nahi.
  static Future<pw.ImageProvider?> _fetchLogo(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
      return pw.MemoryImage(res.bodyBytes);
    } catch (e) {
      debugPrint('Logo fetch failed: $e');
      return null;
    }
  }
}

/// One product line on a stock slip.
class StockSlipLine {
  final String name;
  final String? sizeName;
  final String? colorName;
  final int quantity;

  const StockSlipLine({
    required this.name,
    this.sizeName,
    this.colorName,
    required this.quantity,
  });
}

class _ReceiptLine {
  final String name;
  final String? sizeName;
  final String? colorName;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double total;

  const _ReceiptLine({
    required this.name,
    this.sizeName,
    this.colorName,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.total,
  });
}

class _ReceiptPayment {
  final String method;
  final double amount;
  const _ReceiptPayment(this.method, this.amount);
}
