import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'receipt_options.dart';
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

  /// Receipt header ka naam — printer design preview isi ko dikhata hai.
  static const String defaultShopName = _defaultShopName;

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
                name: i.b1g1FreeQty > 0
                    ? '${i.productName ?? '-'} (Buy 1 Get 1: ${i.b1g1FreeQty} free)'
                    : i.productName ?? '-',
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
    String? address,
    String? phone,
    String footerNote =
        'Stock stays pending until the receiving branch accepts it.',
  }) async {
    final doc = pw.Document();
    // Printer na ho to default header: app ka Safi Shoes logo + diya gaya
    // address/phone.
    final logo =
        await _fetchLogo(printer?.imageUrl) ?? await _defaultLogo();
    final headerAddress =
        printer != null && printer.address.isNotEmpty ? printer.address : address;
    final headerPhone = printer != null && printer.phoneNumber.isNotEmpty
        ? printer.phoneNumber
        : phone;
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
            if (headerAddress != null && headerAddress.isNotEmpty)
              pw.Center(
                child: pw.Text(headerAddress,
                    style: pw.TextStyle(font: _regularFont, fontSize: 8.5, color: PdfColors.grey700)),
              ),
            if (headerPhone != null && headerPhone.isNotEmpty)
              pw.Center(
                child: pw.Text(headerPhone,
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
    final o = printer?.options ?? const ReceiptOptions();

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
            ..._header(logo, shopName, printer),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text('SALE EXCHANGE',
                  style: pw.TextStyle(font: _boldFont, fontSize: 10.5, letterSpacing: 1.5)),
            ),
            pw.SizedBox(height: 4),
            _dashedDivider(),
            pw.SizedBox(height: 4),

            if (o.showDocNumber) _kv('Exchange #', exchange.exchangeNumber),
            if (o.showDocNumber &&
                (exchange.originalInvoiceNumber ?? '').isNotEmpty)
              _kv('Against Invoice', exchange.originalInvoiceNumber!),
            if (o.showDate) _kv('Date', _formatDateTime(exchange.createdAt)),
            if (o.showCustomer && hasCustomer)
              _kv('Customer', exchange.customerName!),
            if (o.showSalesman && hasSalesman)
              _kv('Salesman', exchange.salesmanName!),

            if (returnLines.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              _dashedDivider(),
              pw.SizedBox(height: 4),
              pw.Text('RETURNED ITEMS',
                  style: pw.TextStyle(font: _boldFont, fontSize: 8, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              _itemsHeader(o),
              _dashedDivider(),
              pw.SizedBox(height: 2),
              for (final line in returnLines) _itemRow(line, o),
              pw.SizedBox(height: 4),
              if (o.showSubTotal)
                _kv('Return Sub Total', _fmt(exchange.returnSubtotal)),
              if (o.showDiscount && exchange.returnDiscount > 0)
                _kv('Return Discount', '-${_fmt(exchange.returnDiscount)}'),
              _kv('Return Total', _fmt(exchange.returnTotal)),
            ],

            pw.SizedBox(height: 4),
            _dashedDivider(),
            pw.SizedBox(height: 4),
            pw.Text('NEW ITEMS',
                style: pw.TextStyle(font: _boldFont, fontSize: 7.5, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            _itemsHeader(o),
            _dashedDivider(),
            pw.SizedBox(height: 2),
            for (final line in newLines) _itemRow(line, o),
            pw.SizedBox(height: 4),
            if (o.showSubTotal)
              _kv('New Sub Total', _fmt(exchange.newSubtotal)),
            if (o.showDiscount && exchange.newDiscount > 0)
              _kv('New Discount', '-${_fmt(exchange.newDiscount)}'),
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

            if (o.showPayments &&
                exchange.payments.any((p) => p.amount > 0.01)) ...[
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

            if (o.showNotes)
              pw.Text('Exchanged pairs are subject to inspection before acceptance.',
                  style: pw.TextStyle(font: _regularFont, fontSize: 6.5, color: PdfColors.grey700)),
            ..._footerLines(o),
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
    final o = printer?.options ?? const ReceiptOptions();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            ..._header(logo, shopName, printer),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(title,
                  style: pw.TextStyle(font: _boldFont, fontSize: 10.5, letterSpacing: 1.5)),
            ),
            pw.SizedBox(height: 4),
            _dashedDivider(),
            pw.SizedBox(height: 4),

            if (o.showDocNumber) _kv(documentNumberLabel, documentNumber),
            if (o.showDate) _kv('Date', _formatDateTime(date)),
            if (o.showCustomer && hasCustomer) _kv('Customer', customerName),
            if (o.showSalesman && hasSalesman) _kv('Salesman', salesmanName),

            pw.SizedBox(height: 4),
            _dashedDivider(),
            pw.SizedBox(height: 4),

            _itemsHeader(o),
            _dashedDivider(),
            pw.SizedBox(height: 2),
            for (final line in lines) _itemRow(line, o),

            _dashedDivider(),
            pw.SizedBox(height: 4),

            if (o.showSubTotal) _kv('Sub Total', _fmt(subtotal)),
            if (o.showDiscount && totalDiscount > 0)
              _kv('Discount', '-${_fmt(totalDiscount)}'),
            if (o.showDiscount && extraDiscount > 0)
              _kv(extraDiscountLabel, '-${_fmt(extraDiscount)}'),

            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(grandTotalLabel, style: pw.TextStyle(font: _boldFont, fontSize: 14)),
                pw.Text(_fmt(grandTotal), style: pw.TextStyle(font: _boldFont, fontSize: 14)),
              ],
            ),

            if (o.showPayments && payments.any((p) => p.amount > 0.01)) ...[
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

            if (o.showNotes)
              for (final note in footerNotes)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Text(note, style: pw.TextStyle(font: _regularFont, fontSize: 7.5, color: PdfColors.grey700)),
                ),
            ..._footerLines(o),
          ],
        ),
      ),
    );

    return doc;
  }

  /// Receipt header — logo, uske neeche name, phone, address. Position
  /// (left/center/right) aur on/off printer head ki design settings se aati
  /// hai; printer na ho to default (center, sab on).
  static List<pw.Widget> _header(
    pw.ImageProvider? logo,
    String shopName,
    PrinterLookupItem? printer,
  ) {
    final position = printer?.logoPosition ?? 'center';
    final align = switch (position) {
      'left' => pw.Alignment.centerLeft,
      'right' => pw.Alignment.centerRight,
      _ => pw.Alignment.center,
    };
    final textAlign = switch (position) {
      'left' => pw.TextAlign.left,
      'right' => pw.TextAlign.right,
      _ => pw.TextAlign.center,
    };
    pw.Widget line(String text, pw.TextStyle style) => pw.Align(
          alignment: align,
          child: pw.Text(text, style: style, textAlign: textAlign),
        );
    final smallStyle =
        pw.TextStyle(font: _regularFont, fontSize: 8.5, color: PdfColors.grey700);

    return [
      if (logo != null && (printer?.showLogo ?? true))
        pw.Align(
          alignment: align,
          child: pw.Container(
            width: 55,
            height: 55,
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),
        ),
      if (printer?.showName ?? true)
        line(shopName.toUpperCase(),
            pw.TextStyle(font: _boldFont, fontSize: 14, letterSpacing: 1.5)),
      if (printer != null &&
          printer.showPhone &&
          printer.phoneNumber.isNotEmpty)
        line(printer.phoneNumber, smallStyle),
      if (printer != null &&
          printer.showAddress &&
          printer.address.isNotEmpty)
        line(printer.address, smallStyle),
    ];
  }

  /// Extra note + thank-you line (printer design se on/off aur text).
  static List<pw.Widget> _footerLines(ReceiptOptions o) => [
        if (o.extraNote.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(o.extraNote,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                    font: _regularFont, fontSize: 8, color: PdfColors.grey700)),
          ),
        ],
        if (o.showThankYou) ...[
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text(o.thankYouText,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                    font: _regularFont, fontSize: 9, color: PdfColors.grey700)),
          ),
        ],
      ];

  static pw.Widget _itemsHeader([ReceiptOptions o = const ReceiptOptions()]) {
    pw.Widget h(String t, int flex, pw.TextAlign align) => pw.Expanded(
        flex: flex,
        child: pw.Text(t,
            style: pw.TextStyle(font: _boldFont, fontSize: 8),
            textAlign: align));
    return pw.Row(children: [
      h('ITEM', 3, pw.TextAlign.left),
      if (o.showColorColumn) h('COLOR', 2, pw.TextAlign.center),
      if (o.showSizeColumn) h('SIZE', 2, pw.TextAlign.center),
      h('QTY', 1, pw.TextAlign.center),
      if (o.showDiscountColumn) h('DIS', 2, pw.TextAlign.center),
      h('TOTAL', 2, pw.TextAlign.right),
    ]);
  }

  static pw.Widget _itemRow(_ReceiptLine line,
      [ReceiptOptions o = const ReceiptOptions()]) {
    pw.Widget c(String t, int flex, pw.TextAlign align,
            {pw.Font? font, int? maxLines}) =>
        pw.Expanded(
            flex: flex,
            child: pw.Text(t,
                style: pw.TextStyle(font: font ?? _regularFont, fontSize: 8),
                textAlign: align,
                maxLines: maxLines));
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          c(line.name, 3, pw.TextAlign.left, maxLines: 2),
          if (o.showColorColumn)
            c(line.colorName ?? '-', 2, pw.TextAlign.center),
          if (o.showSizeColumn)
            c(line.sizeName ?? '-', 2, pw.TextAlign.center),
          c('${line.quantity}', 1, pw.TextAlign.center),
          if (o.showDiscountColumn)
            c(line.discount > 0 ? line.discount.toStringAsFixed(0) : '-', 2,
                pw.TextAlign.center),
          c(line.total.toStringAsFixed(0), 2, pw.TextAlign.right,
              font: _boldFont),
        ],
      ),
    );
  }

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
  static Future<pw.ImageProvider?> _defaultLogo() async {
    try {
      final data = await rootBundle.load('assets/images/safi.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      debugPrint('Default logo load failed: $e');
      return null;
    }
  }

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
