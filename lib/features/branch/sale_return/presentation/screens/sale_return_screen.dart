import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/service/print/print_service.dart';
import '../../../../superadmin/employee_salary/presentation/providers/employee_salary_providers.dart';
import '../../../customer/data/model/customer_model.dart';
import '../../../sale_invoice/data/model/sale_invoice_model.dart' show SaleInvoiceModel;
import '../../../sale_invoice/presentation/provider/sale_invoice_provider.dart'
    show bankEntriesForSaleProvider, customersForSaleProvider, printersForSaleProvider,
        salesmenProvider, saleInvoiceListProvider;
import '../../data/model/sale_return_model.dart';
import '../provider/sale_return_provider.dart';
import '../widgets/sale_return_cart_table.dart';
import '../widgets/sale_return_items_picker.dart';
import '../widgets/sale_return_product_selector.dart';

/// Sale Invoice screen ka mirror — structure bilkul wahi hai, sirf effect
/// vice versa: stock wapis add hota hai, cash counter se minus hota hai.
class SaleReturnScreen extends ConsumerWidget {
  const SaleReturnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saleReturnProvider);
    const accent = Colors.red;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Sale Return', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              if (state.originalInvoice != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Against ${state.originalInvoice!.invoiceNumber}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // ── Return header card ──────────────────────────────────────────
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
                    Text('Return Number :',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        state.numberLoading
                            ? const SizedBox(width: 80, child: LinearProgressIndicator(minHeight: 2))
                            : Text(
                                state.returnNumber.isEmpty ? '...' : state.returnNumber,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: accent),
                              ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => ref.read(saleReturnProvider.notifier).resetReturn(),
                          child: const Icon(Icons.refresh, size: 17, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),

                // Refund type toggle
                _RefundTypeToggle(
                  value: state.paymentType,
                  onChanged: (t) => ref.read(saleReturnProvider.notifier).selectPaymentType(t),
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

          // ── Printer / Bank / Cash amount ─────────────────────────────
          const _ReturnMetaRow(),

          const SizedBox(height: 12),

          if (state.originalInvoice != null) ...[
            if (state.originalInvoiceLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              const Expanded(child: SaleReturnItemsPicker()),
          ] else ...[
            const SaleReturnProductSelector(),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const SaleReturnCartTable(),
              ),
            ),
          ],

          const SizedBox(height: 12),
          const _ReturnFooter(),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ── Refund type toggle (cash / card / cash+card) ──────────────────────────

class _RefundTypeToggle extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _RefundTypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const accent = Colors.red;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _seg('Cash', 'cash', Icons.payments_outlined, accent),
        _seg('Card', 'card', Icons.credit_card_outlined, accent),
        _seg('Cash + Card', 'cash_card', Icons.sync_alt, accent),
      ]),
    );
  }

  Widget _seg(String label, String type, IconData icon, Color accent) {
    final selected = value == type;
    return InkWell(
      onTap: () => onChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
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

// ── Printer / Bank / Cash amount row ──────────────────────────────────────

class _ReturnMetaRow extends ConsumerStatefulWidget {
  const _ReturnMetaRow();

  @override
  ConsumerState<_ReturnMetaRow> createState() => _ReturnMetaRowState();
}

class _ReturnMetaRowState extends ConsumerState<_ReturnMetaRow> {
  final _cashAmountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(saleInvoiceListProvider.notifier).loadInvoices();
    });
  }

  @override
  void dispose() {
    _cashAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleReturnProvider);
    final notifier = ref.read(saleReturnProvider.notifier);
    final invoiceListState = ref.watch(saleInvoiceListProvider);
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
            child: invoiceListState.isLoading
                ? const _FieldLoading()
                : DropdownSearch<SaleInvoiceModel>(
                    items: (f, _) => invoiceListState.invoices
                        .where((inv) => inv.invoiceNumber.toLowerCase().contains(f.toLowerCase()))
                        .toList(),
                    selectedItem: state.originalInvoice,
                    itemAsString: (inv) => inv.invoiceNumber,
                    compareFn: (a, b) => a.id == b.id,
                    onSelected: (inv) {
                      if (inv != null) notifier.selectOriginalInvoice(inv);
                    },
                    decoratorProps: DropDownDecoratorProps(
                      decoration: _decor('Sale Invoice #').copyWith(
                        suffixIcon: state.originalInvoice != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                tooltip: 'Return without invoice',
                                onPressed: notifier.clearOriginalInvoice,
                              )
                            : null,
                      ),
                    ),
                    popupProps: const PopupProps.menu(showSearchBox: true, constraints: BoxConstraints(maxHeight: 260)),
                  ),
          ),
          const SizedBox(width: 16),
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
                decoratorProps: DropDownDecoratorProps(decoration: _decor('Printer')),
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

// ── Return footer ──────────────────────────────────────────────────────────

class _ReturnFooter extends ConsumerWidget {
  const _ReturnFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saleReturnProvider);
    const accent = Colors.red;

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
          const SizedBox(width: 28),
          Expanded(
            child: TextField(
              onChanged: (v) => ref.read(saleReturnProvider.notifier).setNote(v),
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
              const Text('Refund Amount', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                state.totalAmount.toStringAsFixed(0),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accent),
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
            onPressed: state.isInvoiceLinked || state.cartItems.isEmpty
                ? null
                : () => ref.read(saleReturnProvider.notifier).clearCart(),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            icon: state.isSaving
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.assignment_return_outlined, size: 18),
            label: const Text('Sale Return'),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed:
                state.isSaving || state.totalQuantity == 0 ? null : () => _onSaveTap(context, ref),
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
    final state = ref.read(saleReturnProvider);

    String? warning;
    if (state.paymentType == 'card' && state.bankEntry == null) {
      warning = 'Please select a bank account for card refund';
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
          Icon(Icons.assignment_return_outlined, color: Colors.red, size: 22),
          SizedBox(width: 8),
          Text('Confirm Sale Return', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: Text(
          'Refund Rs. ${state.totalAmount.toStringAsFixed(0)} '
          '(${state.totalQuantity} pairs, ${state.paymentType == 'cash_card' ? 'CASH Rs.${state.cashAmount.toStringAsFixed(0)} + CARD Rs.${state.cardAmount.toStringAsFixed(0)}' : state.paymentType.toUpperCase()})?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final printer = state.printer;
    final error = await ref.read(saleReturnProvider.notifier).saveReturn();

    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Return ne is salesman ki employee_salary total_sales_return badal di
    // hai (DB trigger se) — Branch Employee screen ki cached figures ko
    // taaza karne ke liye is provider ko invalidate karna zaroori hai.
    ref.invalidate(employeeSalariesForBranchProvider);

    final savedReturn = ref.read(saleReturnProvider).lastSavedReturn;
    if (savedReturn != null) {
      try {
        await ThermalPrintService.printSaleReturn(savedReturn, printer: printer);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Print failed: $e'), backgroundColor: Colors.orange.shade700),
          );
        }
      }
    }
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sale return saved successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    ref.read(saleReturnProvider.notifier).resetReturn();
  }
}
