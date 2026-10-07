import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/branch_target_row.dart';
import '../providers/branch_target_report_provider.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/branch_target_detail_screen.dart';
import '../widgets/branch_target_year_detail_screen.dart';
import '../widgets/report_table_shell.dart';
import '../../../../branch/shared/current_branch_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/utils/responsive.dart';

/// Har branch ka aaj ka target (admin ne din-wise set kiya), aaj ki net sale, aur
/// target achieve hua ya nahi — ek jagah.
class BranchTargetReportScreen extends ConsumerStatefulWidget {
  /// Branch-role users ke liye: true hone par sirf apni branch ka target
  /// dikhta hai (aur "Branch" column / branches-wide summary cards hide ho
  /// jate hain).
  final bool restrictToOwnBranch;

  const BranchTargetReportScreen({super.key, this.restrictToOwnBranch = false});

  @override
  ConsumerState<BranchTargetReportScreen> createState() => _BranchTargetReportScreenState();

  static const _accent = Color(0xFF3E63DD);
  static const _achievedColor = Color(0xFF22A06B);
  static const _pendingColor = Color(0xFFE56A00);

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

class _BranchTargetReportScreenState extends ConsumerState<BranchTargetReportScreen> {
  /// Set hone par report ki jagah us branch ki din-wise detail screen dikhti hai
  /// (sidebar wahi rehta hai).
  BranchTargetRow? _selected;

  bool get restrictToOwnBranch => widget.restrictToOwnBranch;

  static const _accent = BranchTargetReportScreen._accent;
  static const _achievedColor = BranchTargetReportScreen._achievedColor;
  static const _pendingColor = BranchTargetReportScreen._pendingColor;

  void _open(BranchTargetRow r) => setState(() => _selected = r);

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    if (selected != null) {
      final period = ref.read(branchTargetReportProvider);
      if (period.period == TargetPeriod.yearly) {
        return BranchTargetYearDetailScreen(
          key: ValueKey('${selected.branchId}-year'),
          row: selected,
          year: period.anchor.year,
          onBack: () => setState(() => _selected = null),
        );
      }
      return BranchTargetDetailScreen(
        key: ValueKey(selected.branchId),
        row: selected,
        from: period.period == TargetPeriod.today ? null : period.from,
        to: period.period == TargetPeriod.today ? null : period.to,
        periodLabel: period.period == TargetPeriod.today ? null : period.periodLabel,
        onBack: () => setState(() => _selected = null),
      );
    }
    final state = ref.watch(branchTargetReportProvider);
    final notifier = ref.read(branchTargetReportProvider.notifier);
    final isMobile = Responsive(context).isMobile;

    final rows = restrictToOwnBranch
        ? state.rows.where((r) => r.branchId == ref.watch(currentBranchIdProvider)).toList()
        : state.rows;

