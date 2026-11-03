import 'package:safishoe_app/core/utils/date_format.dart' as dfmt;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:safishoe_app/core/widget/invoice_page_body.dart';
import 'package:safishoe_app/core/utils/responsive.dart';
import 'package:safishoe_app/core/widget/adaptive_row.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../sale_invoice/data/model/sale_invoice_model.dart';
import '../../../sale_invoice/presentation/provider/sale_invoice_provider.dart'
    show salesmenProvider, printersForSaleProvider, bankEntriesForSaleProvider;
import '../provider/sale_exchange_provider.dart';
import '../widgets/sale_exchange_new_cart_table.dart';
import '../../../sale_invoice/presentation/widgets/sale_product_selector.dart';
import '../widgets/sale_exchange_return_items_picker.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/utils/error_text.dart';
import 'package:safishoe_app/core/widget/error_view.dart';

/// Layout bilkul SaleInvoiceScreen jaisa: header card (number + payment
/// toggle + date), meta row (salesman / printer / bank / cash), return
/// items, new item selector, cart jo bachi jagah bharta hai, aur neeche
/// footer (totals + note + Collect/Refund + Clear/Save).
class SaleExchangeScreen extends ConsumerWidget {
  const SaleExchangeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saleExchangeProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final isMobile = Responsive(context).isMobile;

    if (state.originalInvoiceLoading || state.originalInvoice == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final invoice = state.originalInvoice!;

    final numberValue = state.numberLoading
        ? const SizedBox(width: 80, child: LinearProgressIndicator(minHeight: 2))
        : Text(
            state.exchangeNumber.isEmpty ? '...' : state.exchangeNumber,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          );

    final header = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppIcon(AppIcons.swapHoriz, color: primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Wrap(
                  spacing: 32,
                  runSpacing: 10,
                  children: [
                    _headerField('Exchange Number', numberValue),
                    _headerField(
                      'Original Invoice',
                      Text(
                        invoice.invoiceNumber,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                    _headerField(
                      'Customer',
                      Text(invoice.customerName ?? '—',
                          style: const TextStyle(fontSize: 15)),
                    ),
                    if (invoice.branchName != null &&
                        invoice.branchName!.isNotEmpty)
                      _headerField(
                        'Branch',
                        Text(invoice.branchName!,
                            style: const TextStyle(fontSize: 15)),
                      ),
                  ],
                ),
              ),
              _headerField(
                'Date',
                Text(
                  _formatDate(DateTime.now()),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                end: true,
              ),
            ],
          ),
          // Payment type — sirf tab jab paisa lena/dena ho
          if (state.differenceAmount != 0) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isMobile)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      state.isCollect ? 'Collect via' : 'Refund via',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600),
                    ),
                  ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _PaymentTypeToggle(
                      stretch: isMobile,
                      value: state.paymentType,
                      onChanged: ref
                          .read(saleExchangeProvider.notifier)
                          .selectPaymentType,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return InvoicePageBody(
      scrollOnDesktop: true,
      top: [
        header,
        const SizedBox(height: 12),
        const _ExchangePaymentRow(),
        const SaleExchangeReturnItemsPicker(),
        const SizedBox(height: 12),
        const _SectionLabel(
          icon: AppIcons.add,
          label: 'New items (customer takes)',
        ),
        SaleProductSelector(
          leading: const [_SalesmanField(), _PrinterField()],
          buttonLabel: 'Add New Item',
          onAdd: (ref, stock, qty) => ref
              .read(saleExchangeProvider.notifier)
              .addNewCartItem(stock, quantity: qty),
        ),
        const SizedBox(height: 8),
      ],
      cart: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const SaleExchangeNewCartTable(),
      ),
      bottom: [
        const SizedBox(height: 12),
        const _ExchangeFooter(),
      ],
    );
  }

  Widget _headerField(String label, Widget value, {bool end = false}) =>
      Column(
        crossAxisAlignment:
            end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          value,
        ],
      );

  String _formatDate(DateTime dt) => dfmt.fmtDateTime(dt);
}

class _SectionLabel extends StatelessWidget {
  final String icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          AppIcon(icon, size: 15, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment type toggle (cash / card / cash + card) ─────────────────────

class _PaymentTypeToggle extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;

  /// Mobile: fill the row width, segments share it equally.
  final bool stretch;
  const _PaymentTypeToggle(
      {required this.value, required this.onChanged, this.stretch = false});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min, children: [
        _seg('Cash', 'cash', AppIcons.paymentsOutlined, primary),
        _seg('Card', 'card', AppIcons.creditCardOutlined, primary),
        _seg('Cash + Card', 'cash_card', AppIcons.syncAlt, primary),
      ]),
    );
  }

  Widget _seg(String label, String type, String icon, Color primary) {
    final selected = value == type;
    final seg = InkWell(
      onTap: () => onChanged(type),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: stretch ? 6 : 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
            mainAxisAlignment:
                stretch ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
          AppIcon(icon, size: 16, color: selected ? Colors.white : Colors.grey.shade600),
          const SizedBox(width: 6),
          stretch ? Flexible(child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: stretch ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.grey.shade700))) : Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: stretch ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.grey.shade700)),
        ]),
      ),
    );
    return stretch ? Expanded(child: seg) : seg;
  }
}

