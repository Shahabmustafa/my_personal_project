import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widget/app_icon.dart';
import '../../../../../core/widget/assign_filter_dialog.dart';
import '../../../../superadmin/report/presentation/widgets/report_summary_card.dart';
import '../../../../superadmin/report/presentation/widgets/report_table_shell.dart';
import '../../data/model/sale_claim_model.dart';
import '../providers/sale_claim_provider.dart';
import '../widgets/new_sale_claim_dialog.dart';
import '../widgets/sale_claim_common.dart';
import 'package:safishoe_app/core/widget/error_view.dart';

/// Branch ke Sale Claims — customer ki kharab nikli product ka Head Office
/// ke naam claim. Approve hone par branch stock se minus hota hai.
class SaleClaimsScreen extends ConsumerStatefulWidget {
  const SaleClaimsScreen({super.key});

  @override
  ConsumerState<SaleClaimsScreen> createState() => _SaleClaimsScreenState();
}

class _SaleClaimsScreenState extends ConsumerState<SaleClaimsScreen> {
  static const _accent = saleClaimAccent;

  List<StatusFilterOption> _statusOptions = const [];
  String _filterStatus = 'all'; // all | pending | approved | rejected
  String _search = '';
  DateTime? _fromDate; // claim-date range (inclusive)
  DateTime? _toDate;

  int get _activeFilterCount =>
      (_filterStatus != 'all' ? 1 : 0) +
      (_fromDate != null ? 1 : 0) + (_toDate != null ? 1 : 0);

  /// Search + date scope. Status chips count within this.
  List<SaleClaimModel> _scope(List<SaleClaimModel> all) {
    return all.where((c) {
      if (!saleClaimMatchesSearch(c, _search)) return false;
      final d = c.claimDate;
      final day = DateTime(d.year, d.month, d.day);
      if (_fromDate != null && day.isBefore(_fromDate!)) return false;
      if (_toDate != null && day.isAfter(_toDate!)) return false;
      return true;
    }).toList();
  }

  Future<void> _openFilterDialog() async {
    final r = await showAssignFilterDialog(
      context,
      branchLabel: '',
      allLabel: '',
      showBranch: false,
      branches: const {},
      statusOptions: _statusOptions,
      status: _filterStatus,
      onStatus: (v) => _filterStatus = v,
      current: (branch: null, branch2: null, from: _fromDate, to: _toDate),
    );
    if (r == null || !mounted) return;
    setState(() {
      _fromDate = r.from;
      _toDate = r.to;
    });
  }

  Future<void> _newClaim() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const NewSaleClaimDialog(),
    );
    if (saved == true) {
      ref.invalidate(branchSaleClaimsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Claim sent to Head Office'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final claimsAsync = ref.watch(branchSaleClaimsProvider);
    final all = claimsAsync.value ?? const <SaleClaimModel>[];
    final isMobile = Responsive(context).isMobile;

    final scoped = _scope(all);
    final filtered = _filterStatus == 'all'
        ? scoped
        : scoped.where((c) => c.status == _filterStatus).toList();

    final pairs = filtered.fold<int>(0, (s, c) => s + c.quantity);
    final value = filtered.fold<double>(0, (s, c) => s + c.totalPrice);

    final filterButton = Badge(
      isLabelVisible: _activeFilterCount > 0,
      label: Text('$_activeFilterCount'),
      child: OutlinedButton.icon(
        onPressed: _openFilterDialog,
        icon: const Icon(Icons.filter_list, size: 18),
        label: const Text('Filter'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
    final newClaimButton = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: _accent,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const AppIcon(AppIcons.add, size: 18, color: Colors.white),
      label: const Text('New Claim'),
      onPressed: _newClaim,
    );
    final refreshButton = IconButton(
      icon: const AppIcon(AppIcons.refresh, size: 18),
      tooltip: 'Refresh',
      onPressed: () => ref.invalidate(branchSaleClaimsProvider),
    );

    const titleBlock = Row(
      children: [
        AppIcon(AppIcons.warningAmberOutlined, color: _accent, size: 24),
        SizedBox(width: 8),
        Expanded(
          child: Text('Sale Claims',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            titleBlock,
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: newClaimButton),
                const SizedBox(width: 8),
                filterButton,
                refreshButton,
              ],
            ),
          ] else
            Row(
              children: [
                const Expanded(child: titleBlock),
                filterButton,
                const SizedBox(width: 4),
                refreshButton,
                const SizedBox(width: 8),
                newClaimButton,
              ],
            ),
          const SizedBox(height: 16),
          ReportSummaryCards(
            children: [
              ReportSummaryCard(
                label: 'Total Claims',
                value: '${filtered.length}',
                icon: AppIcons.warningAmberOutlined,
                color: const Color(0xFF1565C0),
              ),
              ReportSummaryCard(
                label: 'Pending',
                value: '${filtered.where((c) => c.isPending).length}',
                icon: AppIcons.hourglassEmptyOutlined,
                color: _accent,
              ),
              ReportSummaryCard(
                label: 'Pairs Claimed',
                value: '$pairs',
                icon: AppIcons.inventory2Outlined,
                color: const Color(0xFF6A1B9A),
              ),
              ReportSummaryCard(
                label: 'Claim Value',
                value: 'Rs. ${value.toStringAsFixed(0)}',
                icon: AppIcons.sellOutlined,
                color: const Color(0xFF22A06B),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SaleClaimSearchField(
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
                        onRetry: () => ref.invalidate(branchSaleClaimsProvider),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                                all.isEmpty
                                    ? 'No claims yet'
                                    : 'No claims match the filters',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 15)),
                          )
                        : isMobile
                            ? ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (_, i) => SaleClaimCard(
                                  claim: filtered[i],
                                  showBranch: false,
                                  onTap: () => showSaleClaimDetail(
                                    context,
                                    filtered[i],
                                    showBranch: false,
                                  ),
                                ),
                              )
                            : _table(filtered),
          ),
        ],
      ),
    );
  }

  Widget _table(List<SaleClaimModel> rows) {
    return ReportTableShell(
      columns: const [
        DataColumn(label: Text('Claim No')),
        DataColumn(label: Text('Invoice')),
        DataColumn(label: Text('Customer')),
        DataColumn(label: Text('Product')),
        DataColumn(label: Text('Size')),
        DataColumn(label: Text('Color')),
        DataColumn(label: Text('Qty'), numeric: true),
        DataColumn(label: Text('Claim Date')),
        DataColumn(label: Text('Condition')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('')),
      ],
      rows: [
        for (final c in rows)
          DataRow(
            onSelectChanged: (_) =>
                showSaleClaimDetail(context, c, showBranch: false),
            cells: [
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
              DataCell(Text(claimFmtDate(c.claimDate))),
              DataCell(SaleClaimConditionChip(c)),
              DataCell(SaleClaimStatusChip(c.status)),
              DataCell(
                IconButton(
                  tooltip: 'View details',
                  icon: const AppIcon(AppIcons.visibilityOutlined, size: 18),
                  onPressed: () =>
                      showSaleClaimDetail(context, c, showBranch: false),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
