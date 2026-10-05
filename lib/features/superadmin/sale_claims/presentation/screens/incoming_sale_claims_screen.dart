import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/widget/app_icon.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../branch/sale_claim/data/model/sale_claim_model.dart';
import '../../../../branch/sale_claim/presentation/providers/sale_claim_provider.dart';
import '../../../../branch/sale_claim/presentation/widgets/sale_claim_common.dart';
import '../../../report/presentation/widgets/report_summary_card.dart';
import '../../../report/presentation/widgets/report_detail_panel.dart';

/// Head Office ki screen: branches ke sale claims approve/reject karna.
/// Approve par branch stock se claim ki quantity minus ho jati hai
/// (approve_sale_claim RPC); reject par stock ko kuch nahi hota.
class IncomingSaleClaimsScreen extends ConsumerStatefulWidget {
  const IncomingSaleClaimsScreen({super.key});

  @override
  ConsumerState<IncomingSaleClaimsScreen> createState() =>
      _IncomingSaleClaimsScreenState();
}

class _IncomingSaleClaimsScreenState
    extends ConsumerState<IncomingSaleClaimsScreen> {
  static const _accent = Color(0xFFE56A00);

  String _filterStatus = 'all'; // all | pending | approved | rejected
  String? _busyId;

  @override
  Widget build(BuildContext context) {
    final claimsAsync = ref.watch(incomingSaleClaimsProvider);
    final all = claimsAsync.value ?? const <SaleClaimModel>[];
    final filtered = _filterStatus == 'all'
        ? all
        : all.where((c) => c.status == _filterStatus).toList();

    int count(String s) => all.where((c) => c.status == s).length;
    final approvedPairs = all
        .where((c) => c.status == 'approved')
        .fold<int>(0, (s, c) => s + c.quantity);

    final cards = [
      ReportSummaryCard(
        label: 'Total Claims',
        value: '${all.length}',
        icon: AppIcons.warningAmberOutlined,
        color: const Color(0xFF1565C0),
      ),
      ReportSummaryCard(
        label: 'Pending',
        value: '${count('pending')}',
        icon: AppIcons.hourglassEmptyOutlined,
        color: _accent,
      ),
      ReportSummaryCard(
        label: 'Approved',
        value: '${count('approved')}',
        icon: AppIcons.checkCircleOutline,
        color: const Color(0xFF22A06B),
      ),
      ReportSummaryCard(
        label: 'Pairs Removed From Stock',
        value: '$approvedPairs',
        icon: AppIcons.inventory2Outlined,
        color: const Color(0xFF6A1B9A),
      ),
    ];

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
              const Expanded(
                child: Text('Branch Sale Claims',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const AppIcon(AppIcons.refresh, size: 18),
                tooltip: 'Refresh',
                onPressed: () => ref.invalidate(incomingSaleClaimsProvider),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (ctx, c) {
              final w = c.maxWidth;
              final cols = w > 900 ? 4 : w > 560 ? 2 : 1;
              const gap = 14.0;
              final cardW = (w - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final card in cards) SizedBox(width: cardW, child: card),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', 'all', all.length),
                const SizedBox(width: 8),
                _filterChip('Pending', 'pending', count('pending')),
                const SizedBox(width: 8),
                _filterChip('Approved', 'approved', count('approved')),
                const SizedBox(width: 8),
                _filterChip('Rejected', 'rejected', count('rejected')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: claimsAsync.isLoading && !claimsAsync.hasValue
                ? const Center(child: CircularProgressIndicator())
                : claimsAsync.hasError && !claimsAsync.hasValue
                    ? Center(
                        child: Text('Error: ${claimsAsync.error}',
                            style: const TextStyle(color: Colors.red)),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              _filterStatus == 'all'
                                  ? 'No claims received yet'
                                  : 'No claims match this filter',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 15),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) => _claimTile(filtered[i]),
                          ),
          ),
        ],
      ),
    );
  }

  /// Ek claim — band halat mein number, branch, product aur status; kholne
  /// par invoice, customer, dates, reason aur remarks.
  Widget _claimTile(SaleClaimModel c) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey(c.id),
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(c.claimNumber,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: _accent)),
            Text(c.branchName ?? '—',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            SaleClaimStatusChip(c.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${claimProductLabel(c)} · Qty ${c.quantity} · ${claimFmtDate(c.claimDate)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actions(c),
            const AppIcon(AppIcons.arrowDropDown, size: 20, color: Color(0xFF8A8FA3)),
          ],
        ),
        children: [
          const DetailDivider(),
          DetailKV('Invoice', c.invoiceNumber ?? '—'),
          DetailKV('Customer', c.customerName ?? '—'),
          DetailKV('Product', claimProductLabel(c)),
          DetailKV('Size', c.sizeName ?? '—'),
          DetailKV('Color', c.colorName ?? '—'),
          DetailKV('Quantity', '${c.quantity}'),
          DetailKV('Sale Date', claimFmtDate(c.saleDate)),
          DetailKV('Claim Date', claimFmtDate(c.claimDate)),
          _longKV('Reason', c.reason),
          _longKV('Remarks', c.reviewRemarks),
        ],
      ),
    );
  }

  /// Lamba text (reason/remarks) — label upar, value neeche wrap ho kar.
  Widget _longKV(String label, String? value) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3))),
            const SizedBox(height: 2),
            Text((value ?? '').isEmpty ? '—' : value!,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D3A))),
          ],
        ),
      );

  Widget _actions(SaleClaimModel c) {
    if (!c.isPending) return const SizedBox.shrink();
    if (_busyId == c.id) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: AppIcon(AppIcons.checkCircleOutline,
              size: 19, color: Colors.green.shade600),
          tooltip: 'Approve',
          onPressed: () => _review(c, approve: true),
        ),
        IconButton(
          icon: AppIcon(AppIcons.cancelOutlined,
              size: 19, color: Colors.red.shade600),
          tooltip: 'Reject',
          onPressed: () => _review(c, approve: false),
        ),
      ],
    );
  }

  Future<void> _review(SaleClaimModel c, {required bool approve}) async {
    final remarksCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            AppIcon(
              approve ? AppIcons.checkCircleOutline : AppIcons.cancelOutlined,
              color: approve ? Colors.green : Colors.red,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(approve ? 'Approve Claim?' : 'Reject Claim?'),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                approve
                    ? '${c.quantity} pair(s) of ${c.productName ?? 'this product'} '
                        '(size ${c.sizeName ?? '—'}, ${c.colorName ?? '—'}) will be '
                        'removed from ${c.branchName ?? 'the branch'} stock.\n\n'
                        'This action cannot be undone.'
                    : 'This claim will be marked as rejected. Branch stock stays unchanged.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarksCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Remarks (optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: approve ? Colors.green : Colors.red),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    final remarks = remarksCtrl.text.trim();
    remarksCtrl.dispose();
    if (confirm != true || !mounted) return;

    setState(() => _busyId = c.id);
    try {
      final repo = ref.read(saleClaimRepositoryProvider);
      final reviewer = ref.read(authProvider).user?.id;
      final note = remarks.isEmpty ? null : remarks;
      if (approve) {
        await repo.approveClaim(c.id, reviewedBy: reviewer, remarks: note);
      } else {
        await repo.rejectClaim(c.id, reviewedBy: reviewer, remarks: note);
      }
      if (!mounted) return;
      ref.invalidate(incomingSaleClaimsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Widget _filterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    final chipColor = switch (value) {
      'pending' => Colors.orange,
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => const Color(0xFF1565C0),
    };

    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: isSelected ? chipColor : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
