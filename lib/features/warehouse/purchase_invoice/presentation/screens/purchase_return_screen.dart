import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/purchase_return_model.dart';
import '../../data/models/warehouse_stock_model.dart';
import '../providers/purchase_return_provider.dart';
import '../widgets/purchase_return_cart_table.dart';
import '../widgets/purchase_return_product_selector.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class PurchaseReturnScreen extends ConsumerWidget {
  const PurchaseReturnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseReturnProvider);
    final companiesAsync = ref.watch(returnCompaniesProvider);
    final invoicesAsync = ref.watch(returnInvoiceNumbersProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ─────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(AppIcons.keyboardReturn,
                        size: 18, color: Colors.orange.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Purchase Return',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Header card ────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                // Return Number
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Return Number :',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        state.returnLoading
                            ? const SizedBox(
                                width: 80,
                                child:
                                    LinearProgressIndicator(minHeight: 2))
                            : Text(
                                state.returnNumber.isEmpty
                                    ? '...'
                                    : state.returnNumber,
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange.shade700),
                              ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => ref
                              .read(purchaseReturnProvider.notifier)
                              .resetReturn(),
                          child: const AppIcon(AppIcons.refresh,
                              size: 17, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Company dropdown
                Expanded(
                  flex: 3,
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
                          .read(purchaseReturnProvider.notifier)
                          .selectCompany(c),
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: 'Company (optional)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.orange.shade200),
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
                            prefixIcon: AppIcon(AppIcons.search, size: 18),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Invoice reference dropdown (optional)
                Expanded(
                  flex: 3,
                  child: invoicesAsync.when(
                    loading: () => const SizedBox(
                        height: 48,
                        child: Center(child: LinearProgressIndicator())),
                    error: (e, _) => const SizedBox(),
                    data: (invoices) =>
                        DropdownButtonFormField<String>(
                      value: state.selectedInvoiceId,
                      hint: const Text('Ref Invoice (optional)',
                          style: TextStyle(fontSize: 12)),
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Colors.orange.shade200),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                            value: null,
                            child: Text('No Reference')),
                        ...invoices.map((inv) =>
                            DropdownMenuItem<String>(
                              value: inv['id'],
                              child: Text(inv['label'] ?? '',
                                  style:
                                      const TextStyle(fontSize: 12)),
                            )),
                      ],
                      onChanged: (id) {
                        final label = id == null
                            ? null
                            : invoices
                                .firstWhere((i) => i['id'] == id,
                                    orElse: () => {})['label'];
                        ref
                            .read(purchaseReturnProvider.notifier)
                            .selectInvoice(id, label);
                      },
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
          const PurchaseReturnProductSelector(),
          const SizedBox(height: 12),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const PurchaseReturnCartTable(),
            ),
          ),

          const SizedBox(height: 12),
          _ReturnFooter(),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

// ── Return footer ─────────────────────────────────────────────────────────

class _ReturnFooter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseReturnProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          _stat('Sub Total', state.totalAmount.toStringAsFixed(0)),
          const SizedBox(width: 28),
          _stat('Discount',
              '- ${state.totalDiscount.toStringAsFixed(0)}',
              color: Colors.orange.shade700),
          const SizedBox(width: 28),
          _stat('Items', '${state.cartItems.length}',
              color: Colors.blue.shade700),
          const Spacer(),

          // Net Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Net Return Amount',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                state.netAmount.toStringAsFixed(0),
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange.shade700),
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Clear
          OutlinedButton.icon(
            icon: const AppIcon(AppIcons.clearAll, size: 18),
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
                : () =>
                    ref.read(purchaseReturnProvider.notifier).clearCart(),
          ),
          const SizedBox(width: 10),

          // Save Return
          FilledButton.icon(
            icon: state.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const AppIcon(AppIcons.keyboardReturn, size: 18),
            label: const Text('Save Return'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: state.isSaving || state.cartItems.isEmpty
                ? null
                : () => _onSaveReturn(context, ref),
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

  Future<void> _onSaveReturn(BuildContext context, WidgetRef ref) async {
    final state = ref.read(purchaseReturnProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            AppIcon(AppIcons.keyboardReturn,
                color: Colors.orange.shade700, size: 22),
            const SizedBox(width: 8),
            const Text('Confirm Return',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.selectedInvoiceNumber != null)
              _dialogRow(
                  'Ref Invoice', state.selectedInvoiceNumber!),
            if (state.selectedCompany != null)
              _dialogRow('Company', state.selectedCompany!.label),
            _dialogRow('Items', '${state.cartItems.length}'),
            _dialogRow('Total Qty', '${state.totalQuantity}'),
            const Divider(height: 16),
            _dialogRow(
                'Sub Total', state.totalAmount.toStringAsFixed(0)),
            _dialogRow('Discount',
                '- ${state.totalDiscount.toStringAsFixed(0)}',
                color: Colors.orange.shade700),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net Return',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  'PKR ${state.netAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.orange.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Stock info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  AppIcon(AppIcons.infoOutline,
                      size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stock will be decreased and cash will be added back to warehouse.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
            // Company balance info
            if (state.selectedCompany != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    AppIcon(AppIcons.accountBalanceWalletOutlined,
                        size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PKR ${state.netAmount.toStringAsFixed(0)} will be deducted from ${state.selectedCompany!.label}\'s balance.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final err =
        await ref.read(purchaseReturnProvider.notifier).saveReturn();

    // Reload counter
    ref.read(cashCounterProvider.notifier).load();

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
        title: const Text('Return Saved!'),
        content: const Text(
            'Stock decreased and cash added back to warehouse.'),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700),
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(purchaseReturnProvider.notifier)
                  .resetReturn();
            },
            child: const Text('New Return'),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}
