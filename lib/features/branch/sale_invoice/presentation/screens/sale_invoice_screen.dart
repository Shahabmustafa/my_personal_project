import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../customer/data/model/customer_model.dart';
import '../../data/model/sale_invoice_model.dart';
import '../../data/sale_invoice_print/sale_invoice_print_service.dart';
import '../provider/sale_invoice_provider.dart';
import '../widgets/sale_cart_table.dart';
import '../widgets/sale_product_selector.dart';

class SaleInvoiceScreen extends ConsumerWidget {
  const SaleInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saleInvoiceProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sale Invoice', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),

          // ── Invoice header card ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Invoice Number :',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        state.invoiceLoading
                            ? const SizedBox(width: 80, child: LinearProgressIndicator(minHeight: 2))
                            : Text(
                                state.invoiceNumber.isEmpty ? '...' : state.invoiceNumber,
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: primary),
                              ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => ref.read(saleInvoiceProvider.notifier).resetInvoice(),
                          child: const Icon(Icons.refresh, size: 17, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),

                // Payment type toggle
                _SaleTypeToggle(
                  value: state.paymentType,
                  onChanged: (t) => ref.read(saleInvoiceProvider.notifier).selectPaymentType(t),
                ),
                const Spacer(),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Date', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text(_formatDate(DateTime.now()),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Salesman / Printer / Bank ─────────────────────────────────
          const _InvoiceMetaRow(),

          const SizedBox(height: 12),
          const SaleProductSelector(),
          const SizedBox(height: 12),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const SaleCartTable(),
            ),
          ),

          const SizedBox(height: 12),
          const _InvoiceFooter(),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ── Sale type toggle (cash / card) ────────────────────────────────────────

