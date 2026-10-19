import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/sale_invoice_model.dart';
import '../provider/sale_invoice_provider.dart';
import 'sale_invoice_screen.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/service/print/print_service.dart';
import 'package:safishoe_app/core/widget/printer_picker_field.dart';

class SaleInvoicesListScreen extends ConsumerStatefulWidget {
  final bool showNewInvoiceButton;
  final void Function(SaleInvoiceModel invoice)? onExchangeTap;

  /// Sab branches ki invoices, ek din ki (date filter ke sath, default aaj) —
  /// Sale Exchange ke liye. False ho to sirf apni branch ki saari invoices.
  final bool allBranchesByDate;

  const SaleInvoicesListScreen({
    super.key,
    this.showNewInvoiceButton = true,
    this.onExchangeTap,
    this.allBranchesByDate = false,
  });

  @override
  ConsumerState<SaleInvoicesListScreen> createState() =>
      _SaleInvoicesListScreenState();
}

class _SaleInvoicesListScreenState extends ConsumerState<SaleInvoicesListScreen> {
  late DateTime _date = _today();

  /// Invoice number search (server-side) — sab branches, kisi bhi din ki.
  /// Search likha ho to date filter ignore hota hai.
  String _search = '';
  Timer? _debounce;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get _isToday => _date == _today();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String v) {
    final next = v.trim();
    if (next == _search) return;
    setState(() => _search = next);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  void _load() {
    if (widget.allBranchesByDate) {
      ref.read(exchangeInvoiceListProvider.notifier).loadByDate(_date, search: _search);
    } else {
      ref.read(saleInvoiceListProvider.notifier).loadInvoices();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: _today(),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    _load();
  }

  void _setToday() {
    setState(() => _date = _today());
    _load();
  }

  Future<void> _onPrint(SaleInvoiceModel inv) async {
    final choice = await pickPrinterForSlip(context, printersForSaleProvider);
    if (choice == null || !mounted) return;
    try {
      // List rows mein items nahi hote — print ke liye poori invoice load karo.
      final detail = await ref
          .read(saleInvoiceRepositoryProvider)
          .getInvoiceDetail(inv.id);
      await ThermalPrintService.printSaleInvoice(detail, printer: choice.printer);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Print failed: $e'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.allBranchesByDate
        ? ref.watch(exchangeInvoiceListProvider)
        : ref.watch(saleInvoiceListProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.allBranchesByDate ? 'Sale Exchange' : 'Sale Invoices',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                        '${state.invoices.length} invoice${state.invoices.length == 1 ? '' : 's'} · Total Rs. ${state.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              if (widget.allBranchesByDate) ...[
                OutlinedButton.icon(
                  onPressed: _search.isEmpty ? _pickDate : null,
                  icon: const AppIcon(AppIcons.calendarTodayOutlined, size: 16),
                  label: Text(_formatDateStatic(_date)),
                ),
                if (!_isToday) ...[
                  const SizedBox(width: 8),
                  TextButton(onPressed: _setToday, child: const Text('Today')),
                ],
                const SizedBox(width: 4),
              ],
              Tooltip(
                message: 'Refresh',
                child: IconButton(
                  onPressed: _load,
                  icon: const AppIcon(AppIcons.refresh, size: 18),
                ),
              ),
              if (widget.showNewInvoiceButton)
                FilledButton.icon(
                  icon: const AppIcon(AppIcons.add, color: Colors.white),
                  label: const Text('New Invoice'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('New Sale Invoice')),
                          body: const SaleInvoiceScreen(),
                        ),
                      ),
                    );
                    if (context.mounted) {
                      ref.read(saleInvoiceListProvider.notifier).loadInvoices();
                    }
                  },
                ),
            ],
          ),
          if (widget.allBranchesByDate) ...[
            const SizedBox(height: 12),
            TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search by invoice number (all branches, any date)...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const AppIcon(AppIcons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
          const SizedBox(height: 16),

          if (state.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state.error != null)
            Expanded(
              child: Center(
                  child: Text('Error: ${state.error}', style: const TextStyle(color: Colors.red))),
            )
          else if (state.invoices.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon(AppIcons.receiptLongOutlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                        !widget.allBranchesByDate
                            ? 'No sale invoices yet'
                            : _search.isNotEmpty
                                ? 'No invoice found for "$_search"'
                                : 'No sale invoices on this date',
                        style: const TextStyle(color: Colors.grey, fontSize: 15)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                return isWide
                    ? _DesktopInvoiceTable(
                        invoices: state.invoices,
                        showBranch: widget.allBranchesByDate,
                        onExchangeTap: widget.onExchangeTap,
                        onPrintTap: _onPrint)
                    : _MobileInvoiceList(
                        invoices: state.invoices,
                        showBranch: widget.allBranchesByDate,
                        onExchangeTap: widget.onExchangeTap,
                        onPrintTap: _onPrint);
              }),
            ),
        ],
      ),
    );
  }
}

