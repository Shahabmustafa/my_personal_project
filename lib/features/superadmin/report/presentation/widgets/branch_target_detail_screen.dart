import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../branch_target/data/branch_target_datasource.dart';
import '../../data/model/branch_target_row.dart';
import '../providers/sale_report_providers.dart'
    show saleReportRepositoryProvider;

/// Branch Target report mein branch par click karne par khulne wali screen —
/// us branch ke har din ka sale target, total sale aur achieve hua ya nahi.
class BranchTargetDetailScreen extends ConsumerStatefulWidget {
  final BranchTargetRow row;
  final VoidCallback onBack;
  const BranchTargetDetailScreen({
    super.key,
    required this.row,
    required this.onBack,
  });

  @override
  ConsumerState<BranchTargetDetailScreen> createState() =>
      _BranchTargetDetailScreenState();
}

class _DayLine {
  final DateTime date;
  final double target;
  final double sale;
  final bool isToday;
  final bool isFuture;
  const _DayLine(
    this.date,
    this.target,
    this.sale,
    this.isToday,
    this.isFuture,
  );
  bool get achieved => !isFuture && target > 0 && sale >= target;
}

class _BranchTargetDetailScreenState
    extends ConsumerState<BranchTargetDetailScreen> {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _green = Color(0xFF22A06B);
  static const _orange = Color(0xFFE56A00);
  static const _grey = Color(0xFF8A8FA3);

  bool _loading = true;
  String? _error;
  List<_DayLine> _lines = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final id = widget.row.branchId;
      final targets = await ref
          .read(branchTargetDatasourceProvider)
          .fetchFrom(id, DateTime(2000));
      final today = BranchTargetDatasource.dateOnly(DateTime.now());
      final days = targets.keys.toList()..sort();
      Map<DateTime, double> sales = {};
      if (days.isNotEmpty && !days.first.isAfter(today)) {
        final last = days.last.isAfter(today) ? today : days.last;
        sales = await ref
            .read(saleReportRepositoryProvider)
            .getNetSaleByDay(id, days.first, last);
      }
      if (!mounted) return;
      setState(() {
        _lines = [
          for (final d in days)
            _DayLine(
              d,
              targets[d]!,
              sales[d] ?? 0,
              d == today,
              d.isAfter(today),
            ),
        ];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  static String _amt(double v) => 'Rs. ${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final past = _lines.where((l) => !l.isFuture).toList();
    final achieved = past.where((l) => l.achieved).length;
    final totalTarget = _lines.fold(0.0, (s, l) => s + l.target);
    final totalSale = past.fold(0.0, (s, l) => s + l.sale);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${widget.row.branchName} — Target Report',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (!_loading && _lines.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              children: [
                _card(
                  'Total Target',
                  _amt(totalTarget),
                  const Color(0xFF3E63DD),
                ),
                _card(
                  'Total Sale (till today)',
                  _amt(totalSale),
                  totalSale >= 0 ? _green : Colors.red,
                ),
                _card('Achieved Days', '$achieved / ${past.length}', _green),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _card(String label, String value, Color color) => Container(
    width: 220,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE7E9F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Text('Error: $_error', style: const TextStyle(color: Colors.red));
    }
    if (_lines.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('Is branch ka koi target set nahi hai')),
      );
    }
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E9F0)),
        ),
        child: DataTable(
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Sale Target'), numeric: true),
            DataColumn(label: Text('Total Sale'), numeric: true),
            DataColumn(label: Text('Status')),
          ],
          rows: [for (final l in _lines) _row(l)],
        ),
      ),
    );
  }

  DataRow _row(_DayLine l) {
    final String status;
    final Color color;
    if (l.isFuture) {
      status = 'Upcoming';
      color = _grey;
    } else if (l.achieved) {
      status = 'Achieved';
      color = _green;
    } else if (l.isToday) {
      status = 'Pending';
      color = _orange;
    } else {
      status = 'Not Achieved';
      color = Colors.red;
    }
    return DataRow(
      cells: [
        DataCell(
          Text(
            '${_fmtDate(l.date)}  ${_weekdays[l.date.weekday - 1]}${l.isToday ? '  (Today)' : ''}',
            style: TextStyle(
              fontWeight: l.isToday ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        DataCell(Text(_amt(l.target))),
        DataCell(
          Text(
            l.isFuture ? '—' : _amt(l.sale),
            style: TextStyle(color: l.sale < 0 ? Colors.red : null),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