// ── Salesman / Printer (product selector ki row mein) ───────────────────

InputDecoration _decor(String label, {bool required = false}) => InputDecoration(
      labelText: required ? '$label *' : label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );

class _SalesmanField extends ConsumerWidget {
  const _SalesmanField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saleExchangeProvider);
    return ref.watch(salesmenProvider).when(
          loading: () => const _FieldLoading(),
          error: (e, _) => InlineError(e, onRetry: () => ref.invalidate(salesmenProvider)),
          data: (list) => DropdownSearch<EmployeeLookupItem>(
            items: (f, _) => list.where((e) => e.name.toLowerCase().contains(f.toLowerCase())).toList(),
            selectedItem: state.salesman,
            itemAsString: (e) => e.name,
            compareFn: (a, b) => a.id == b.id,
            onSelected: ref.read(saleExchangeProvider.notifier).selectSalesman,
            decoratorProps: DropDownDecoratorProps(decoration: _decor('Salesman', required: true)),
            popupProps: const PopupProps.menu(fit: FlexFit.loose, showSearchBox: true, constraints: BoxConstraints(maxHeight: 260)),
          ),
        );
  }
}

class _PrinterField extends ConsumerWidget {
  const _PrinterField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saleExchangeProvider);
    return ref.watch(printersForSaleProvider).when(
          loading: () => const _FieldLoading(),
          error: (e, _) => InlineError(e, onRetry: () => ref.invalidate(printersForSaleProvider)),
          data: (list) => DropdownSearch<PrinterLookupItem>(
            items: (f, _) => list.where((e) => e.label.toLowerCase().contains(f.toLowerCase())).toList(),
            selectedItem: state.printer,
            itemAsString: (e) => e.label,
            compareFn: (a, b) => a.id == b.id,
            onSelected: ref.read(saleExchangeProvider.notifier).selectPrinter,
            decoratorProps: DropDownDecoratorProps(decoration: _decor('Printer', required: true)),
            popupProps: const PopupProps.menu(fit: FlexFit.loose, showSearchBox: true, constraints: BoxConstraints(maxHeight: 260)),
          ),
        );
  }
}

// ── Bank / Cash row — sirf jab card ya cash + card se paisa lena/dena ho ──

class _ExchangePaymentRow extends ConsumerStatefulWidget {
  const _ExchangePaymentRow();

  @override
  ConsumerState<_ExchangePaymentRow> createState() => _ExchangePaymentRowState();
}

class _ExchangePaymentRowState extends ConsumerState<_ExchangePaymentRow> {
  final _cashAmountCtrl = TextEditingController();

  @override
  void dispose() {
    _cashAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive(context).isMobile;
    final state = ref.watch(saleExchangeProvider);
    final notifier = ref.read(saleExchangeProvider.notifier);

    final hasPayment = state.differenceAmount != 0;
    final showBank = hasPayment &&
        (state.paymentType == 'card' || state.paymentType == 'cash_card');
    final showCash = hasPayment && state.paymentType == 'cash_card';
    if (!showBank) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: adaptiveFieldRow(
 isMobile,
 [
          Expanded(
            child: ref.watch(bankEntriesForSaleProvider).when(
                  loading: () => const _FieldLoading(),
                  error: (e, _) => InlineError(e, onRetry: () => ref.invalidate(bankEntriesForSaleProvider)),
                  data: (list) => DropdownSearch<BankEntryLookupItem>(
                    items: (f, _) =>
                        list.where((e) => e.label.toLowerCase().contains(f.toLowerCase())).toList(),
                    selectedItem: state.bankEntry,
                    itemAsString: (e) => e.label,
                    compareFn: (a, b) => a.id == b.id,
                    onSelected: notifier.selectBankEntry,
                    decoratorProps:
                        DropDownDecoratorProps(decoration: _decor('Bank Account', required: true)),
                    popupProps: const PopupProps.menu(
                        fit: FlexFit.loose,
                        showSearchBox: true, constraints: BoxConstraints(maxHeight: 260)),
                  ),
                ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: showCash
                ? TextField(cursorHeight: 16, 
                    controller: _cashAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    ],
                    onChanged: (v) => notifier.setCashAmount(double.tryParse(v.trim()) ?? 0),
                    decoration: _decor('Cash Amount', required: true).copyWith(
                      helperText: 'Card: Rs. ${state.cardAmount.toStringAsFixed(0)}',
                      helperStyle: const TextStyle(fontSize: 11),
                    ),
                  )
                : const SizedBox(),
          ),
          const Spacer(flex: 2),
        ],
 ),
    );
  }
}

class _FieldLoading extends StatelessWidget {
  const _FieldLoading();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 48,
        child: Center(child: LinearProgressIndicator()),
      );
}

// ── Footer ─────────────────────────────────────────────────────────────

class _ExchangeFooter extends ConsumerWidget {
  const _ExchangeFooter();