// ── Desktop table ─────────────────────────────────────────────────────────

class _DesktopInvoiceTable extends StatelessWidget {
  final List<SaleInvoiceModel> invoices;
  final void Function(SaleInvoiceModel invoice)? onExchangeTap;
  final void Function(SaleInvoiceModel invoice) onPrintTap;
  final bool showBranch;
  const _DesktopInvoiceTable(
      {required this.invoices,
      this.onExchangeTap,
      required this.onPrintTap,
      this.showBranch = false});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white);
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(children: [
            _hcell('Invoice #', flex: 2, style: headerStyle),
            if (showBranch) _hcell('Branch', flex: 2, style: headerStyle),
            _hcell('Customer', flex: 2, style: headerStyle),
            _hcell('Date', flex: 2, style: headerStyle),
            _hcell('Type', flex: 1, style: headerStyle),
            _hcell('Sub Total', flex: 2, style: headerStyle),
            _hcell('Discount', flex: 2, style: headerStyle),
            _hcell('Returned', flex: 2, style: headerStyle),
            _hcell('Net Amount', flex: 2, style: headerStyle),
            _hcell('', flex: 2, style: headerStyle),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: invoices.length,
            itemBuilder: (context, i) {
              final inv = invoices[i];
              return Container(
                color: i.isEven ? Colors.grey.shade50 : Colors.white,
                child: Row(children: [
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(inv.invoiceNumber,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary)),
                          ),
                          if (inv.hasReturn || inv.hasExchange) ...[
                            const SizedBox(width: 6),
                            _StatusBadges(hasReturn: inv.hasReturn, hasExchange: inv.hasExchange),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (showBranch) _dcell(inv.branchName ?? '—', flex: 2),
                  _dcell(inv.customerName ?? '—', flex: 2),
                  _dcell(_formatDate(inv.createdAt), flex: 2),
                  _dcell(inv.paymentTypeLabel.toUpperCase(), flex: 1),
                  _dcell(inv.subtotal.toStringAsFixed(0), flex: 2),
                  _dcell('- ${inv.allDiscount.toStringAsFixed(0)}', flex: 2, style: const TextStyle(color: Colors.orange)),
                  _dcell(_returnedText(inv), flex: 2,
                      style: const TextStyle(color: Colors.red)),
                  _dcell(inv.netAmount.toStringAsFixed(0), flex: 2,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.green)),
                  Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const AppIcon(AppIcons.printOutlined, size: 20),
                            tooltip: 'Print',
                            onPressed: () => onPrintTap(inv),
                          ),
                          if (onExchangeTap != null)
                            IconButton(
                              icon: const AppIcon(AppIcons.swapHorizOutlined, size: 20),
                              tooltip: 'Exchange',
                              onPressed: () => onExchangeTap!(inv),
                            ),
                        ],
                      ),
                    ),
                ]),
              );
            },
          ),
        ),
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                  flex: showBranch ? 9 : 7, child: const Text('TOTALS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              Expanded(
                flex: 2,
                child: Text(invoices.fold(0.0, (s, i) => s + i.subtotal).toStringAsFixed(0),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                flex: 2,
                child: Text(
                    '- ${invoices.fold(0.0, (s, i) => s + i.allDiscount).toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
              ),
              Expanded(
                flex: 2,
                child: Text(
                    '- ${invoices.fold(0.0, (s, i) => s + i.returnedAmount - i.exchangeDifference).toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              ),
              Expanded(
                flex: 2,
                child: Text(invoices.fold(0.0, (s, i) => s + i.netAmount).toStringAsFixed(0),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.green)),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hcell(String text, {int flex = 2, TextStyle? style}) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(text, style: style),
        ),
      );

  Widget _dcell(String text, {int flex = 2, TextStyle? style}) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(text, overflow: TextOverflow.ellipsis, style: style ?? const TextStyle(fontSize: 13)),
        ),
      );

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

