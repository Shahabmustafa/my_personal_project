import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../branch/shared/current_branch_provider.dart';
import '../../data/pair_incentive/pair_incentive.dart';
import '../providers/pair_incentive_provider.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/report_table_shell.dart';

import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/utils/responsive.dart';
import 'package:safishoe_app/core/widget/app_icon.dart';

/// Per-pair incentive — Branch Target report jaisa drill-down:
///   sab employees (is mahine) → employee click: saal-wise →
///   saal click: mahine-wise → mahina click: din-wise.
/// Rakam tab payable hai jab branch ka mahine ka target poora ho aur admin
/// (superadmin) Accept kare. Admin rate badal sakta hai; branch users sirf
/// apni branch dekhte hain.
class PairIncentiveReportScreen extends ConsumerStatefulWidget {
  const PairIncentiveReportScreen({super.key});

  @override
  ConsumerState<PairIncentiveReportScreen> createState() =>
      _PairIncentiveReportScreenState();
}

class _PairIncentiveReportScreenState
    extends ConsumerState<PairIncentiveReportScreen> {
  static const _green = Color(0xFF22A06B);
  static const _red = Color(0xFFE5484D);
  static const _orange = Color(0xFFE56A00);
  static const _accent = Color(0xFF3E63DD);
  static const _grey = Color(0xFF8A8FA3);
  static const _mon = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Level 1: mahina chunna.
  DateTime _anchor = DateTime(DateTime.now().year, DateTime.now().month);

  // Drill-down: employee → saal → mahina.
  PairIncentiveRow? _emp;
  int? _year;
  DateTime? _month;

  static String _rs(num v) => 'Rs. ${v.toStringAsFixed(0)}';

  bool get _canNextMonth {
    final n = DateTime.now();
    return _anchor.year < n.year ||
        (_anchor.year == n.year && _anchor.month < n.month);
  }

  void _back() => setState(() {
    if (_month != null) {
      _month = null;
    } else if (_year != null) {
      _year = null;
    } else {
      _emp = null;
    }
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authProvider).user?.isSuperAdmin ?? false;
    final ownBranch = isAdmin ? '' : ref.watch(currentBranchIdProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 14),
          Expanded(
            child: _emp == null
                ? _employeesLevel(isAdmin, ownBranch)
                : _year == null
                ? _yearsLevel(isAdmin)
                : _month == null
                ? _monthsLevel(isAdmin)
                : _daysLevel(),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final e = _emp;
    final crumbs = [
      if (e != null) '${e.username} (${e.branchName})',
      if (_year != null) '$_year',
      if (_month != null) _mon[_month!.month - 1],
    ].join('  ›  ');
    return Row(
      children: [
        if (e != null)
          IconButton(
            icon: const AppIcon(AppIcons.chevronLeft, size: 20),
            tooltip: 'Back',
            onPressed: _back,
          ),
        Expanded(
          child: Text(
            e == null ? 'Pair Incentive' : crumbs,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const AppIcon(AppIcons.refresh, size: 18),
          onPressed: () {
            ref.invalidate(pairIncentiveProvider);
            ref.invalidate(pairIncentiveDaysProvider);
          },
        ),
      ],
    );
  }

  // ── Level 1: sab employees, chuna hua mahina ──────────────────────────────

  Widget _employeesLevel(bool isAdmin, String ownBranch) {
    final async = ref.watch(
      pairIncentiveProvider((_anchor, _anchor, ownBranch)),
    );
    final isMobile = Responsive(context).isMobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const AppIcon(AppIcons.chevronLeft, size: 20),
              onPressed: () => setState(
                () => _anchor = DateTime(_anchor.year, _anchor.month - 1),
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                '${_mon[_anchor.month - 1]} ${_anchor.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const AppIcon(AppIcons.chevronRight, size: 20),
              onPressed: _canNextMonth
                  ? () => setState(
                      () => _anchor = DateTime(_anchor.year, _anchor.month + 1),
                    )
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: async.when(
            skipLoadingOnReload: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Error: $e', style: const TextStyle(color: _red)),
            ),
            data: (data) {
              if (data.rows.isEmpty) {
                return const Center(
                  child: Text(
                    'No salesman / manager found',
                    style: TextStyle(color: _grey),
                  ),
                );
              }
              final monthOf = {for (final m in data.months) m.branchId: m};
              final net = data.rows.fold<int>(0, (s, r) => s + r.net);
              final earned = data.rows.fold<double>(0, (s, r) => s + r.amount);
              final payable = data.rows
                  .where((r) => r.approved)
                  .fold<double>(0, (s, r) => s + r.amount);
              final cards = [
                ReportSummaryCard(
                  label: 'Net Pairs',
                  value: '$net',
                  icon: AppIcons.peopleOutline,
                  color: _accent,
                ),
                ReportSummaryCard(
                  label: 'Earned',
                  value: _rs(earned),
                  icon: AppIcons.currencyRupeeOutlined,
                  color: _orange,
                ),
                ReportSummaryCard(
                  label: 'Payable (Accepted)',
                  value: _rs(payable),
                  icon: AppIcons.checkCircleOutline,
                  color: _green,
                ),
              ];
              return ListView(
                children: [
                  isMobile
                      ? Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final c in cards)
                              SizedBox(
                                width:
                                    (MediaQuery.of(context).size.width - 50) /
                                    2,
                                child: c,
                              ),
                          ],
                        )
                      : Row(
                          children: [
                            for (var i = 0; i < cards.length; i++) ...[
                              if (i > 0) const SizedBox(width: 14),
                              Expanded(child: cards[i]),
                            ],
                          ],
                        ),
                  const SizedBox(height: 16),
                  ReportTableShell(
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Employee')),
                      DataColumn(label: Text('Branch')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Sold'), numeric: true),
                      DataColumn(label: Text('Returned'), numeric: true),
                      DataColumn(label: Text('Net Pairs'), numeric: true),
                      DataColumn(label: Text('Rate / Pair'), numeric: true),
                      DataColumn(label: Text('Earned'), numeric: true),
                      DataColumn(label: Text('Payable'), numeric: true),
                      DataColumn(label: Text('Branch Target')),
                    ],
                    rows: [
                      for (var i = 0; i < data.rows.length; i++)
                        _employeeRow(
                          i + 1,
                          data.rows[i],
                          monthOf[data.rows[i].branchId],
                          isAdmin,
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  DataRow _employeeRow(
    int n,
    PairIncentiveRow r,
    PairIncentiveMonth? m,
    bool isAdmin,
  ) {
    return DataRow(
      onSelectChanged: (_) => setState(() {
        _emp = r;
        _year = null;
        _month = null;
      }),
      cells: [
        DataCell(Text('$n', style: const TextStyle(color: _grey))),
        DataCell(
          Text(r.username, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        DataCell(Text(r.branchName)),
        DataCell(
          Text(
            r.role == 'manager' ? 'Manager' : 'Salesman',
            style: const TextStyle(color: _grey),
          ),
        ),
        DataCell(Text('${r.sold}')),
        DataCell(
          Text(
            '${r.returned}',
            style: TextStyle(color: r.returned > 0 ? _red : null),
          ),
        ),
        DataCell(
          Text('${r.net}', style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        DataCell(_rateCell(r, isAdmin)),
        DataCell(Text(_rs(r.amount))),
        DataCell(
          Text(
            _rs(r.approved ? r.amount : 0),
            style: TextStyle(
              color: r.approved && r.amount > 0 ? _green : _grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(m == null ? const Text('—') : _targetCell(m, isAdmin)),
      ],
    );
  }

  Widget _rateCell(PairIncentiveRow r, bool isAdmin) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(_rs(r.rate)),
      if (isAdmin)
        IconButton(
          tooltip: 'Set rate per pair',
          icon: const Icon(Icons.edit_outlined, size: 16),
          onPressed: () => _editRate(r),
        ),
    ],
  );

  /// Branch ke target ka haal + (admin ke liye) Accept.
  Widget _targetCell(PairIncentiveMonth m, bool isAdmin) {
    if (m.approved) return _chip('Accepted', _green);
    if (m.achieved) {
      return isAdmin
          ? TextButton(
              onPressed: () => _accept(m),
              child: const Text('Achieved — Accept'),
            )
          : _chip('Achieved — waiting', _orange);
    }
    return _chip(m.target > 0 ? 'Not achieved' : 'No target', _grey);
  }

  // ── Level 2: employee ke saal ─────────────────────────────────────────────

  Widget _yearsLevel(bool isAdmin) {
    final e = _emp!;
    final startAsync = ref.watch(pairIncentiveStartYearProvider(e.employeeId));
    final now = DateTime.now();
    return startAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text('Error: $err', style: const TextStyle(color: _red)),
      ),
      data: (start) {
        final from = DateTime(start < now.year ? start : now.year);
        final async = ref.watch(
          pairIncentiveProvider((
            from,
            DateTime(now.year, now.month),
            e.branchId,
          )),
        );
        return async.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text('Error: $err', style: const TextStyle(color: _red)),
          ),
          data: (data) {
            final mine = data.rows
                .where((r) => r.employeeId == e.employeeId)
                .toList();
            final years = [for (var y = now.year; y >= from.year; y--) y];
            return SingleChildScrollView(
              child: ReportTableShell(
                columns: _periodColumns('Year'),
                rows: [
                  for (final y in years)
                    _periodRow(
                      '$y',
                      mine.where((r) => r.month.year == y).toList(),
                      onTap: () => setState(() => _year = y),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Level 3: saal ke mahine ───────────────────────────────────────────────

  Widget _monthsLevel(bool isAdmin) {
    final e = _emp!;
    final y = _year!;
    final async = ref.watch(
      pairIncentiveProvider((DateTime(y), DateTime(y, 12), e.branchId)),
    );
    final now = DateTime.now();
    return async.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text('Error: $err', style: const TextStyle(color: _red)),
      ),
      data: (data) {
        final mine = data.rows
            .where((r) => r.employeeId == e.employeeId)
            .toList();
        final monthInfo = {for (final m in data.months) m.month.month: m};
        return SingleChildScrollView(
          child: ReportTableShell(
            columns: [
              ..._periodColumns('Month'),
              const DataColumn(label: Text('Branch Target')),
            ],
            rows: [
              for (var mo = 12; mo >= 1; mo--)
                if (!DateTime(y, mo).isAfter(DateTime(now.year, now.month)))
                  _periodRow(
                    _mon[mo - 1],
                    mine.where((r) => r.month.month == mo).toList(),
                    onTap: () => setState(() => _month = DateTime(y, mo)),
                    extra: monthInfo[mo] == null
                        ? const Text('—')
                        : _targetCell(monthInfo[mo]!, isAdmin),
                  ),
            ],
          ),
        );
      },
    );
  }

  // ── Level 4: mahine ke din ────────────────────────────────────────────────

  Widget _daysLevel() {
    final e = _emp!;
    final async = ref.watch(pairIncentiveDaysProvider((e.employeeId, _month!)));
    return async.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text('Error: $err', style: const TextStyle(color: _red)),
      ),
      data: (days) => SingleChildScrollView(
        child: ReportTableShell(
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Sold'), numeric: true),
            DataColumn(label: Text('Returned'), numeric: true),
            DataColumn(label: Text('Net Pairs'), numeric: true),
            DataColumn(label: Text('Earned'), numeric: true),
          ],
          rows: [
            for (final d in days)
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      '${_wd[d.day.weekday - 1]}, ${d.day.day} ${_mon[d.day.month - 1]}',
                      style: TextStyle(
                        color: d.sold == 0 && d.returned == 0 ? _grey : null,
                      ),
                    ),
                  ),
                  DataCell(Text('${d.sold}')),
                  DataCell(
                    Text(
                      '${d.returned}',
                      style: TextStyle(color: d.returned > 0 ? _red : null),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${d.net}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text(_rs(d.net * e.rate))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Common ────────────────────────────────────────────────────────────────

  List<DataColumn> _periodColumns(String first) => [
    DataColumn(label: Text(first)),
    const DataColumn(label: Text('Sold'), numeric: true),
    const DataColumn(label: Text('Returned'), numeric: true),
    const DataColumn(label: Text('Net Pairs'), numeric: true),
    const DataColumn(label: Text('Earned'), numeric: true),
    const DataColumn(label: Text('Payable'), numeric: true),
  ];

  DataRow _periodRow(
    String label,
    List<PairIncentiveRow> rows, {
    required VoidCallback onTap,
    Widget? extra,
  }) {
    final sold = rows.fold<int>(0, (s, r) => s + r.sold);
    final ret = rows.fold<int>(0, (s, r) => s + r.returned);
    final earned = rows.fold<double>(0, (s, r) => s + r.amount);
    final payable = rows
        .where((r) => r.approved)
        .fold<double>(0, (s, r) => s + r.amount);
    return DataRow(
      onSelectChanged: (_) => onTap(),
      cells: [
        DataCell(
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        DataCell(Text('$sold')),
        DataCell(Text('$ret', style: TextStyle(color: ret > 0 ? _red : null))),
        DataCell(
          Text(
            '${sold - ret}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(Text(_rs(earned))),
        DataCell(
          Text(
            _rs(payable),
            style: TextStyle(
              color: payable > 0 ? _green : _grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (extra != null) DataCell(extra),
      ],
    );
  }

  Widget _chip(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      t,
      style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );

  Future<void> _accept(PairIncentiveMonth m) async {
    final label = '${_mon[m.month.month - 1]} ${m.month.year}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Accept $label — ${m.branchName}?'),
        content: Text(
          'Target ${_rs(m.target)} achieved (sale ${_rs(m.netSale)}). '
          'The pair incentive of this month will be fixed and payable. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(pairIncentiveDatasourceProvider)
          .approve(m.branchId, m.month);
      ref.invalidate(pairIncentiveProvider);
      _snack('Accepted');
    } catch (e) {
      _snack('Error: $e');
    }
  }

  Future<void> _editRate(PairIncentiveRow r) async {
    final ctrl = TextEditingController(
      text: r.rate == 0 ? '' : r.rate.toStringAsFixed(2),
    );
    final v = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Rate per pair — ${r.username}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: 'Rs. '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final n = double.tryParse(ctrl.text.trim());
              if (n != null && n >= 0) Navigator.pop(context, n);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (v == null) return;
    try {
      await ref.read(pairIncentiveDatasourceProvider).setRate(r.employeeId, v);
      ref.invalidate(pairIncentiveProvider);
    } catch (e) {
      _snack('Error: $e');
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }
}
