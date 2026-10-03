import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
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

    if (state.originalInvoiceLoading || state.originalInvoice == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final invoice = state.originalInvoice!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Exchange header card ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                _headerField(
                  'Exchange Number :',
                  state.numberLoading
                      ? const SizedBox(
                          width: 80,
                          child: LinearProgressIndicator(minHeight: 2),
                        )
                      : Text(
                          state.exchangeNumber.isEmpty
                              ? '...'
                              : state.exchangeNumber,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                ),
                const SizedBox(width: 24),
                _headerField(
                  'Original Invoice :',
                  Text(
                    invoice.invoiceNumber,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                _headerField(
                  'Customer :',
                  Text(
                    invoice.customerName ?? '—',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(width: 24),

                // Payment type toggle — sirf tab jab paisa lena/dena ho
                if (state.differenceAmount != 0)
                  _PaymentTypeToggle(
                    value: state.paymentType,
                    onChanged: ref
                        .read(saleExchangeProvider.notifier)
                        .selectPaymentType,
                  ),
                const Spacer(),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Salesman / Printer / Bank / Cash ─────────────────────────
          const _ExchangeMetaRow(),

          const SizedBox(height: 8),

          // ── Wapas aane wale items (lambi list ho to scroll) ──────────
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 190),
            child: const SingleChildScrollView(
              child: SaleExchangeReturnItemsPicker(),
            ),
          ),

          const SizedBox(height: 8),
          SaleProductSelector(
            buttonLabel: 'Add New Item',
            onAdd: (ref, stock, qty) => ref
                .read(saleExchangeProvider.notifier)
                .addNewCartItem(stock, quantity: qty),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const SaleExchangeNewCartTable(),
            ),
          ),

          const SizedBox(height: 12),
          const _ExchangeFooter(),
        ],
      ),
    );
  }

  Widget _headerField(String label, Widget value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          value,
        ],
      );

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ── Payment type toggle (cash / card / cash + card) ─────────────────────

class _PaymentTypeToggle extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _PaymentTypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _seg('Cash', 'cash', AppIcons.paymentsOutlined, primary),
        _seg('Card', 'card', AppIcons.creditCardOutlined, primary),
        _seg('Cash + Card', 'cash_card', AppIcons.syncAlt, primary),
      ]),
    );
  }

  Widget _seg(String label, String type, String icon, Color primary) {
    final selected = value == type;
    return InkWell(
      onTap: () => onChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(children: [
          AppIcon(icon, size: 16, color: selected ? Colors.white : Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey.shade700)),
        ]),
      ),
    );
  }
}

// ── Salesman / Printer / Bank / Cash row ────────────────────────────────

class _ExchangeMetaRow extends ConsumerStatefulWidget {
  const _ExchangeMetaRow();

  @override
  ConsumerState<_ExchangeMetaRow> createState() => _ExchangeMetaRowState();
}

class _ExchangeMetaRowState extends ConsumerState<_ExchangeMetaRow> {
  final _cashAmountCtrl = TextEditingController();

  @override
  void dispose() {
    _cashAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleExchangeProvider);
    final notifier = ref.read(saleExchangeProvider.notifier);
    final salesmenAsync = ref.watch(salesmenProvider);
    final printersAsync = ref.watch(printersForSaleProvider);
    final bankAsync = ref.watch(bankEntriesForSaleProvider);