String _formatDateStatic(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

/// Returns minus exchange ka farq — jitna invoice ki sale se kam hua.
String _returnedText(SaleInvoiceModel inv) {
  final v = inv.returnedAmount - inv.exchangeDifference;
  if (v == 0) return '—';
  return v > 0 ? '- ${v.toStringAsFixed(0)}' : '+ ${(-v).toStringAsFixed(0)}';
}

// ── Mobile list ───────────────────────────────────────────────────────────

class _MobileInvoiceList extends StatelessWidget {
  final List<SaleInvoiceModel> invoices;
  final void Function(SaleInvoiceModel invoice)? onExchangeTap;
  final void Function(SaleInvoiceModel invoice) onPrintTap;
  final bool showBranch;
  const _MobileInvoiceList(
      {required this.invoices,
      this.onExchangeTap,
      required this.onPrintTap,
      this.showBranch = false});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final inv = invoices[i];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(inv.invoiceNumber,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(inv.paymentTypeLabel.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    if (inv.hasReturn || inv.hasExchange) ...[
                      const SizedBox(width: 6),
                      _StatusBadges(hasReturn: inv.hasReturn, hasExchange: inv.hasExchange),
                    ],
                    const Spacer(),
                    Text(_formatDate(inv.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const AppIcon(AppIcons.printOutlined, size: 18),
                      tooltip: 'Print',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => onPrintTap(inv),
                    ),
                    if (onExchangeTap != null)
                      IconButton(
                        icon: const AppIcon(AppIcons.swapHorizOutlined, size: 18),
                        tooltip: 'Exchange',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => onExchangeTap!(inv),
                      ),
                  ],
                ),
                if (showBranch && (inv.branchName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(inv.branchName!,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary)),
                ],
                if (inv.customerName != null && inv.customerName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(inv.customerName!, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat('Sub Total', inv.subtotal.toStringAsFixed(0)),
                    _stat('Discount', '- ${inv.allDiscount.toStringAsFixed(0)}', color: Colors.orange),
                    if (inv.hasReturn || inv.hasExchange)
                      _stat('Returned', _returnedText(inv), color: Colors.red),
                    _stat('Net Amount', inv.netAmount.toStringAsFixed(0), color: Colors.green.shade700),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color ?? Colors.black87)),
      ],
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ── Status badges (Returned / Exchanged) ────────────────────────────────────

/// Invoice ke against koi sale_return ya sale_exchange record hai to yahan
/// badge dikhta hai — is se cashier/manager ko dono jagah (invoice list ke
/// tor par "sale report" aur exchange ka invoice-picker, chunke wo yehi
/// widget reuse karta hai) foran pata chal jata hai ke ye invoice
/// return/exchange ho chuka hai.
class _StatusBadges extends StatelessWidget {
  final bool hasReturn;
  final bool hasExchange;
  const _StatusBadges({required this.hasReturn, required this.hasExchange});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasReturn) _badge('Returned', Colors.red),
        if (hasReturn && hasExchange) const SizedBox(width: 4),
        if (hasExchange) _badge('Exchanged', Colors.blue),
      ],
    );
  }

  Widget _badge(String label, MaterialColor color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.shade200),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color.shade700)),
      );
}
