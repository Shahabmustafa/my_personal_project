import 'package:flutter/material.dart';

import '../../../../branch/sale_exchange/data/model/sale_exchange_model.dart';
import '../../../../branch/sale_invoice/data/model/sale_invoice_model.dart';
import '../../../../branch/sale_return/data/model/sale_return_model.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
/// Right-side slide-in panel shared by the sale/return/exchange report
/// screens — shows a single record's full detail (products, payments,
/// totals) when its "View" action is tapped. Each screen supplies its own
/// [child] body; only the header (title/subtitle/print/close) is common.
class ReportDetailPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onClose;

  /// Null hone par print button hide ho jata hai (e.g. assignment detail —
  /// print karne ko kuch nahi hota).
  final VoidCallback? onPrint;
  final Widget child;

  const ReportDetailPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onClose,
    this.onPrint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth < 480 ? screenWidth : 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1B1F3B),
            blurRadius: 24,
            offset: Offset(-6, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F8FC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: accent)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (onPrint != null)
                  Tooltip(
                    message: 'Print',
                    child: IconButton(
                      icon: const AppIcon(AppIcons.printOutlined, size: 20),
                      onPressed: onPrint,
                    ),
                  ),
                Tooltip(
                  message: 'Close',
                  child: IconButton(
                    icon: const AppIcon(AppIcons.close, size: 20),
                    onPressed: onClose,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// [ReportDetailPanel] ko table ke upar right-side overlay ki tarah dikhata
/// hai — peeche scrim (tap se close), panel poori height right par slide-in.
/// Table ab full width leti hai; detail sirf "View" par overlay hoti hai.
class ReportDetailOverlay extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onClose;
  final VoidCallback? onPrint;
  final Widget child;

  const ReportDetailOverlay({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onClose,
    this.onPrint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(color: const Color(0x33101223)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              heightFactor: 1,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                tween: Tween(begin: 1, end: 0),
                builder: (context, t, panel) => Transform.translate(
                  offset: Offset(t * 32, 0),
                  child: Opacity(opacity: 1 - t, child: panel),
                ),
                child: ReportDetailPanel(
                  title: title,
                  subtitle: subtitle,
                  accent: accent,
                  onClose: onClose,
                  onPrint: onPrint,
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading used inside a detail panel body (e.g. "ITEMS", "PAYMENTS").
class DetailSectionLabel extends StatelessWidget {
  final String text;
  const DetailSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A8FA3),
                letterSpacing: 0.5)),
      );
}

/// A label/value row used for header fields (Invoice #, Date, Customer, …)
/// and totals (Sub Total, Discount, Total) inside a detail panel.
class DetailKV extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  const DetailKV(this.label, this.value, {super.key, this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3))),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                    color: valueColor ?? const Color(0xFF2D2D3A))),
          ],
        ),
      );
}

/// A single product line inside a detail panel's item list.
class DetailProductRow extends StatelessWidget {
  final String name;
  final String? sizeName;
  final String? colorName;
  final int quantity;
  final double total;

