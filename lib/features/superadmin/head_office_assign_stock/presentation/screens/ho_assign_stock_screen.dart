import 'package:flutter/material.dart';
import 'package:safishoe_app/core/widget/invoice_page_body.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/current_head_office_provider.dart';
import '../providers/ho_assign_stock_provider.dart';
import '../widgets/ho_assign_cart_table.dart';
import '../widgets/ho_assign_product_selector.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/utils/responsive.dart';
import 'package:safishoe_app/core/service/print/print_service.dart';
/// SuperAdmin — Head Office se Branch ko stock assign karna (form only).
/// History ab alag sidebar item hai ([HoAssignStockListScreen]).
/// Warehouse ke "Assign Stock to Branch" jaisa hi, bas source head office
/// ka stock_inventory hai aur record par assigned_by = head office id save hota hai.
class HoAssignStockScreen extends StatelessWidget {
  const HoAssignStockScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AssignStockTab();
}

class _AssignStockTab extends ConsumerWidget {
  const _AssignStockTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hoAssignStockProvider);

    return InvoicePageBody(
        top: [
          const Row(
            children: [
              AppIcon(AppIcons.localShippingOutlined,
                  color: Color(0xFF1565C0), size: 24),
              SizedBox(width: 8),
              Text(
                'Assign Stock to Branch',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Builder(builder: (context) {
            final assignmentNoWidget = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Assignment No :',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    state.numberLoading
                        ? const SizedBox(
                            width: 100,
                            child: LinearProgressIndicator(minHeight: 2))
                        : Text(
                            state.assignmentNumber.isEmpty
                                ? '...'
                                : state.assignmentNumber,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1565C0)),
                          ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => ref
                          .read(hoAssignStockProvider.notifier)
                          .resetAssignment(),
                      child: const AppIcon(AppIcons.refresh,
                          size: 17, color: Colors.red),
                    ),
                  ],
                ),
              ],
            );

            final dateWidget = Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Date',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text(_formatDate(DateTime.now()),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            );

            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: assignmentNoWidget),
                  const SizedBox(width: 12),
                  dateWidget,
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          const HoAssignProductSelector(),
          const SizedBox(height: 12),
        ],
        cart: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const HoAssignCartTable(),
        ),
        bottom: const [
          SizedBox(height: 12),
          _AssignFooter(),
        ],
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

/// Whole-rupee amount with thousands separators, e.g. 1875000 -> "1,875,000".
String _money(double v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

class _AssignFooter extends ConsumerWidget {
  const _AssignFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hoAssignStockProvider);
    const primary = Color(0xFF1565C0);
    final isMobile = Responsive(context).isMobile;

    final totalPairsCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Total Pairs',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(
          '${state.totalQuantity}',
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: primary),
        ),
      ],
    );

    final totalValueCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Total Purchase Value',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(
          'Rs. ${_money(state.totalPurchaseValue)}',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey.shade700),
        ),
      ],
    );

    final branchChip = state.selectedBranch != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(AppIcons.storeOutlined,
                  size: 16, color: Color(0xFF1565C0)),
              const SizedBox(width: 6),
              Text(
                state.selectedBranch!.label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          )
        : null;

    final clearButton = OutlinedButton.icon(
      icon: const AppIcon(AppIcons.clearAll, size: 18),
      label: const Text('Clear'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: state.cartItems.isEmpty
          ? null
          : () => ref.read(hoAssignStockProvider.notifier).clearCart(),
    );

    final submitFilledButton = FilledButton.icon(
      icon: const AppIcon(AppIcons.sendOutlined, size: 18),
      label: const Text('Add Assign Stock to Branch'),
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed:
          state.cartItems.isEmpty ? null : () => _onSend(context, ref),
    );
    final submitButtonDesktop = state.isSaving
        ? const SizedBox(
            width: 180,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        : submitFilledButton;
    final submitButtonMobile = state.isSaving
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
        : submitFilledButton;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    totalPairsCol,
                    totalValueCol,
                    if (branchChip != null) branchChip,
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: clearButton),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: submitButtonMobile),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                totalPairsCol,
                const SizedBox(width: 24),
                totalValueCol,
                const SizedBox(width: 24),
                if (branchChip != null) branchChip,
                const Spacer(),
                clearButton,
                const SizedBox(width: 12),
                submitButtonDesktop,
              ],
            ),
    );
  }

  Future<void> _onSend(BuildContext context, WidgetRef ref) async {
    final state = ref.read(hoAssignStockProvider);

    if (state.selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a branch first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Slip header: Safi Shoes logo + head office address/phone (no printer
    // picker, no confirm dialog).
    final contact = await ref
        .read(headOfficeContactProvider.future)
        .catchError((_) => (address: '', phone: ''));

    final branchName = state.selectedBranch?.branchName ?? 'branch';
    // Cart is cleared right after saving — keep what the slip needs.
    final slipLines = state.cartItems
        .map((i) => StockSlipLine(
              name: i.productName,
              sizeName: i.sizeName,
              colorName: i.colorName,
              quantity: i.quantity,
            ))
        .toList();
    final error =
        await ref.read(hoAssignStockProvider.notifier).saveAssignment();

    if (!context.mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const AppIcon(AppIcons.checkCircleOutline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Stock assigned to $branchName successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      final assignmentNumber =
          ref.read(hoAssignStockProvider).assignmentNumber;
      ref.read(hoAssignStockProvider.notifier).clearCart();
      ref.read(hoAssignListProvider.notifier).loadAssignments();
      ref.invalidate(hoAssignStockListProvider);

      try {
        await ThermalPrintService.printStockSlip(
          title: 'STOCK ASSIGNMENT',
          documentNumberLabel: 'Assignment #',
          documentNumber: assignmentNumber,
          date: DateTime.now(),
          fromName: 'Head Office',
          toName: branchName,
          lines: slipLines,
          address: contact.address,
          phone: contact.phone,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Print failed: $e'),
              backgroundColor: Colors.orange.shade700,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

