import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/purchase_invoice_model.dart';
import '../../data/models/purchase_return_model.dart';
import '../../data/models/warehouse_stock_model.dart';
import '../providers/purchase_invoice_provider.dart';
import '../widgets/purchase_cart_table.dart';
import '../widgets/purchase_product_selector.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
class PurchaseInvoiceScreen extends ConsumerWidget {
  const PurchaseInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseInvoiceProvider);
    final companiesAsync = ref.watch(purchaseCompaniesProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Purchase Invoice',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
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
                // Invoice Number
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Invoice Number :',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        state.invoiceLoading
                            ? const SizedBox(
                                width: 80,
                                child: LinearProgressIndicator(minHeight: 2))
                            : Text(
                                state.invoiceNumber.isEmpty
                                    ? '...'
                                    : state.invoiceNumber,
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary),
                              ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => ref
                              .read(purchaseInvoiceProvider.notifier)
                              .resetInvoice(),
                          child: const AppIcon(AppIcons.refresh,
                              size: 17, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),

                // Company dropdown
                Expanded(
                  flex: 4,
                  child: companiesAsync.when(
                    loading: () => const SizedBox(
                        height: 48,
                        child: Center(child: LinearProgressIndicator())),
                    error: (e, _) => Text('Error: $e',
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12)),
                    data: (companies) => DropdownSearch<StockLookupItem>(
                      items: (filter, _) => companies
                          .where((c) => c.label
                              .toLowerCase()
                              .contains(filter.toLowerCase()))
                          .toList(),
                      selectedItem: state.selectedCompany,
                      itemAsString: (c) => c.label,
                      compareFn: (a, b) => a.id == b.id,
                      onSelected: (c) => ref
                          .read(purchaseInvoiceProvider.notifier)
                          .selectCompany(c),
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: 'Select Company',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        constraints: const BoxConstraints(maxHeight: 260),
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search company...',
                            prefixIcon: TextFieldIcon(AppIcons.search, size: 24),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Date',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text(_formatDate(DateTime.now()),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const PurchaseProductSelector(),
          const SizedBox(height: 12),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const PurchaseCartTable(),
            ),
          ),

          const SizedBox(height: 12),
          _InvoiceFooter(),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

// ── Invoice footer ────────────────────────────────────────────────────────

class _InvoiceFooter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseInvoiceProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _stat('Sub Total', state.totalAmount.toStringAsFixed(0)),
          const SizedBox(width: 28),
          _stat('Discount',
              '- ${state.totalDiscount.toStringAsFixed(0)}',
              color: Colors.orange.shade700),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Net Amount',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                state.netAmount.toStringAsFixed(0),
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: state.cartItems.isEmpty
                ? null
                : () =>
                    ref.read(purchaseInvoiceProvider.notifier).clearCart(),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            icon: state.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const AppIcon(AppIcons.receiptLong, size: 18),
            label: const Text('Purchase Invoice'),
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: state.isSaving || state.cartItems.isEmpty
                ? null
                : () => _onPurchaseInvoiceTap(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.black87)),
      ],
    );
  }

  void _onPurchaseInvoiceTap(BuildContext context, WidgetRef ref) {
    final state = ref.read(purchaseInvoiceProvider);

    if (state.selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              AppIcon(AppIcons.warningAmberRounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Please select a company first'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    _showPaymentDialog(context, ref);
  }

  Future<void> _showPaymentDialog(
      BuildContext context, WidgetRef ref) async {
    final state = ref.read(purchaseInvoiceProvider);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PaymentDialog(
        invoiceState: state,
        onConfirm: (paid, credit, mode) async {
          final repo = ref.read(purchaseInvoiceRepositoryProvider);
          final err = await ref
              .read(purchaseInvoiceProvider.notifier)
              .saveInvoice(
                paidAmount: paid,
                creditAmount: credit,
                paymentMode: mode,
                repo: repo,
              );

          // Reload counter
          ref.read(purchaseCashCounterProvider.notifier).load();

          if (!context.mounted) return;
          if (err != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error: $err'),
                  backgroundColor: Colors.red),
            );
            return;
          }

          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              icon: const AppIcon(AppIcons.checkCircleOutline,
                  color: Colors.green, size: 48),
              title: const Text('Invoice Saved!'),
              content:
                  const Text('Purchase invoice saved successfully.'),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref
                        .read(purchaseInvoiceProvider.notifier)
                        .resetInvoice();
                  },
                  child: const Text('New Invoice'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Payment dialog ────────────────────────────────────────────────────────

class _PaymentDialog extends ConsumerStatefulWidget {
  final PurchaseInvoiceState invoiceState;
  final Future<void> Function(double paid, double credit, String mode)
      onConfirm;

  const _PaymentDialog(
      {required this.invoiceState, required this.onConfirm});

  @override
  ConsumerState<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<_PaymentDialog> {
  late TextEditingController _customerNameCtrl;
  late TextEditingController _payCtrl;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _customerNameCtrl = TextEditingController(
        text: widget.invoiceState.selectedCompany?.label ?? '');
    _payCtrl = TextEditingController(
        text: widget.invoiceState.netAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _payCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceState = widget.invoiceState;
    final company = invoiceState.selectedCompany;
    final totalAmount = invoiceState.netAmount;

    final counter = ref.watch(purchaseCashCounterProvider);
    final cashAmount = counter?.netAmount ?? 0;

    final companyData = company != null
        ? ref.watch(companyBalanceProvider(company.id))
        : null;
    final openingBalance = companyData?.openingBalance ?? 0;

    final payEntered = double.tryParse(_payCtrl.text) ?? 0;
    final canPay = cashAmount >= totalAmount;

    final effectivePay =
        canPay ? payEntered.clamp(0, cashAmount).toDouble() : 0.0;
    final remaining = totalAmount - effectivePay;

    final String paymentMode;
    if (effectivePay <= 0) {
      paymentMode = 'credit';
    } else if (remaining > 0) {
      paymentMode = 'partial';
    } else {
      paymentMode = 'cash';
    }

    final primary = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      title: Row(
        children: [
          AppIcon(AppIcons.receiptLong, color: primary, size: 22),
          const SizedBox(width: 8),
          const Text('Purchase Invoice',
              style:
                  TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 20),

            _fieldRow(
              label: 'Customer Name',
              icon: AppIcons.personOutline,
              child: TextField(
                controller: _customerNameCtrl,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                decoration: _inputDeco(context, 'Enter customer name'),
              ),
            ),
            const SizedBox(height: 12),

            _fieldRow(
              label: 'Opening Balance',
              icon: AppIcons.accountBalanceWalletOutlined,
              child: _readOnlyField(
                value: 'PKR ${openingBalance.toStringAsFixed(0)}',
                color: openingBalance > 0
                    ? Colors.orange.shade700
                    : Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 12),

            _fieldRow(
              label: 'Cash in Hand',
              icon: AppIcons.paymentsOutlined,
              child: _readOnlyField(
                value: 'PKR ${cashAmount.toStringAsFixed(0)}',
                color: cashAmount > 0
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),

            _fieldRow(
              label: 'Total Amount',
              icon: AppIcons.shoppingBagOutlined,
              child: _readOnlyField(
                value: 'PKR ${totalAmount.toStringAsFixed(0)}',
                color: Colors.black87,
                bold: true,
              ),
            ),
            const SizedBox(height: 12),

            _fieldRow(
              label: 'Pay Amount',
              icon: AppIcons.paymentsOutlined,
              child: canPay
                  ? TextField(
                      controller: _payCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primary),
                      decoration: _inputDeco(context, '0'),
                      onChanged: (_) => setState(() {}),
                    )
                  : _readOnlyField(
                      value: 'PKR 0',
                      color: Colors.red.shade700,
                    ),
            ),
            const SizedBox(height: 12),

            _fieldRow(
              label: 'Remaining',
              icon: AppIcons.pendingOutlined,
              child: _readOnlyField(
                value: 'PKR ${remaining.toStringAsFixed(0)}',
                color: remaining > 0
                    ? Colors.orange.shade700
                    : Colors.green.shade700,
                bold: true,
              ),
            ),

            const SizedBox(height: 14),

            if (!canPay)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    AppIcon(AppIcons.warningAmberRounded,
                        color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cash in hand (PKR ${cashAmount.toStringAsFixed(0)}) is insufficient. '
                        'Full amount will be added to company balance.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 20),

            // Summary chips
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _chip(
                    label: 'Cash Pay',
                    value: 'PKR ${effectivePay.toStringAsFixed(0)}',
                    color: Colors.green.shade700,
                    icon: AppIcons.paymentsOutlined,
                  ),
                  Container(
                      width: 1,
                      height: 36,
                      color: Colors.grey.shade300),
                  _chip(
                    label: 'On Credit',
                    value: 'PKR ${remaining.toStringAsFixed(0)}',
                    color: Colors.orange.shade700,
                    icon: AppIcons.creditCardOutlined,
                  ),
                  Container(
                      width: 1,
                      height: 36,
                      color: Colors.grey.shade300),
                  _chip(
                    label: 'Mode',
                    value: paymentMode.toUpperCase(),
                    color: primary,
                    icon: AppIcons.receiptOutlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isProcessing
              ? null
              : () async {
                  setState(() => _isProcessing = true);
                  Navigator.pop(context);
                  await widget.onConfirm(
                      effectivePay, remaining, paymentMode);
                },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Confirm & Save'),
        ),
      ],
    );
  }

  Widget _fieldRow({
    required String label,
    required String icon,
    required Widget child,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Row(
            children: [
              AppIcon(icon, size: 15, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey)),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _readOnlyField(
      {required String value, Color? color, bool bold = false}) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          color: color ?? Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _inputDeco(BuildContext context, String hint) =>
      InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
      );

  Widget _chip({
    required String label,
    required String value,
    required Color color,
    required String icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 14, color: color),
        const SizedBox(height: 3),
        Text(label,
            style:
                TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        const SizedBox(height: 1),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }
}