  const DetailProductRow({
    super.key,
    required this.name,
    this.sizeName,
    this.colorName,
    required this.quantity,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final meta = [
      if ((colorName ?? '').isNotEmpty) colorName!,
      if ((sizeName ?? '').isNotEmpty) 'Size ${sizeName!}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (meta.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(meta,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA3))),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('x$quantity', style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
          const SizedBox(width: 12),
          Text('Rs. ${total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Divider used between detail-panel sections.
class DetailDivider extends StatelessWidget {
  const DetailDivider({super.key});
  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Color(0xFFE7E9F0)));
}

/// Detail-panel body for a sale invoice — shared by the Sale Invoice report
/// and the combined Sale Summary screen.
class InvoiceDetailBody extends StatelessWidget {
  final SaleInvoiceModel invoice;
  const InvoiceDetailBody({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailKV('Branch', invoice.branchName ?? '—'),
        DetailKV('Customer', invoice.customerName ?? '—'),
        DetailKV('Payment', invoice.paymentTypeLabel.toUpperCase()),
        if (invoice.hasReturn || invoice.hasExchange)
          DetailKV(
              'Status',
              [
                if (invoice.hasReturn) 'Returned',
                if (invoice.hasExchange) 'Exchanged',
              ].join(' · '),
              valueColor: Colors.red),
        const DetailDivider(),
        DetailSectionLabel('ITEMS (${invoice.items.length})'),
        for (final item in invoice.items)
          DetailProductRow(
            name: item.productName ?? 'Item',
            sizeName: item.sizeName,
            colorName: item.colorName,
            quantity: item.quantity,
            total: item.totalPrice,
          ),
        const DetailDivider(),
        DetailKV('Sub Total', 'Rs. ${invoice.subtotal.toStringAsFixed(0)}'),
        if (invoice.totalDiscount > 0)
          DetailKV('Discount', '- Rs. ${invoice.totalDiscount.toStringAsFixed(0)}',
              valueColor: Colors.orange),
        if (invoice.invoiceDiscount > 0)
          DetailKV('Invoice Discount', '- Rs. ${invoice.invoiceDiscount.toStringAsFixed(0)}',
              valueColor: Colors.orange),
        DetailKV('Total', 'Rs. ${invoice.totalAmount.toStringAsFixed(0)}',
            bold: true, valueColor: Colors.green.shade700),
        if (invoice.payments.isNotEmpty) ...[
          const DetailDivider(),
          DetailSectionLabel('PAYMENTS'),
          for (final p in invoice.payments)
            DetailKV(p.paymentType.toUpperCase(), 'Rs. ${p.amount.toStringAsFixed(0)}'),
        ],
      ],
    );
  }
}

/// Detail-panel body for a sale return — shared by the Sale Return report
/// and the combined Sale Summary screen.
class ReturnDetailBody extends StatelessWidget {
  final SaleReturnModel saleReturn;
  const ReturnDetailBody({super.key, required this.saleReturn});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailKV('Branch', saleReturn.branchName ?? '—'),
        DetailKV('Customer', saleReturn.customerName ?? '—'),
        DetailKV('Against Invoice', saleReturn.originalInvoiceNumber ?? '—'),
        DetailKV('Refund Via', saleReturn.paymentTypeLabel.toUpperCase()),
        const DetailDivider(),
        DetailSectionLabel('ITEMS (${saleReturn.items.length})'),
        for (final item in saleReturn.items)
          DetailProductRow(
            name: item.productName ?? 'Item',
            sizeName: item.sizeName,
            colorName: item.colorName,
            quantity: item.quantity,
            total: item.totalPrice,
          ),
        const DetailDivider(),
        DetailKV('Sub Total', 'Rs. ${saleReturn.subtotal.toStringAsFixed(0)}'),
        if (saleReturn.totalDiscount > 0)
          DetailKV('Discount', '- Rs. ${saleReturn.totalDiscount.toStringAsFixed(0)}',
              valueColor: Colors.orange),
        DetailKV('Refund Amount', 'Rs. ${saleReturn.totalAmount.toStringAsFixed(0)}',
            bold: true, valueColor: Colors.red.shade400),
        if (saleReturn.payments.isNotEmpty) ...[
          const DetailDivider(),
          DetailSectionLabel('REFUNDED VIA'),
          for (final p in saleReturn.payments)
            DetailKV(p.paymentType.toUpperCase(), 'Rs. ${p.amount.toStringAsFixed(0)}'),
        ],
      ],
    );
  }
}

/// Detail-panel body for a sale exchange — shared by the Sale Exchange
/// report and the combined Sale Summary screen.
class ExchangeDetailBody extends StatelessWidget {
  final SaleExchangeModel exchange;
  const ExchangeDetailBody({super.key, required this.exchange});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailKV('Branch', exchange.branchName ?? '—'),
        DetailKV('Customer', exchange.customerName ?? '—'),
        DetailKV('Against Invoice', exchange.originalInvoiceNumber ?? '—'),
        if (exchange.returnItems.isNotEmpty) ...[
          const DetailDivider(),
          DetailSectionLabel('RETURNED ITEMS (${exchange.returnItems.length})'),
          for (final item in exchange.returnItems)
            DetailProductRow(
              name: item.productName ?? 'Item',
              sizeName: item.sizeName,
              colorName: item.colorName,
              quantity: item.quantity,
              total: item.totalPrice,
            ),
          DetailKV('Return Total', 'Rs. ${exchange.returnTotal.toStringAsFixed(0)}'),
        ],
        const DetailDivider(),
        DetailSectionLabel('NEW ITEMS (${exchange.newItems.length})'),
        for (final item in exchange.newItems)
          DetailProductRow(
            name: item.productName ?? 'Item',
            sizeName: item.sizeName,
            colorName: item.colorName,
            quantity: item.quantity,
            total: item.totalPrice,
          ),
        DetailKV('New Total', 'Rs. ${exchange.newTotal.toStringAsFixed(0)}'),
        const DetailDivider(),
        DetailKV(
          exchange.differenceLabel == 'Refund'
              ? 'Refund To Customer'
              : exchange.differenceLabel == 'Collect'
                  ? 'Collect From Customer'
                  : 'Even Exchange',
          'Rs. ${exchange.differenceAmount.abs().toStringAsFixed(0)}',
          bold: true,
          valueColor: exchange.differenceAmount < 0
              ? Colors.red.shade400
              : exchange.differenceAmount > 0
                  ? Colors.green.shade700
                  : null,
        ),
        if (exchange.payments.isNotEmpty) ...[
          const DetailDivider(),
          DetailSectionLabel('PAYMENTS'),
          for (final p in exchange.payments)
            DetailKV('${p.direction == 'refund' ? 'Refunded' : 'Collected'} (${p.paymentType.toUpperCase()})',
                'Rs. ${p.amount.toStringAsFixed(0)}'),
        ],
      ],
    );
  }
}
