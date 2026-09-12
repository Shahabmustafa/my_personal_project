import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/branch_target_row.dart';
import '../providers/branch_target_report_provider.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/report_table_shell.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';

/// Har branch ka monthly target (÷30 = aaj ka target), aaj ki net sale, aur
/// target achieve hua ya nahi — ek jagah.
class BranchTargetReportScreen extends ConsumerWidget {
  const BranchTargetReportScreen({super.key});

  static const _accent = Color(0xFF3E63DD);
  static const _achievedColor = Color(0xFF22A06B);
  static const _pendingColor = Color(0xFFE56A00);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(branchTargetReportProvider);
    final notifier = ref.read(branchTargetReportProvider.notifier);

    final withTarget = state.rows.where((r) => r.monthlyTarget > 0).toList();
    final achievedCount = withTarget.where((r) => r.isAchieved).length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Branch Target',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const AppIcon(AppIcons.refresh),
                onPressed: notifier.load,
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                : state.rows.isEmpty
                    ? const Center(child: Text('No branches found'))
                    : SingleChildScrollView(
                        child: ReportTableShell(
                          columns: const [
                            DataColumn(label: Text('Branch')),
                            DataColumn(label: Text('Monthly Target'), numeric: true),
                            DataColumn(label: Text('Today\'s Target'), numeric: true),
                            DataColumn(label: Text('Net Sale (Today)'), numeric: true),
                            DataColumn(label: Text('Status')),
                          ],
                          rows: state.rows.map((r) => _row(r)).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  DataRow _row(BranchTargetRow r) {
    final hasTarget = r.monthlyTarget > 0;
    return DataRow(cells: [
      DataCell(Text(r.branchName, style: const TextStyle(fontWeight: FontWeight.w600))),
      DataCell(Text(
        hasTarget ? 'Rs. ${r.monthlyTarget.toStringAsFixed(0)}' : '—',
      )),
      DataCell(Text(
        hasTarget ? 'Rs. ${r.dailyTarget.toStringAsFixed(0)}' : '—',
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
    ]);
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
