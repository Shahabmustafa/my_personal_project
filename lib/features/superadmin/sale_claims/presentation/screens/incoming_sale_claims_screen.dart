import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/widget/app_icon.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../branch/sale_claim/data/model/sale_claim_model.dart';
import '../../../../branch/sale_claim/presentation/providers/sale_claim_provider.dart';
import '../../../../branch/sale_claim/presentation/widgets/sale_claim_common.dart';
import '../../../report/presentation/widgets/report_summary_card.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widget/assign_filter_dialog.dart';
import '../../../report/presentation/widgets/report_table_shell.dart';
import 'package:safishoe_app/core/utils/error_text.dart';
import 'package:safishoe_app/core/widget/error_view.dart';

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
  static const _accent = saleClaimAccent;

  List<StatusFilterOption> _statusOptions = const [];
  String _filterStatus = 'all'; // all | pending | approved | rejected
  String _search = '';
  String? _filterBranch;
  DateTime? _fromDate; // claim-date range (inclusive)
  DateTime? _toDate;
  String? _busyId;

  int get _activeFilterCount =>
      (_filterStatus != 'all' ? 1 : 0) +
      (_filterBranch != null ? 1 : 0) +
      (_fromDate != null ? 1 : 0) +
      (_toDate != null ? 1 : 0);

  /// Search + branch + date scope. Status chips / cards count within this.
  List<SaleClaimModel> _scope(List<SaleClaimModel> all) {
    return all.where((c) {
      if (!saleClaimMatchesSearch(c, _search)) return false;
      if (_filterBranch != null && c.branchId != _filterBranch) return false;
      final d = c.claimDate;
      final day = DateTime(d.year, d.month, d.day);
      if (_fromDate != null && day.isBefore(_fromDate!)) return false;
      if (_toDate != null && day.isAfter(_toDate!)) return false;
      return true;
    }).toList();
  }

  Future<void> _openFilterDialog(List<SaleClaimModel> all) async {
    final r = await showAssignFilterDialog(
      context,
      branchLabel: 'Branch',
      allLabel: 'All branches',
      branches: {for (final c in all) c.branchId: c.branchName ?? c.branchId},
      statusOptions: _statusOptions,
      status: _filterStatus,
      onStatus: (v) => _filterStatus = v,
      current: (
        branch: _filterBranch,
        branch2: null,
        from: _fromDate,
        to: _toDate,
      ),
    );
    if (r == null || !mounted) return;
    setState(() {
      _filterBranch = r.branch;
      _fromDate = r.from;
      _toDate = r.to;
    });
  }

  @override
  Widget build(BuildContext context) {
    final claimsAsync = ref.watch(incomingSaleClaimsProvider);
    final all = claimsAsync.value ?? const <SaleClaimModel>[];
    final isMobile = Responsive(context).isMobile;

    final scoped = _scope(all);
    final filtered = _filterStatus == 'all'
        ? scoped
        : scoped.where((c) => c.status == _filterStatus).toList();

    int count(String s) => scoped.where((c) => c.status == s).length;
    final approvedPairs = scoped
        .where((c) => c.status == 'approved')
        .fold<int>(0, (s, c) => s + c.quantity);

    final cards = [
      ReportSummaryCard(
        label: 'Total Claims',
        value: '${scoped.length}',
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
      padding: EdgeInsets.all(isMobile ? 12 : 20),
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
              Badge(
                isLabelVisible: _activeFilterCount > 0,
                label: Text('$_activeFilterCount'),
                child: OutlinedButton.icon(
                  onPressed: () => _openFilterDialog(all),
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filter'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 4),
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
          SaleClaimSearchField(
            hint: 'Search claim no, branch, invoice, customer, product...',
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 12),
          Builder(builder: (_) {
            _statusOptions = buildStatusOptions(scoped, (c) => c.status,
                second: 'approved');
            return const SizedBox.shrink();
          }),
          const SizedBox(height: 16),
          Expanded(
            child: claimsAsync.isLoading && !claimsAsync.hasValue
                ? const Center(child: CircularProgressIndicator())
                : claimsAsync.hasError && !claimsAsync.hasValue
                    ? ErrorView(
                        error: claimsAsync.error,
                        onRetry: () => ref.invalidate(incomingSaleClaimsProvider),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              all.isEmpty
                                  ? 'No claims received yet'
                                  : 'No claims match the filters',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 15),
                            ),
                          )
                        : isMobile
                            ? ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (_, i) => SaleClaimCard(
                                  claim: filtered[i],
                                  showBranch: true,
                                  onTap: () => _showDetail(filtered[i]),
                                  trailing: filtered[i].isPending
                                      ? _actions(filtered[i])
                                      : null,
                                ),
                              )
                            : ReportTableShell(
                                columns: const [
                                  DataColumn(label: Text('Claim No')),
                                  DataColumn(label: Text('Branch')),
                                  DataColumn(label: Text('Customer')),
                                  DataColumn(label: Text('Product')),
                                  DataColumn(label: Text('Size')),
                                  DataColumn(label: Text('Color')),
                                  DataColumn(label: Text('Qty'), numeric: true),
                                  DataColumn(label: Text('Claim Date')),
                                  DataColumn(label: Text('Condition')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: [
                                  for (final c in filtered)
                                    DataRow(
                                      onSelectChanged: (_) => _showDetail(c),
                                      cells: [
                                        DataCell(Text(c.claimNumber,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'monospace',
                                                color: _accent))),
                                        DataCell(Text(c.branchName ?? '—')),
                                        DataCell(Text(c.customerName ?? '—')),
                                        DataCell(Text(claimProductLabel(c))),
                                        DataCell(Text(c.sizeName ?? '—')),
                                        DataCell(Text(c.colorName ?? '—')),
                                        DataCell(Text('${c.quantity}')),
                                        DataCell(
                                            Text(claimFmtDate(c.claimDate))),
                                        DataCell(SaleClaimConditionChip(c)),
                                        DataCell(SaleClaimStatusChip(c.status)),
                                        DataCell(_actions(c)),
                                      ],
                                    ),
                                ],
                              ),
          ),
        ],
      ),
    );
  }

  Widget _actions(SaleClaimModel c) {
    final viewButton = OutlinedButton.icon(
      onPressed: () => _showDetail(c),
      icon: const AppIcon(AppIcons.visibilityOutlined, size: 15),
      label: const Text('View'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1565C0),
        side: const BorderSide(color: Color(0xFF1565C0)),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
    if (!c.isPending) return viewButton;
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
        viewButton,
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

  /// Claim ki poori detail — shared dialog, pending par approve/reject.
  void _showDetail(SaleClaimModel c) {
    showSaleClaimDetail(
      context,
      c,
      actions: (ctx) => [
        if (c.isPending) ...[
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _review(c, approve: false);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _review(c, approve: true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ] else
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
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
              TextField(cursorHeight: 16, 
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
        SnackBar(content: Text(friendlyError(e, prefix: 'Error: ')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }
}
