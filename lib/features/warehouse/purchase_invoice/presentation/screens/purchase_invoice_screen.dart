import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/warehouse_stock_model.dart';
import '../providers/purchase_invoice_provider.dart';
import '../widgets/purchase_cart_table.dart';
import '../widgets/purchase_product_selector.dart';

class PurchaseInvoiceScreen extends ConsumerWidget {
  const PurchaseInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseInvoiceProvider);
    final companiesAsync = ref.watch(purchaseCompaniesProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page title ────────────────────────────────────────────────
          const Text(
            'Purchase Invoice',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),

          // ── Invoice header card ───────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                    color: theme.colorScheme.primary),
                              ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => ref
                              .read(purchaseInvoiceProvider.notifier)
                              .resetInvoice(),
                          child: const Icon(Icons.refresh,
                              size: 17, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),

                // Company dropdown (AppSearchDropdown style)
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
                        constraints:
                            const BoxConstraints(maxHeight: 260),
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search company...',
                            prefixIcon: Icon(Icons.search, size: 18),
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
                    Text(
                      _formatDate(DateTime.now()),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Product selector ──────────────────────────────────────────
          const PurchaseProductSelector(),

          const SizedBox(height: 12),

          // ── Cart table ────────────────────────────────────────────────
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

          // ── Footer ───────────────────────────────────────────────────
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
          _stat(
            'Discount',
            '- ${state.totalDiscount.toStringAsFixed(0)}',
            color: Colors.orange.shade700,
          ),
          const Spacer(),
          // Net amount
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
          // Clear
          OutlinedButton.icon(
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: state.cartItems.isEmpty
                ? null
                : () => ref
                    .read(purchaseInvoiceProvider.notifier)
                    .clearCart(),
          ),
          const SizedBox(width: 10),
          // Save
          FilledButton.icon(
            icon: state.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save Invoice'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed:
                state.isSaving || state.cartItems.isEmpty
                    ? null
                    : () => _saveInvoice(context, ref),
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
        Text(
          value,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.black87),
        ),
      ],
    );
  }

  Future<void> _saveInvoice(BuildContext context, WidgetRef ref) async {
    final err =
        await ref.read(purchaseInvoiceProvider.notifier).saveInvoice();
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
        icon: const Icon(Icons.check_circle_outline,
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
  }
}
