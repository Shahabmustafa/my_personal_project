import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/branch_target_row.dart';
import '../providers/branch_target_report_provider.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/branch_target_detail_dialog.dart';
import '../widgets/report_table_shell.dart';
import '../../../../branch/shared/current_branch_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/utils/responsive.dart';

/// Har branch ka aaj ka target (admin ne din-wise set kiya), aaj ki net sale, aur
/// target achieve hua ya nahi — ek jagah.
class BranchTargetReportScreen extends ConsumerWidget {
  /// Branch-role users ke liye: true hone par sirf apni branch ka target
  /// dikhta hai (aur "Branch" column / branches-wide summary cards hide ho
  /// jate hain).
  final bool restrictToOwnBranch;

  const BranchTargetReportScreen({super.key, this.restrictToOwnBranch = false});

  static const _accent = Color(0xFF3E63DD);
  static const _achievedColor = Color(0xFF22A06B);
  static const _pendingColor = Color(0xFFE56A00);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(branchTargetReportProvider);
    final notifier = ref.read(branchTargetReportProvider.notifier);
    final isMobile = Responsive(context).isMobile;

    final rows = restrictToOwnBranch
        ? state.rows.where((r) => r.branchId == ref.watch(currentBranchIdProvider)).toList()
        : state.rows;

    final withTarget = rows.where((r) => r.hasTarget).toList();
    final achievedCount = withTarget.where((r) => r.isAchieved).length;
    final myTarget = restrictToOwnBranch && rows.isNotEmpty ? rows.first : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(restrictToOwnBranch ? 'My Target' : 'Branch Target',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const AppIcon(AppIcons.refresh, size: 18),
                onPressed: notifier.load,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (myTarget != null)
            Row(children: [
              Expanded(
                child: ReportSummaryCard(
                  label: 'Sale Target (Today)',
                  value: myTarget.hasTarget
                      ? 'Rs. ${myTarget.todayTarget.toStringAsFixed(0)}'
                      : 'Not set',
                  icon: AppIcons.flagOutlined,
                  color: _accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ReportSummaryCard(
                  label: 'Total Sale (Today)',
                  value: 'Rs. ${myTarget.netSaleToday.toStringAsFixed(0)}',
                  icon: AppIcons.trendingUpOutlined,
                  color: myTarget.isAchieved ? _achievedColor : _pendingColor,
                ),
              ),
            ])
          else
            Row(children: [
              Expanded(
                child: ReportSummaryCard(
                  label: 'Branches With Target',
                  value: '${withTarget.length}',
                  icon: AppIcons.flagOutlined,
                  color: _accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ReportSummaryCard(
                  label: 'Achieved Today',
                  value: '$achievedCount / ${withTarget.length}',
                  icon: AppIcons.trendingUpOutlined,
                  color: _achievedColor,
                ),
              ),
            ]),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                    ? const Center(child: Text('No branches found'))
                    : isMobile
                        ? _MobileBranchTargetList(
                            rows: rows,
                            restrictToOwnBranch: restrictToOwnBranch,
                            asOf: state.asOf,
                          )
                        : SingleChildScrollView(
                            child: ReportTableShell(
                              columns: [
                                if (!restrictToOwnBranch) const DataColumn(label: Text('Branch')),
                                const DataColumn(label: Text('Sale Target'), numeric: true),
                                const DataColumn(label: Text('Total Sale'), numeric: true),
                                const DataColumn(label: Text('Status')),
                                const DataColumn(label: Text('Date & Time')),
                              ],
                              rows: rows.map((r) => _row(context, r, state.asOf)).toList(),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  DataRow _row(BuildContext context, BranchTargetRow r, DateTime? asOf) {
    final hasTarget = r.hasTarget;
    return DataRow(onSelectChanged: (_) => BranchTargetDetailDialog.show(context, r), cells: [
      if (!restrictToOwnBranch)
        DataCell(Text(r.branchName, style: const TextStyle(fontWeight: FontWeight.w600))),
      DataCell(Text(
        hasTarget ? 'Rs. ${r.todayTarget.toStringAsFixed(0)}' : '—',
      )),
      DataCell(Text(
        'Rs. ${r.netSaleToday.toStringAsFixed(0)}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: r.netSaleToday < 0 ? Colors.red : const Color(0xFF2D2D3A),
        ),
      )),
      DataCell(hasTarget ? _StatusBadge(row: r) : const Text('No target set',
          style: TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)))),
      DataCell(Text(asOf != null ? _fmtDateTime(asOf) : '—',
          style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)))),
    ]);
  }

  static String _fmtDateTime(DateTime d) {
    final local = d.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    final hour24 = local.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final period = hour24 < 12 ? 'AM' : 'PM';
    final time =
        '${hour12.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} $period';
    return '$date $time';
  }
}

class _StatusBadge extends StatelessWidget {
  final BranchTargetRow row;
  const _StatusBadge({required this.row});

  @override
  Widget build(BuildContext context) {
    final achieved = row.isAchieved;
    final color = achieved
        ? BranchTargetReportScreen._achievedColor
        : BranchTargetReportScreen._pendingColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(achieved ? 'Achieved' : 'Pending',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 90,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: row.progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFE7E9F0),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}

/// Mobile-width fallback for the branch target table — one compact card per
/// branch instead of a six-column DataTable that would overflow or need
/// horizontal scrolling on a phone.
class _MobileBranchTargetList extends StatelessWidget {
  final List<BranchTargetRow> rows;
  final bool restrictToOwnBranch;
  final DateTime? asOf;

  const _MobileBranchTargetList({
    required this.rows,
    required this.restrictToOwnBranch,
    required this.asOf,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = rows[i];
        final hasTarget = r.hasTarget;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => BranchTargetDetailDialog.show(context, r),
          child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7E9F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(restrictToOwnBranch ? 'Today' : r.branchName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text(asOf != null ? BranchTargetReportScreen._fmtDateTime(asOf!) : '—',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA3))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _stat('Sale Target',
                      hasTarget ? 'Rs. ${r.todayTarget.toStringAsFixed(0)}' : '—'),
                  _stat(
                    'Total Sale',
                    'Rs. ${r.netSaleToday.toStringAsFixed(0)}',
                    color: r.netSaleToday < 0 ? Colors.red : const Color(0xFF2D2D3A),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              hasTarget
                  ? _StatusBadge(row: r)
                  : const Text('No target set',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
            ],
          ),
        ));
      },
    );
  }

  Widget _stat(String label, String value, {Color? color}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF8A8FA3))),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color ?? const Color(0xFF2D2D3A))),
        ],
      );
}
