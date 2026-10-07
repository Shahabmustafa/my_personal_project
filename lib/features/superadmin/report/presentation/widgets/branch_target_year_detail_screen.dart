import 'package:flutter/material.dart';
import '../../data/model/branch_target_row.dart';
import 'branch_target_detail_screen.dart';
import 'report_summary_card.dart';
import 'report_table_shell.dart';

import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/utils/responsive.dart';

/// Yearly Branch Target report mein branch par click — us branch ke Jan..Dec
/// ka target, sale, achieved % aur kitna baqi. Mahine par click → us mahine
/// ki din-wise detail ([BranchTargetDetailScreen]).
class BranchTargetYearDetailScreen extends StatefulWidget {
  final BranchTargetRow row;
  final int year;
  final VoidCallback onBack;

  const BranchTargetYearDetailScreen({
    super.key,
    required this.row,
    required this.year,
    required this.onBack,
  });

  @override
  State<BranchTargetYearDetailScreen> createState() =>
      _BranchTargetYearDetailScreenState();
}

class _BranchTargetYearDetailScreenState
    extends State<BranchTargetYearDetailScreen> {
  static const _accent = Color(0xFF3E63DD);
  static const _green = Color(0xFF22A06B);
  static const _orange = Color(0xFFE56A00);
  static const _grey = Color(0xFF8A8FA3);
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// Set hone par us mahine ki din-wise detail dikhti hai.
  BranchMonthTarget? _month;

  static String _amt(double v) => 'Rs. ${v.toStringAsFixed(0)}';
  static String _pct(double v) => '${v.toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final month = _month;
    final row = widget.row;
    if (month != null) {
      return BranchTargetDetailScreen(
        key: ValueKey('${row.branchId}-${month.month}'),
        row: row,
        from: month.month,
        to: DateTime(month.month.year, month.month.month + 1, 0),
        periodLabel: '${_months[month.month.month - 1]} ${month.month.year}',
        onBack: () => setState(() => _month = null),
      );
    }

    final isMobile = Responsive(context).isMobile;
    final withTarget = row.months.where((m) => m.hasTarget && !m.isFuture);
    final achievedMonths = withTarget.where((m) => m.isAchieved).length;

    final cards = [
      ReportSummaryCard(
        label: 'Year Target',
        value: row.hasTarget ? _amt(row.todayTarget) : 'Not set',
        icon: AppIcons.flagOutlined,
        color: _accent,
      ),
      ReportSummaryCard(
        label: 'Total Sale',
        value: _amt(row.netSaleToday),
        icon: AppIcons.trendingUpOutlined,
        color: row.netSaleToday < 0 ? Colors.red : _green,
      ),
      ReportSummaryCard(
        label: 'Achieved',
        value: row.hasTarget ? _pct(row.achievedPercent) : '—',
        icon: AppIcons.percentOutlined,
        color: row.isAchieved ? _green : _orange,
      ),
      ReportSummaryCard(
        label: 'Achieved Months',
        value: '$achievedMonths / ${withTarget.length}',
        icon: AppIcons.calendarTodayOutlined,
        color: _green,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(
                onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
            const SizedBox(width: 4),
            Expanded(
              child: Text('${row.branchName} — Target Report (${widget.year})',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 16),
          isMobile
              ? Column(children: [
                  for (final c in cards)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 10), child: c),
                ])
              : Row(children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(child: cards[i]),
                  ],
                ]),
          const SizedBox(height: 8),
          const Text('Mahine par click karein — din-wise detail',
              style: TextStyle(fontSize: 12, color: _grey)),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: ReportTableShell(
                columns: const [
                  DataColumn(label: Text('Month')),
                  DataColumn(label: Text('Target'), numeric: true),
                  DataColumn(label: Text('Total Sale'), numeric: true),
                  DataColumn(label: Text('Achieved %'), numeric: true),
                  DataColumn(label: Text('Remaining'), numeric: true),
                  DataColumn(label: Text('Remaining %'), numeric: true),
                  DataColumn(label: Text('Status')),
                ],
                rows: [for (final m in row.months) _row(m)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _row(BranchMonthTarget m) {
    final (String status, Color color) = !m.hasTarget
        ? ('No target', _grey)
        : m.isFuture
            ? ('Upcoming', _grey)
            : m.isAchieved
                ? ('Achieved', _green)
                : m.isCurrent
                    ? ('Pending', _orange)
                    : ('Not Achieved', Colors.red);
    final showNumbers = m.hasTarget && !m.isFuture;
    return DataRow(
      onSelectChanged: m.hasTarget ? (_) => setState(() => _month = m) : null,
      cells: [
        DataCell(Text(
            '${_months[m.month.month - 1]}${m.isCurrent ? '  (This month)' : ''}',
            style: TextStyle(
                fontWeight: m.isCurrent ? FontWeight.w700 : FontWeight.w500))),
        DataCell(Text(m.hasTarget ? _amt(m.target) : '—')),
        DataCell(Text(m.isFuture ? '—' : _amt(m.sale),
            style: TextStyle(color: m.sale < 0 ? Colors.red : null))),
        DataCell(Text(showNumbers ? _pct(m.achievedPercent) : '—',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: showNumbers ? (m.isAchieved ? _green : _orange) : _grey))),
        DataCell(Text(showNumbers ? _amt(m.remainingAmount) : '—')),
        DataCell(Text(showNumbers ? _pct(m.remainingPercent) : '—',
            style: TextStyle(
                color: showNumbers && m.remainingPercent > 0
                    ? Colors.red
                    : _grey))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(status,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        )),
      ],
    );
  }
}