  void _clear(WidgetRef ref) {
    final n = ref.read(saleExchangeProvider.notifier);
    for (final i in ref.read(saleExchangeProvider).returnCartItems) {
      if (i.quantity > 0) n.setReturnQuantity(i.originalItemId, 0);
    }
    for (final i in List.of(ref.read(saleExchangeProvider).newCartItems)) {
      n.removeNewItem(i.branchStockId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = Responsive(context).isMobile;
    final state = ref.watch(saleExchangeProvider);

    final canSave = !state.isSaving &&
        state.returnCartItems.any((i) => i.quantity > 0) &&
        state.newCartItems.isNotEmpty;
    final canClear = state.returnCartItems.any((i) => i.quantity > 0) ||
        state.newCartItems.isNotEmpty;

    final Color diffColor;
    final String diffLabel;
    final String diffIcon;
    if (state.isCollect) {
      diffColor = Colors.green.shade700;
      diffLabel = 'Collect from customer';
      diffIcon = AppIcons.add;
    } else if (state.isRefund) {
      diffColor = Colors.red.shade700;
      diffLabel = 'Refund to customer';
      diffIcon = AppIcons.swapHoriz;
    } else {
      diffColor = Colors.grey.shade600;
      diffLabel = 'Even exchange';
      diffIcon = AppIcons.checkCircleOutline;
    }

    final diffBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: diffColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: diffColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(diffIcon, size: 18, color: diffColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(diffLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: diffColor)),
              Text(
                'Rs. ${state.absDifference.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: diffColor),
              ),
            ],
          ),
        ],
      ),
    );

    final note = TextField(cursorHeight: 16, 
      onChanged: (v) => ref.read(saleExchangeProvider.notifier).setNote(v),
      decoration: InputDecoration(
        hintText: 'Note (optional)',
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );

    final clearButton = OutlinedButton.icon(
      icon: const AppIcon(AppIcons.clearAll, size: 18),
      label: const Text('Clear'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: canClear ? () => _clear(ref) : null,
    );

    final saveButton = FilledButton.icon(
      icon: state.isSaving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const AppIcon(AppIcons.swapHoriz, size: 18),
      label: const Text('Save Exchange'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: canSave ? () => _onSaveTap(context, ref) : null,
    );

    final totals = [
      _stat('Return Total', '- Rs. ${state.returnTotal.toStringAsFixed(0)}',
          color: Colors.red.shade700),
      _stat('New Total', 'Rs. ${state.newTotal.toStringAsFixed(0)}',
          color: Colors.green.shade700),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Wrap(spacing: 24, runSpacing: 8, children: totals),
                    diffBadge,
                  ],
                ),
                const SizedBox(height: 12),
                note,
                const SizedBox(height: 12),
                Row(
                  children: [
                    clearButton,
                    const SizedBox(width: 10),
                    Expanded(child: saveButton),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                ...[
                  for (final t in totals) ...[t, const SizedBox(width: 28)],
                ],
                Expanded(child: note),
                const SizedBox(width: 20),
                diffBadge,
                const SizedBox(width: 20),
                clearButton,
                const SizedBox(width: 10),
                saveButton,
              ],
            ),
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.black87)),
      ],
    );
  }

  Future<void> _onSaveTap(BuildContext context, WidgetRef ref) async {
    final state = ref.read(saleExchangeProvider);

    String? warning;
    if (state.salesman == null) {
      warning = 'Please select a salesman';
    } else if (state.printer == null) {
      warning = 'Please select a printer';
    } else if (state.differenceAmount != 0) {
      if (state.paymentType == 'card' && state.bankEntry == null) {
        warning = 'Please select a bank account';
      } else if (state.paymentType == 'cash_card') {
        if (state.bankEntry == null) {
          warning = 'Please select a bank account for the card portion';
        } else if (state.cashAmount <= 0 || state.cashAmount >= state.absDifference) {
          warning = 'Enter a cash amount between 0 and the difference amount';
        }
      }
    }
    if (warning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const AppIcon(AppIcons.warningAmberRounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(warning),
          ]),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final returnCount = state.returnCartItems.where((i) => i.quantity > 0).length;
    final newCount = state.newCartItems.length;
    final diffLabel = state.isCollect
        ? 'Collect Rs.${state.absDifference.toStringAsFixed(0)}'
        : state.isRefund
            ? 'Refund Rs.${state.absDifference.toStringAsFixed(0)}'
            : 'Even exchange';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          AppIcon(AppIcons.swapHoriz, color: Colors.green, size: 22),
          SizedBox(width: 8),
          Text('Confirm Exchange', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: Text('Return $returnCount item(s), add $newCount new item(s) — $diffLabel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600),
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final error = await ref.read(saleExchangeProvider.notifier).saveExchange();
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(error, prefix: 'Error: ')), backgroundColor: Colors.red.shade700),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const AppIcon(AppIcons.checkCircleOutline, color: Colors.green, size: 48),
        title: const Text('Exchange Saved!'),
        content: const Text('Sale exchange saved successfully.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // dialog
              Navigator.pop(context); // exchange screen -> back to invoice picker
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