    final hasPayment = state.differenceAmount != 0;
    final showBank = hasPayment &&
        (state.paymentType == 'card' || state.paymentType == 'cash_card');
    final showCash = hasPayment && state.paymentType == 'cash_card';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: salesmenAsync.when(
              loading: () => const _FieldLoading(),
              error: (e, _) => Text('Error: $e', style: const TextStyle(fontSize: 11, color: Colors.red)),
              data: (list) => DropdownSearch<EmployeeLookupItem>(
                items: (f, _) => list.where((e) => e.name.toLowerCase().contains(f.toLowerCase())).toList(),
                selectedItem: state.salesman,
                itemAsString: (e) => e.name,
                compareFn: (a, b) => a.id == b.id,
                onSelected: notifier.selectSalesman,
                decoratorProps: DropDownDecoratorProps(decoration: _decor('Salesman', required: true)),
                popupProps: const PopupProps.menu(showSearchBox: true, constraints: BoxConstraints(maxHeight: 260)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: printersAsync.when(
              loading: () => const _FieldLoading(),
              error: (e, _) => Text('Error: $e', style: const TextStyle(fontSize: 11, color: Colors.red)),
              data: (list) => DropdownSearch<PrinterLookupItem>(
                items: (f, _) => list.where((e) => e.label.toLowerCase().contains(f.toLowerCase())).toList(),
                selectedItem: state.printer,
                itemAsString: (e) => e.label,
                compareFn: (a, b) => a.id == b.id,
                onSelected: notifier.selectPrinter,
                decoratorProps: DropDownDecoratorProps(decoration: _decor('Printer', required: true)),
                popupProps: const PopupProps.menu(showSearchBox: true, constraints: BoxConstraints(maxHeight: 260)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: showBank
                ? bankAsync.when(
                    loading: () => const _FieldLoading(),
                    error: (e, _) => Text('Error: $e', style: const TextStyle(fontSize: 11, color: Colors.red)),
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
                          showSearchBox: true, constraints: BoxConstraints(maxHeight: 260)),
                    ),
                  )
                : const SizedBox(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: showCash
                ? TextField(
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
        ],
      ),
    );
  }

  InputDecoration _decor(String label, {bool required = false}) => InputDecoration(
        labelText: required ? '$label *' : label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      );
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saleExchangeProvider);

    final canSave = !state.isSaving &&
        state.returnCartItems.any((i) => i.quantity > 0) &&
        state.newCartItems.isNotEmpty;
    final canClear = state.returnCartItems.any((i) => i.quantity > 0) || state.newCartItems.isNotEmpty;

    final Color diffColor;
    final String diffLabel;
    if (state.isCollect) {
      diffColor = Colors.green.shade700;
      diffLabel = 'Collect';
    } else if (state.isRefund) {
      diffColor = Colors.red.shade700;
      diffLabel = 'Refund';
    } else {
      diffColor = Colors.grey.shade600;
      diffLabel = 'Even Exchange';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _stat('Return Total', '- ${state.returnTotal.toStringAsFixed(0)}', color: Colors.red.shade700),
          const SizedBox(width: 28),
          _stat('New Total', state.newTotal.toStringAsFixed(0), color: Colors.green.shade700),
          const SizedBox(width: 28),
          Expanded(
            child: TextField(
              onChanged: (v) => ref.read(saleExchangeProvider.notifier).setNote(v),
              decoration: InputDecoration(
                hintText: 'Note (optional)',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(diffLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                state.absDifference.toStringAsFixed(0),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: diffColor),
              ),
            ],
          ),
          const SizedBox(width: 20),
          OutlinedButton.icon(
            icon: const AppIcon(AppIcons.clearAll, size: 18),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: canClear
                ? () {
                    final n = ref.read(saleExchangeProvider.notifier);
                    for (final i in ref.read(saleExchangeProvider).returnCartItems) {
                      if (i.quantity > 0) n.setReturnQuantity(i.originalItemId, 0);
                    }
                    for (final i in List.of(ref.read(saleExchangeProvider).newCartItems)) {
                      n.removeNewItem(i.branchStockId);
                    }
                  }
                : null,
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            icon: state.isSaving
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const AppIcon(AppIcons.swapHoriz, size: 18),
            label: const Text('Save Exchange'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: canSave ? () => _onSaveTap(context, ref) : null,
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color ?? Colors.black87)),
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
        SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red.shade700),
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