    final withTarget = rows.where((r) => r.hasTarget).toList();
    final achievedCount = withTarget.where((r) => r.isAchieved).length;
    final myTarget = restrictToOwnBranch && rows.isNotEmpty ? rows.first : null;
    final label = state.periodLabel;

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
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<TargetPeriod>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: TargetPeriod.today, label: Text('Today')),
                  ButtonSegment(value: TargetPeriod.monthly, label: Text('Monthly')),
                  ButtonSegment(value: TargetPeriod.yearly, label: Text('Yearly')),
                ],
                selected: {state.period},
                onSelectionChanged: (s) => notifier.setPeriod(s.first),
              ),
              if (state.period != TargetPeriod.today)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const AppIcon(AppIcons.chevronLeft, size: 20),
                      tooltip: 'Previous',
                      onPressed: () => notifier.shift(-1),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      icon: const AppIcon(AppIcons.chevronRight, size: 20),
                      tooltip: 'Next',
                      onPressed: state.canGoNext ? () => notifier.shift(1) : null,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (myTarget != null)
            Row(children: [
              Expanded(
                child: ReportSummaryCard(
                  label: 'Sale Target ($label)',
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
                  label: 'Total Sale ($label)',
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
                  label: 'Achieved ($label)',
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
                            onOpen: _open,
                            restrictToOwnBranch: restrictToOwnBranch,
                            asOf: state.asOf,
                            periodLabel:
                                state.period == TargetPeriod.today ? null : label,
                          )
                        : state.period == TargetPeriod.yearly
                            ? _YearMatrix(
                                rows: rows,
                                year: state.anchor.year,
                                showBranch: !restrictToOwnBranch,
                                onOpen: _open,
                              )
                        : SingleChildScrollView(
                            child: ReportTableShell(
                              columns: [
                                if (!restrictToOwnBranch) const DataColumn(label: Text('Branch')),
                                const DataColumn(label: Text('Sale Target'), numeric: true),
                                const DataColumn(label: Text('Total Sale'), numeric: true),
                                const DataColumn(label: Text('Achieved %'), numeric: true),
                                const DataColumn(label: Text('Remaining'), numeric: true),
                                const DataColumn(label: Text('Remaining %'), numeric: true),
                                const DataColumn(label: Text('Status')),
                                DataColumn(
                                    label: Text(state.period == TargetPeriod.today
                                        ? 'Date & Time'
                                        : 'Period')),
                              ],
                              rows: rows
                                  .map((r) => _row(context, r, state.asOf,
                                      state.period == TargetPeriod.today ? null : label))
                                  .toList(),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  /// [periodLabel] null = "Today" view (aakhri load ka date/time dikhao).
  DataRow _row(BuildContext context, BranchTargetRow r, DateTime? asOf, String? periodLabel) {
    final hasTarget = r.hasTarget;
    return DataRow(onSelectChanged: (_) => _open(r), cells: [
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
      DataCell(Text(
        hasTarget ? '${r.achievedPercent.toStringAsFixed(1)}%' : '—',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: !hasTarget
              ? const Color(0xFF8A8FA3)
              : r.isAchieved ? _achievedColor : _pendingColor,
        ),
      )),
      DataCell(Text(hasTarget ? 'Rs. ${r.remainingAmount.toStringAsFixed(0)}' : '—')),
      DataCell(Text(
        hasTarget ? '${r.remainingPercent.toStringAsFixed(1)}%' : '—',
        style: TextStyle(
          color: hasTarget && r.remainingPercent > 0
              ? Colors.red
              : const Color(0xFF8A8FA3),
        ),
      )),
      DataCell(hasTarget ? _StatusBadge(row: r) : const Text('No target set',
          style: TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)))),
      DataCell(Text(
          periodLabel ??
              (asOf != null ? BranchTargetReportScreen._fmtDateTime(asOf) : '—'),
          style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)))),
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

/// Mobile-width fallback for the branch target table — one compact card per
/// branch instead of a six-column DataTable that would overflow or need
/// horizontal scrolling on a phone.
class _MobileBranchTargetList extends StatelessWidget {
  final List<BranchTargetRow> rows;
  final bool restrictToOwnBranch;
  final DateTime? asOf;
  final String? periodLabel;
  final void Function(BranchTargetRow) onOpen;

  const _MobileBranchTargetList({
    required this.rows,
    required this.onOpen,
    required this.restrictToOwnBranch,
    required this.asOf,
    required this.periodLabel,
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
          onTap: () => onOpen(r),
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
                    child: Text(restrictToOwnBranch ? (periodLabel ?? 'Today') : r.branchName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text(
                      periodLabel ??
                          (asOf != null ? BranchTargetReportScreen._fmtDateTime(asOf!) : '—'),
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
              if (hasTarget) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat(
                      'Achieved',
                      '${r.achievedPercent.toStringAsFixed(1)}%',
                      color: r.isAchieved
                          ? BranchTargetReportScreen._achievedColor
                          : BranchTargetReportScreen._pendingColor,
                    ),
                    _stat(
                      'Remaining',
                      'Rs. ${r.remainingAmount.toStringAsFixed(0)} (${r.remainingPercent.toStringAsFixed(1)}%)',
                      color: r.remainingPercent > 0 ? Colors.red : null,
                    ),
                  ],
                ),
              ],
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

/// Yearly view — har branch ki ek row, Jan..Dec har mahine ka achieved % aur
/// sale / target, aakhir mein poore saal ka total. Row par click → us branch
/// ki month-wise detail.
class _YearMatrix extends StatelessWidget {
  final List<BranchTargetRow> rows;
  final int year;
  final bool showBranch;
  final void Function(BranchTargetRow) onOpen;

  const _YearMatrix({
    required this.rows,
    required this.year,
    required this.showBranch,
    required this.onOpen,
  });

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _grey = Color(0xFF8A8FA3);

  static String _k(double v) {
    final a = v.abs();
    final s = a >= 1000000
        ? '${(a / 1000000).toStringAsFixed(a >= 10000000 ? 0 : 1)}M'
        : a >= 1000
            ? '${(a / 1000).toStringAsFixed(a >= 100000 ? 0 : 1)}K'
            : a.toStringAsFixed(0);
    return v < 0 ? '-$s' : s;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: c.maxWidth),
            child: SingleChildScrollView(
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF7F8FC)),
                headingRowHeight: 48,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 72,
                columnSpacing: 18,
                horizontalMargin: 16,
                columns: [
                  if (showBranch) const DataColumn(label: Text('Branch')),
                  for (final m in _monthNames)
                    DataColumn(label: Text('$m $year')),
                  const DataColumn(
                      label: Text('Year Total',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                ],
                rows: [
                  for (final r in rows)
                    DataRow(onSelectChanged: (_) => onOpen(r), cells: [
                      if (showBranch)
                        DataCell(Text(r.branchName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600))),
                      for (final m in r.months)
                        DataCell(_cell(
                          target: m.target,
                          sale: m.sale,
                          percent: m.achievedPercent,
                          achieved: m.isAchieved,
                          future: m.isFuture,
                        )),
                      DataCell(_cell(
                        target: r.todayTarget,
                        sale: r.netSaleToday,
                        percent: r.achievedPercent,
                        achieved: r.isAchieved,
                        future: false,
                        bold: true,
                      )),
                    ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Upar achieved % (bara), neeche "sale / target" (chhota).
  Widget _cell({
    required double target,
    required double sale,
    required double percent,
    required bool achieved,
    required bool future,
    bool bold = false,
  }) {
    if (target <= 0) {
      return const Text('—', style: TextStyle(color: _grey));
    }
    final color = future
        ? _grey
        : achieved
            ? BranchTargetReportScreen._achievedColor
            : BranchTargetReportScreen._pendingColor;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(future ? 'Upcoming' : '${percent.toStringAsFixed(0)}%',
            style: TextStyle(
                fontSize: future ? 11 : (bold ? 15 : 14),
                fontWeight: FontWeight.w700,
                color: color)),
        const SizedBox(height: 2),
        Text(future ? 'T ${_k(target)}' : '${_k(sale)} / ${_k(target)}',
            style: const TextStyle(fontSize: 10, color: _grey)),
      ],
    );
  }
}
