import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/widget/app_icon.dart';
import '../../../../superadmin/report/presentation/widgets/report_table_shell.dart';
import '../providers/sale_claim_provider.dart';
import '../widgets/new_sale_claim_dialog.dart';
import '../widgets/sale_claim_common.dart';

/// Branch ke Sale Claims — customer ki kharab nikli product ka Head Office
/// ke naam claim. Approve hone par branch stock se minus hota hai.
class SaleClaimsScreen extends ConsumerWidget {
  const SaleClaimsScreen({super.key});

  static const _accent = Color(0xFFE56A00);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimsAsync = ref.watch(branchSaleClaimsProvider);
    final claims = claimsAsync.value ?? const [];
    final pending = claims.where((c) => c.isPending).length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(AppIcons.warningAmberOutlined,
                  color: _accent, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sale Claims',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Total: ${claims.length}  ·  Pending: $pending',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              IconButton(
                icon: const AppIcon(AppIcons.refresh, size: 18),
                tooltip: 'Refresh',
                onPressed: () => ref.invalidate(branchSaleClaimsProvider),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _accent),
                icon: const AppIcon(AppIcons.add, size: 18, color: Colors.white),
                label: const Text('New Claim'),
                onPressed: () async {
                  final saved = await showDialog<bool>(
                    context: context,
                    builder: (_) => const NewSaleClaimDialog(),
                  );
                  if (saved == true) {
                    ref.invalidate(branchSaleClaimsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Claim sent to Head Office'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: claimsAsync.isLoading && !claimsAsync.hasValue
                ? const Center(child: CircularProgressIndicator())
                : claimsAsync.hasError && !claimsAsync.hasValue
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Error: ${claimsAsync.error}',
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () =>
                                  ref.invalidate(branchSaleClaimsProvider),
                              icon: const AppIcon(AppIcons.refresh, size: 16),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : claims.isEmpty
                        ? Center(
                            child: Text('No claims yet',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 15)),
                          )
                        : ReportTableShell(
                            columns: const [
                              DataColumn(label: Text('Claim No')),
                              DataColumn(label: Text('Invoice')),
                              DataColumn(label: Text('Customer')),
                              DataColumn(label: Text('Product')),
                              DataColumn(label: Text('Size')),
                              DataColumn(label: Text('Color')),
                              DataColumn(label: Text('Qty'), numeric: true),
                              DataColumn(label: Text('Sale Date')),
                              DataColumn(label: Text('Claim Date')),
                              DataColumn(label: Text('Reason')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('HO Remarks')),
                            ],
                            rows: [
                              for (final c in claims)
                                DataRow(cells: [
                                  DataCell(Text(c.claimNumber,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'monospace',
                                          color: _accent))),
                                  DataCell(Text(c.invoiceNumber ?? '—')),
                                  DataCell(Text(c.customerName ?? '—')),
                                  DataCell(Text(claimProductLabel(c))),
                                  DataCell(Text(c.sizeName ?? '—')),
                                  DataCell(Text(c.colorName ?? '—')),
                                  DataCell(Text('${c.quantity}')),
                                  DataCell(Text(claimFmtDate(c.saleDate))),
                                  DataCell(Text(claimFmtDate(c.claimDate))),
                                  DataCell(SaleClaimTextCell(c.reason)),
                                  DataCell(SaleClaimStatusChip(c.status)),
                                  DataCell(SaleClaimTextCell(c.reviewRemarks)),
                                ]),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