class _SaleTypeToggle extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _SaleTypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _seg('Cash', 'cash', Icons.payments_outlined, primary),
        _seg('Card', 'card', Icons.credit_card_outlined, primary),
        _seg('Cash + Card', 'cash_card', Icons.sync_alt, primary),
      ]),
    );
  }

  Widget _seg(String label, String type, IconData icon, Color primary) {
    final selected = value == type;
    return InkWell(
      onTap: () => onChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey.shade600),
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

// ── Salesman / Printer / Bank row ─────────────────────────────────────────
// Manager auto-resolve hota hai (branch ka jo bhi role='manager' hai) —
// isliye yahan koi manager dropdown nahi dikhaya jata.

class _InvoiceMetaRow extends ConsumerStatefulWidget {
  const _InvoiceMetaRow();

  @override
  ConsumerState<_InvoiceMetaRow> createState() => _InvoiceMetaRowState();
}

class _InvoiceMetaRowState extends ConsumerState<_InvoiceMetaRow> {
  final _cashAmountCtrl = TextEditingController();

  @override
  void dispose() {
    _cashAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleInvoiceProvider);
    final notifier = ref.read(saleInvoiceProvider.notifier);
    final customersAsync = ref.watch(customersForSaleProvider);
    final salesmenAsync = ref.watch(salesmenProvider);
    final printersAsync = ref.watch(printersForSaleProvider);
    final bankAsync = ref.watch(bankEntriesForSaleProvider);

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
            flex: 3,
            child: customersAsync.when(
              loading: () => const _FieldLoading(),
              error: (e, _) => Text('Error: $e', style: const TextStyle(fontSize: 11, color: Colors.red)),
              data: (list) {
                final active = list.where((c) => c.isActive).toList();
                return DropdownSearch<CustomerModel>(
                  items: (f, _) => active.where((c) => c.name.toLowerCase().contains(f.toLowerCase())).toList(),
                  selectedItem: state.customer,
                  itemAsString: (c) => c.name,
                  compareFn: (a, b) => a.id == b.id,
                  onSelected: notifier.selectCustomer,
                  decoratorProps: DropDownDecoratorProps(decoration: _decor('Customer', required: true)),
                  popupProps: const PopupProps.menu(showSearchBox: true, constraints: BoxConstraints(maxHeight: 260)),
                );
              },
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            flex: 3,
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
            flex: 3,
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

          if (state.paymentType == 'card' || state.paymentType == 'cash_card') ...[
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: bankAsync.when(
                loading: () => const _FieldLoading(),
                error: (e, _) => Text('Error: $e', style: const TextStyle(fontSize: 11, color: Colors.red)),
                data: (list) => DropdownSearch<BankEntryLookupItem>(
                  items: (f, _) => list.where((e) => e.label.toLowerCase().contains(f.toLowerCase())).toList(),
                  selectedItem: state.bankEntry,
                  itemAsString: (e) => e.label,
                  compareFn: (a, b) => a.id == b.id,
                  onSelected: notifier.selectBankEntry,
                  decoratorProps: DropDownDecoratorProps(
                      decoration: _decor('Bank Account', required: true)),
                  popupProps:
                      const PopupProps.menu(showSearchBox: true, constraints: BoxConstraints(maxHeight: 260)),
                ),
              ),
            ),
          ],

          if (state.paymentType == 'cash_card') ...[
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _cashAmountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) =>
                    notifier.setCashAmount(double.tryParse(v.trim()) ?? 0),
                decoration: _decor('Cash Amount *').copyWith(
                  helperText: 'Card: Rs. ${state.cardAmount.toStringAsFixed(0)}',
                  helperStyle: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
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
  Widget build(BuildContext context) =>
      const SizedBox(height: 48, child: Center(child: LinearProgressIndicator()));
}

// ── Invoice footer ────────────────────────────────────────────────────────

class _InvoiceFooter extends ConsumerStatefulWidget {
  const _InvoiceFooter();

  @override
  ConsumerState<_InvoiceFooter> createState() => _InvoiceFooterState();
}

class _InvoiceFooterState extends ConsumerState<_InvoiceFooter> {
  final _discountCtrl = TextEditingController();

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleInvoiceProvider);
    final theme = Theme.of(context);
    final allowDiscountAsync = ref.watch(currentBranchAllowsInvoiceDiscountProvider);
    final allowDiscount = allowDiscountAsync.value ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _stat('Sub Total', state.subtotal.toStringAsFixed(0)),
          const SizedBox(width: 28),
          _stat('Discount', '- ${state.totalDiscount.toStringAsFixed(0)}', color: Colors.orange.shade700),
          if (allowDiscount) ...[
            const SizedBox(width: 20),
            SizedBox(
              width: 130,
              child: TextField(
                controller: _discountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) =>
                    ref.read(saleInvoiceProvider.notifier).setInvoiceDiscount(double.tryParse(v.trim()) ?? 0),
                decoration: InputDecoration(
                  labelText: 'Extra Discount',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ],
          const SizedBox(width: 28),
          Expanded(
            child: TextField(
              onChanged: (v) => ref.read(saleInvoiceProvider.notifier).setNote(v),
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
              const Text('Net Amount', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                state.totalAmount.toStringAsFixed(0),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(width: 20),
          OutlinedButton.icon(
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: state.cartItems.isEmpty
                ? null
                : () => ref.read(saleInvoiceProvider.notifier).clearCart(),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            icon: state.isSaving
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.receipt_long, size: 18),
            label: const Text('Sale Invoice'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed:
                state.isSaving || state.cartItems.isEmpty ? null : () => _onSaveTap(context, ref),
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
    final state = ref.read(saleInvoiceProvider);

    String? warning;
    if (state.customer == null) {
      warning = 'Please select a customer';
    } else if (state.salesman == null) {
      warning = 'Please select a salesman';
    } else if (state.printer == null) {
      warning = 'Please select a printer';
    } else if (state.paymentType == 'card' && state.bankEntry == null) {
      warning = 'Please select a bank account for card sale';
    } else if (state.paymentType == 'cash_card') {
      if (state.bankEntry == null) {
        warning = 'Please select a bank account for the card portion';
      } else if (state.cashAmount <= 0 || state.cashAmount >= state.totalAmount) {
        warning = 'Enter a cash amount between 0 and the net amount';
      }
    }
    if (warning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.receipt_long, color: Colors.green, size: 22),
          SizedBox(width: 8),
          Text('Confirm Sale Invoice', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: Text(
          'Save this invoice for Rs. ${state.totalAmount.toStringAsFixed(0)} '
          '(${state.totalQuantity} pairs, ${state.paymentType == 'cash_card' ? 'CASH Rs.${state.cashAmount.toStringAsFixed(0)} + CARD Rs.${state.cardAmount.toStringAsFixed(0)}' : state.paymentType.toUpperCase()})?',
        ),
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

    final printerLabel = state.printer?.label;
    final error = await ref.read(saleInvoiceProvider.notifier).saveInvoice();
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red.shade700),
      );
      return;
    }

    final savedInvoice = ref.read(saleInvoiceProvider).lastSavedInvoice;
    if (savedInvoice != null) {
      try {
        await SaleInvoicePrintService.printInvoice(savedInvoice, shopName: printerLabel);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Print failed: $e'), backgroundColor: Colors.orange.shade700),
          );
        }
      }
    }
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
        title: const Text('Invoice Saved!'),
        content: const Text('Sale invoice saved successfully.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(saleInvoiceProvider.notifier).resetInvoice();
            },
            child: const Text('New Invoice'),
          ),
        ],
      ),
    );
  }
}
