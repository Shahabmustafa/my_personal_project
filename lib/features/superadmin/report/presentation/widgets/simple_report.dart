import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../branch/shared/current_branch_provider.dart';
import 'report_branch_filter_dropdown.dart';
import 'report_date_filter_dialog.dart';
import 'report_summary_card.dart';
import 'report_table_shell.dart';

import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/utils/responsive.dart';
import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/widget/error_view.dart';

/// Report ke upar ka ek summary card.
class SimpleReportCard {
  final String label;
  final String value;
  final String icon;
  final Color color;
  const SimpleReportCard(this.label, this.value, this.icon, this.color);
}

/// Row click par khulne wali detail — upar label/value fields, neeche
/// (zaroorat ho to) ek table.
class SimpleDetail {
  final String title;
  final List<(String, String)> fields;
  final List<String> tableColumns;
  final List<List<String>> tableRows;
  const SimpleDetail({
    required this.title,
    this.fields = const [],
    this.tableColumns = const [],
    this.tableRows = const [],
  });
}

class SimpleReportRow {
  final List<String> cells;

  /// Row click par detail laane wala — null ho to row click nahi hoti.
  final Future<SimpleDetail> Function()? detail;
  const SimpleReportRow(this.cells, {this.detail});
}

class SimpleReportData {
  final List<SimpleReportCard> cards;
  final List<String> columns;

  /// Jin columns ke numbers right-align hon (index).
  final Set<int> numericColumns;
  final List<SimpleReportRow> rows;
  const SimpleReportData({
    required this.cards,
    required this.columns,
    required this.rows,
    this.numericColumns = const {},
  });
}

/// Report chalane ke liye filter — [from]/[to] Pakistan ke din (dono shamil),
/// [branchId] null = sab branches.
class SimpleReportQuery {
  final DateTime from;
  final DateTime to;
  final String? branchId;
  const SimpleReportQuery(this.from, this.to, this.branchId);

  /// Pakistan (UTC+5) din ki hadd — created_at jaise timestamptz columns ke
  /// liye: [start, endExclusive).
  String get startIso =>
      DateTime.utc(from.year, from.month, from.day)
          .subtract(const Duration(hours: 5))
          .toIso8601String();
  String get endIso =>
      DateTime.utc(to.year, to.month, to.day + 1)
          .subtract(const Duration(hours: 5))
          .toIso8601String();
}

String rs(num v) {
  final neg = v < 0;
  final s = v.abs().round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '${neg ? '-' : ''}Rs. $b';
}

String fmtDate(DateTime d) {
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
}

String fmtDateTime(DateTime d) {
  final l = d.toLocal();
  final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
  return '${fmtDate(l)} $h:${l.minute.toString().padLeft(2, '0')} ${l.hour < 12 ? 'AM' : 'PM'}';
}

/// Config se chalne wali report screen: filters (date / branch), cards,
/// search, table (pagination), row click par detail.
class SimpleReportScreen extends ConsumerStatefulWidget {
  final String title;

  /// Branch user: sirf apni branch (branch filter nahi).
  final bool restrictToOwnBranch;
  final bool showDates;
  final String searchHint;
  final Future<SimpleReportData> Function(SimpleReportQuery q) fetch;

  const SimpleReportScreen({
    super.key,
    required this.title,
    required this.fetch,
    this.restrictToOwnBranch = false,
    this.showDates = true,
    this.searchHint = 'Search…',
  });

  @override
  ConsumerState<SimpleReportScreen> createState() => _SimpleReportScreenState();
}

enum _Period { today, month, year, custom }

class _SimpleReportScreenState extends ConsumerState<SimpleReportScreen> {
  static const _grey = Color(0xFF8A8FA3);
  static const _pageSize = 50;
  static const _mon = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  _Period _period = _Period.month;
  late DateTime _from;
  late DateTime _to;
  String? _branchId; // admin ka filter
  String _search = '';
  int _page = 0;

  SimpleReportData? _data;
  Object? _error;
  bool _loading = true;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _applyPeriod(_Period.month, load: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  static DateTime _today() {
    final t = DateTime.now().toUtc().add(const Duration(hours: 5));
    return DateTime(t.year, t.month, t.day);
  }

  void _applyPeriod(_Period p, {bool load = true}) {
    final t = _today();
    switch (p) {
      case _Period.today:
        _from = t;
        _to = t;
      case _Period.month:
        _from = DateTime(t.year, t.month, 1);
        _to = t;
      case _Period.year:
        _from = DateTime(t.year, 1, 1);
        _to = t;
      case _Period.custom:
        break;
    }
    _period = p;
    if (load) _load();
  }

  Future<void> _pickCustom() async {
    final r = await showDialog<(DateTime?, DateTime?)>(
      context: context,
      builder: (_) => ReportDateFilterDialog(initialStart: _from, initialEnd: _to),
    );
    if (r == null || r.$1 == null) return;
    setState(() {
      _from = r.$1!;
      _to = r.$2 ?? r.$1!;
      if (_to.isBefore(_from)) _to = _from;
      _period = _Period.custom;
    });
    _load();
  }

  String? get _effectiveBranch => widget.restrictToOwnBranch
      ? ref.read(currentBranchIdProvider)
      : _branchId;

  Future<void> _load() async {
    final token = ++_token;
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
    });
    try {
      final data = await widget.fetch(
          SimpleReportQuery(_from, _to, _effectiveBranch));
      if (!mounted || token != _token) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || token != _token) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  List<SimpleReportRow> get _filtered {
    final rows = _data?.rows ?? const <SimpleReportRow>[];
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((r) => r.cells.any((c) => c.toLowerCase().contains(q)))
        .toList();
  }

