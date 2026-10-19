import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../branch_target/data/branch_target_datasource.dart';
import '../../data/model/branch_target_row.dart';
import '../providers/sale_report_providers.dart'
    show saleReportRepositoryProvider;
import 'branch_target_year_detail_screen.dart';
import 'report_table_shell.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';

/// Branch Target report mein branch par click — us branch ke saal (target
/// set hone wale pehle saal se is saal tak), har saal ka total target, sale
/// aur achieved %. Saal par click → us saal ke mahine
/// ([BranchTargetYearDetailScreen]) → mahine par click → din-ba-din.
class BranchTargetYearsScreen extends ConsumerStatefulWidget {
  final BranchTargetRow row;
  final VoidCallback onBack;

  const BranchTargetYearsScreen(
      {super.key, required this.row, required this.onBack});

  @override
  ConsumerState<BranchTargetYearsScreen> createState() =>
      _BranchTargetYearsScreenState();
}

class _BranchTargetYearsScreenState
    extends ConsumerState<BranchTargetYearsScreen> {
  static const _green = Color(0xFF22A06B);
  static const _orange = Color(0xFFE56A00);
  static const _grey = Color(0xFF8A8FA3);

  bool _loading = true;
  String? _error;

  /// Naya saal pehle. Har entry: us saal ka total + Jan..Dec.
  List<BranchTargetRow> _years = [];

  /// Set hone par us saal ke mahine dikhte hain.
  BranchTargetRow? _year;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = widget.row.branchId;
      final targets = await ref
          .read(branchTargetDatasourceProvider)
          .fetchFrom(id, DateTime(2000));
      final now = DateTime.now();
      final today = BranchTargetDatasource.dateOnly(now);
      final firstYear = targets.isEmpty
          ? now.year
          : targets.keys.map((d) => d.year).reduce((a, b) => a < b ? a : b);
      final lastYear = targets.isEmpty
          ? now.year
          : targets.keys
              .map((d) => d.year)
              .fold(now.year, (a, b) => a > b ? a : b);
      final sales = await ref
          .read(saleReportRepositoryProvider)
          .getNetSaleByDay(id, DateTime(firstYear, 1, 1), today);

      // {saal: {mahina: amount}}
      Map<int, Map<int, double>> byMonth(Map<DateTime, double> daily) {
        final out = <int, Map<int, double>>{};
        for (final e in daily.entries) {
          final m = out.putIfAbsent(e.key.year, () => {});
          m[e.key.month] = (m[e.key.month] ?? 0) + e.value;
        }
        return out;
      }

      final t = byMonth(targets);
      final s = byMonth(sales);
      final years = [
        for (var y = lastYear; y >= firstYear; y--)
          () {
            final months = [
              for (var m = 1; m <= 12; m++)
                BranchMonthTarget(
                  month: DateTime(y, m, 1),
                  target: t[y]?[m] ?? 0,
                  sale: s[y]?[m] ?? 0,
                ),
            ];
            return BranchTargetRow(
              branchId: id,
              branchName: widget.row.branchName,
              todayTarget: months.fold(0, (a, m) => a + m.target),
              netSaleToday: months.fold(0, (a, m) => a + m.sale),
              months: months,
            );
          }(),
      ];
      if (!mounted) return;
      setState(() {
        _years = years;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
        _loading = false;
      });
    }
  }

  static String _amt(double v) => 'Rs. ${v.toStringAsFixed(0)}';
  static String _pct(double v) => '${v.toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final year = _year;
    if (year != null) {
      return BranchTargetYearDetailScreen(
        key: ValueKey('${year.branchId}-${year.months.first.month.year}'),
        row: year,
        year: year.months.first.month.year,
        onBack: () => setState(() => _year = null),
      );
    }

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
              child: Text('${widget.row.branchName} — Target by Year',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ),
            IconButton(
              icon: const AppIcon(AppIcons.refresh, size: 18),
              onPressed: _load,
            ),
          ]),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 52),
            child: Text('Click a year — months of that year',
                style: TextStyle(fontSize: 12, color: _grey)),
          ),
          const SizedBox(height: 16),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Text('Error: $_error', style: const TextStyle(color: Colors.red));
    }
    return ReportTableShell(
      columns: const [
        DataColumn(label: Text('Year')),
        DataColumn(label: Text('Target'), numeric: true),
        DataColumn(label: Text('Achieved'), numeric: true),
        DataColumn(label: Text('Achieved %'), numeric: true),
        DataColumn(label: Text('Remaining'), numeric: true),
        DataColumn(label: Text('Remaining %'), numeric: true),
      ],
      rows: [for (final y in _years) _row(y)],
    );
  }

  DataRow _row(BranchTargetRow y) {
    final has = y.hasTarget;
    final year = y.months.first.month.year;
    return DataRow(onSelectChanged: (_) => setState(() => _year = y), cells: [
      DataCell(Text(
          '$year${year == DateTime.now().year ? '  (This year)' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w600))),
      DataCell(Text(has ? _amt(y.todayTarget) : '—')),
      DataCell(Text(_amt(y.netSaleToday),
          style: TextStyle(color: y.netSaleToday < 0 ? Colors.red : null))),
      DataCell(Text(has ? _pct(y.achievedPercent) : '—',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              color: !has ? _grey : (y.isAchieved ? _green : _orange)))),
      DataCell(Text(has ? _amt(y.remainingAmount) : '—')),
      DataCell(Text(has ? _pct(y.remainingPercent) : '—',
          style: TextStyle(
              color: has && y.remainingPercent > 0 ? Colors.red : _grey))),
    ]);
  }
}