  String get _rangeLabel {
    String d(DateTime x) => '${x.day} ${_mon[x.month - 1]} ${x.year}';
    return _from == _to ? d(_from) : '${d(_from)} – ${d(_to)}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive(context).isMobile;
    final data = _data;
    final filtered = _filtered;
    final pages = (filtered.length / _pageSize).ceil().clamp(1, 1 << 30);
    final page = _page.clamp(0, pages - 1);
    final shown = filtered.skip(page * _pageSize).take(_pageSize).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(widget.title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const AppIcon(AppIcons.refresh, size: 18),
            onPressed: _load,
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (widget.showDates) ...[
              SegmentedButton<_Period>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: _Period.today, label: Text('Today')),
                  ButtonSegment(value: _Period.month, label: Text('This Month')),
                  ButtonSegment(value: _Period.year, label: Text('This Year')),
                  ButtonSegment(value: _Period.custom, label: Text('Custom')),
                ],
                selected: {_period},
                onSelectionChanged: (s) {
                  if (s.first == _Period.custom) {
                    _pickCustom();
                  } else {
                    setState(() => _applyPeriod(s.first, load: false));
                    _load();
                  }
                },
              ),
              Text(_rangeLabel,
                  style: const TextStyle(color: _grey, fontSize: 13)),
            ],
            if (!widget.restrictToOwnBranch)
              ReportBranchFilterDropdown(
                value: _branchId,
                onChanged: (v) {
                  setState(() => _branchId = v);
                  _load();
                },
              ),
            SizedBox(
              width: 240,
              child: TextField(cursorHeight: 16, 
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (v) => setState(() {
                  _search = v;
                  _page = 0;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (data != null && data.cards.isNotEmpty)
          isMobile
              ? Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final c in data.cards)
                    SizedBox(
                        width: (MediaQuery.of(context).size.width - 50) / 2,
                        child: _card(c)),
                ])
              : Row(children: [
                  for (var i = 0; i < data.cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(child: _card(data.cards[i])),
                  ],
                ]),
        const SizedBox(height: 14),
        Expanded(
          child: _loading && data == null
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: ErrorView(error: _error, onRetry: _load))
                  : data == null || filtered.isEmpty
                      ? const Center(
                          child: Text('No records found',
                              style: TextStyle(color: _grey)))
                      : Column(children: [
                          Expanded(
                            child: Stack(children: [
                              SingleChildScrollView(
                                child: ReportTableShell(
                                  columns: [
                                    for (var i = 0; i < data.columns.length; i++)
                                      DataColumn(
                                        label: Text(data.columns[i]),
                                        numeric: data.numericColumns.contains(i),
                                      ),
                                  ],
                                  rows: [
                                    for (final r in shown)
                                      DataRow(
                                        onSelectChanged: r.detail == null
                                            ? null
                                            : (_) => _openDetail(r),
                                        cells: [
                                          for (final c in r.cells)
                                            DataCell(Text(c)),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              if (_loading)
                                const Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: LinearProgressIndicator()),
                            ]),
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            Text('${filtered.length} records',
                                style: const TextStyle(color: _grey)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: page > 0
                                  ? () => setState(() => _page = page - 1)
                                  : null,
                            ),
                            Text('${page + 1} / $pages'),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: page < pages - 1
                                  ? () => setState(() => _page = page + 1)
                                  : null,
                            ),
                          ]),
                        ]),
        ),
      ]),
    );
  }

  Widget _card(SimpleReportCard c) => ReportSummaryCard(
      label: c.label, value: c.value, icon: c.icon, color: c.color);

  Future<void> _openDetail(SimpleReportRow r) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _DetailDialog(load: r.detail!),
    );
  }
}

class _DetailDialog extends StatefulWidget {
  final Future<SimpleDetail> Function() load;
  const _DetailDialog({required this.load});

  @override
  State<_DetailDialog> createState() => _DetailDialogState();
}

class _DetailDialogState extends State<_DetailDialog> {
  late final Future<SimpleDetail> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
        child: FutureBuilder<SimpleDetail>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorView(error: snap.error),
              );
            }
            final d = snap.data!;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(d.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final f in d.fields)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 170,
                                    child: Text(f.$1,
                                        style: const TextStyle(
                                            color: Color(0xFF8A8FA3))),
                                  ),
                                  Expanded(
                                    child: Text(f.$2,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          if (d.tableRows.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            ReportTableShell(
                              columns: [
                                for (final c in d.tableColumns)
                                  DataColumn(label: Text(c)),
                              ],
                              rows: [
                                for (final r in d.tableRows)
                                  DataRow(cells: [
                                    for (final c in r) DataCell(Text(c)),
                                  ]),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
