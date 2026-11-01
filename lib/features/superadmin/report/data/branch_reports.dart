import 'dart:math' as math;
import 'package:flutter/material.dart' show Color;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import '../presentation/widgets/simple_report.dart';

/// Admin + branch dono ki "Reports" screens ka data. Har function
/// [SimpleReportQuery] (date range + branch) leta hai aur cards / table /
/// row-detail wala [SimpleReportData] banata hai. Branch user ke liye
/// [SimpleReportQuery.branchId] hamesha uski apni branch hoti hai.

SupabaseClient get _c => Supabase.instance.client;

const _blue = Color(0xFF3E63DD);
const _green = Color(0xFF22A06B);
const _orange = Color(0xFFE56A00);
const _red = Color(0xFFE5484D);

double _n(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
String _s(dynamic v) => v == null ? '—' : '$v';
DateTime _t(dynamic v) => DateTime.parse(v as String);

String _cap(String? s) =>
    (s == null || s.isEmpty) ? '—' : s[0].toUpperCase() + s.substring(1);

/// PostgREST ek request mein ~1000 rows deta hai — sab pages le aata hai.
Future<List<Map<String, dynamic>>> _all(
    PostgrestTransformBuilder<List<Map<String, dynamic>>> Function() build) async {
  const chunk = 1000;
  final all = <Map<String, dynamic>>[];
  for (var from = 0;; from += chunk) {
    final page = await build().range(from, from + chunk - 1);
    all.addAll(page);
    if (page.length < chunk) break;
  }
  return all;
}

/// [table].[idCol] IN ids — chhote chhote hisson mein.
Future<List<Map<String, dynamic>>> _byIds(
    String table, String idCol, Iterable<Object?> ids,
    {String select = '*'}) async {
  final list = {for (final i in ids) if (i != null) i.toString()}.toList();
  final out = <Map<String, dynamic>>[];
  for (var i = 0; i < list.length; i += 40) {
    final part = list.sublist(i, math.min(i + 40, list.length));
    out.addAll(await _all(() =>
        _c.from(table).select(select).inFilter(idCol, part).order('id')));
  }
  return out;
}

Future<Map<String, String>> _names(
    String table, String col, Iterable<Object?> ids) async {
  final rows = await _byIds(table, 'id', ids, select: 'id, $col');
  return {for (final r in rows) r['id'].toString(): (r[col] ?? '').toString()};
}

Future<Map<String, String>> _branchNames() async {
  final rows = await _c.from('branches').select('id, branch_name');
  return {for (final r in rows) r['id'].toString(): r['branch_name'] as String};
}

String _pairsOf(List<Map<String, dynamic>> items) =>
    '${items.fold<int>(0, (s, r) => s + _i(r['quantity']))}';

// ── 1. Cash Counter ──────────────────────────────────────────────────────

Future<SimpleReportData> cashCounterReport(SimpleReportQuery q) async {
  final rows = await _all(() {
    var b = _c
        .from('branch_cash_counter')
        .select()
        .gte('created_at', q.startIso)
        .lt('created_at', q.endIso);
    if (q.branchId != null) b = b.eq('branch_id', q.branchId!);
    return b.order('created_at', ascending: false).order('id');
  });
  final showBranch = q.branchId == null;
  final bn = showBranch ? await _branchNames() : const <String, String>{};

  double sum(String k) => rows.fold(0.0, (s, r) => s + _n(r[k]));
  double net(Map<String, dynamic> r) =>
      _n(r['total_sale']) -
      _n(r['return_sale']) -
      _n(r['return_amount_in_exchange']) +
      _n(r['received_amount_in_exchange']);
  final netTotal = rows.fold(0.0, (s, r) => s + net(r));

  return SimpleReportData(
    cards: [
      SimpleReportCard('Total Sale', rs(sum('total_sale')),
          AppIcons.listAlt, _blue),
      SimpleReportCard('Net Sale', rs(netTotal),
          AppIcons.trendingUpOutlined, _green),
      SimpleReportCard('Expense', rs(sum('expense')),
          AppIcons.paymentsOutlined, _orange),
      SimpleReportCard('Paid to Head Office', rs(sum('paid_amount')),
          AppIcons.accountBalanceWalletOutlined, _green),
    ],
    columns: [
      'Date',
      if (showBranch) 'Branch',
      'Cash Sale',
      'Card Sale',
      'Total Sale',
      'Return',
      'Net Sale',
      'Expense',
      'Gross',
      'Paid',
      'Total Amount',
    ],
    numericColumns: {for (var i = showBranch ? 2 : 1; i < (showBranch ? 11 : 10); i++) i},
    rows: [
      for (final r in rows)
        SimpleReportRow(
          [
            fmtDate(_t(r['created_at'])),
            if (showBranch) bn[r['branch_id'].toString()] ?? '—',
            rs(_n(r['cash_sale'])),
            rs(_n(r['card_sale'])),
            rs(_n(r['total_sale'])),
            rs(_n(r['return_sale'])),
            rs(net(r)),
            rs(_n(r['expense'])),
            rs(_n(r['gross'])),
            rs(_n(r['paid_amount'])),
            rs(_n(r['total_amount'])),
          ],
          detail: () async {
            final ex = await _c
                .from('expense_entries')
                .select()
                .eq('branch_cash_counter_id', r['id'] as String)
                .order('created_at');
            final heads = await _names(
                'expense_heads', 'name', ex.map((e) => e['expense_head_id']));
            return SimpleDetail(
              title: 'Cash Counter — ${fmtDate(_t(r['created_at']))}',
              fields: [
                if (showBranch) ('Branch', bn[r['branch_id'].toString()] ?? '—'),
                ('Cash Sale', rs(_n(r['cash_sale']))),
                ('Card Sale', rs(_n(r['card_sale']))),
                ('Total Sale', rs(_n(r['total_sale']))),
                ('Return Sale', rs(_n(r['return_sale']))),
                ('Return in Exchange', rs(_n(r['return_amount_in_exchange']))),
                ('Received in Exchange',
                    rs(_n(r['received_amount_in_exchange']))),
                ('Net Sale', rs(net(r))),
                ('Expense', rs(_n(r['expense']))),
                ('Gross', rs(_n(r['gross']))),
                ('Paid Amount', rs(_n(r['paid_amount']))),
                ('Total Amount', rs(_n(r['total_amount']))),
              ],
              tableColumns: const ['Expense Head', 'Amount', 'Note'],
              tableRows: [
                for (final e in ex)
                  [
                    heads[e['expense_head_id'].toString()] ?? '—',
                    rs(_n(e['amount'])),
                    _s(e['note']),
                  ],
              ],
            );
          },
        ),
    ],
  );
}

// ── 2. Expense ───────────────────────────────────────────────────────────

Future<SimpleReportData> expenseReport(SimpleReportQuery q) async {
  final rows = await _all(() {
    var b = _c
        .from('expense_entries')
        .select()
        .gte('created_at', q.startIso)
        .lt('created_at', q.endIso);
    if (q.branchId != null) b = b.eq('branch_id', q.branchId!);
    return b.order('created_at', ascending: false).order('id');
  });
  final showBranch = q.branchId == null;
  final bn = showBranch ? await _branchNames() : const <String, String>{};
  final heads =
      await _names('expense_heads', 'name', rows.map((r) => r['expense_head_id']));

  final byHead = <String, double>{};
  for (final r in rows) {
    final h = heads[r['expense_head_id'].toString()] ?? '—';
    byHead[h] = (byHead[h] ?? 0) + _n(r['amount']);
  }
  final top = byHead.entries.isEmpty
      ? null
      : (byHead.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
          .first;
  final total = rows.fold(0.0, (s, r) => s + _n(r['amount']));

  return SimpleReportData(
    cards: [
      SimpleReportCard('Total Expense', rs(total), AppIcons.paymentsOutlined, _red),
      SimpleReportCard('Entries', '${rows.length}', AppIcons.listAlt, _blue),
      SimpleReportCard('Expense Heads Used', '${byHead.length}',
          AppIcons.inventory2Outlined, _orange),
      SimpleReportCard(
          'Highest Head',
          top == null ? '—' : '${top.key} • ${rs(top.value)}',
          AppIcons.trendingUpOutlined,
          _green),
    ],
    columns: ['Date', if (showBranch) 'Branch', 'Expense Head', 'Amount', 'Note'],
    numericColumns: {showBranch ? 3 : 2},
    rows: [
      for (final r in rows)
        SimpleReportRow(
          [
            fmtDateTime(_t(r['created_at'])),
            if (showBranch) bn[r['branch_id'].toString()] ?? '—',
            heads[r['expense_head_id'].toString()] ?? '—',
            rs(_n(r['amount'])),
            _s(r['note']),
          ],
          detail: () async => SimpleDetail(
            title: 'Expense — ${heads[r['expense_head_id'].toString()] ?? ''}',
            fields: [
              ('Date', fmtDateTime(_t(r['created_at']))),
              if (showBranch) ('Branch', bn[r['branch_id'].toString()] ?? '—'),
              ('Expense Head', heads[r['expense_head_id'].toString()] ?? '—'),
              ('Amount', rs(_n(r['amount']))),
              ('Note', _s(r['note'])),
            ],
          ),
        ),
    ],
  );
}

// ── 3. Customers ─────────────────────────────────────────────────────────

Future<SimpleReportData> customerReport(SimpleReportQuery q) async {
  final customers = await _all(() {
    var b = _c.from('customers').select();
    if (q.branchId != null) b = b.eq('branch_id', q.branchId!);
    return b.order('name').order('id');
  });
  final invoices = await _all(() {
    var b = _c
        .from('sale_invoices')
        .select('id, invoice_number, customer_id, total_amount, created_at')
        .gte('created_at', q.startIso)
        .lt('created_at', q.endIso);
    if (q.branchId != null) b = b.eq('branch_id', q.branchId!);
    return b.order('created_at', ascending: false).order('id');
  });
  final returns = await _all(() {
    var b = _c
        .from('sale_returns')
        .select('id, customer_id, total_amount')
        .gte('created_at', q.startIso)
        .lt('created_at', q.endIso);
    if (q.branchId != null) b = b.eq('branch_id', q.branchId!);
    return b.order('id');
  });
  final showBranch = q.branchId == null;
  final bn = showBranch ? await _branchNames() : const <String, String>{};

  final invBy = <String, List<Map<String, dynamic>>>{};
  for (final r in invoices) {
    if (r['customer_id'] != null) {
      invBy.putIfAbsent(r['customer_id'].toString(), () => []).add(r);
    }
  }
  final retBy = <String, double>{};
  for (final r in returns) {
    if (r['customer_id'] != null) {
      final k = r['customer_id'].toString();
      retBy[k] = (retBy[k] ?? 0) + _n(r['total_amount']);
    }
  }

  double saleOf(String id) =>
      (invBy[id] ?? const []).fold(0.0, (s, r) => s + _n(r['total_amount']));
  final list = [...customers]..sort((a, b) {
      final na = saleOf(a['id'].toString()) - (retBy[a['id'].toString()] ?? 0);
      final nb = saleOf(b['id'].toString()) - (retBy[b['id'].toString()] ?? 0);
      return nb.compareTo(na);
    });

  final active = list.where((c) => invBy.containsKey(c['id'].toString())).length;
  final netTotal = list.fold(
      0.0,
      (s, c) =>
          s + saleOf(c['id'].toString()) - (retBy[c['id'].toString()] ?? 0));
  final points = list.fold<int>(0, (s, c) => s + _i(c['loyalty_points']));

  return SimpleReportData(
    cards: [
      SimpleReportCard('Customers', '${list.length}', AppIcons.peopleOutline, _blue),
      SimpleReportCard('Bought in Period', '$active',
          AppIcons.checkCircleOutline, _green),
      SimpleReportCard('Net Sale', rs(netTotal), AppIcons.listAlt, _orange),
      SimpleReportCard('Loyalty Points', '$points', AppIcons.percentOutlined, _blue),
    ],
    columns: [
      'Customer',
      'Phone',
      if (showBranch) 'Branch',
      'Invoices',
      'Sale',
      'Return',
      'Net Sale',
      'Points',
      'Last Purchase',
    ],
    numericColumns: {for (var i = showBranch ? 3 : 2; i < (showBranch ? 8 : 7); i++) i},
    rows: [
      for (final c in list)
        () {
          final id = c['id'].toString();
          final inv = invBy[id] ?? const <Map<String, dynamic>>[];
          final sale = saleOf(id);
          final ret = retBy[id] ?? 0;
          final last = inv.isEmpty ? '—' : fmtDate(_t(inv.first['created_at']));
          return SimpleReportRow(
            [
              _s(c['name']) + (c['is_walkin'] == true ? ' (Walk-in)' : ''),
              _s(c['phone_number']),
              if (showBranch) bn[c['branch_id'].toString()] ?? '—',
              '${inv.length}',
              rs(sale),
              rs(ret),
              rs(sale - ret),
              '${_i(c['loyalty_points'])}',
              last,
            ],
            detail: () async => SimpleDetail(
              title: _s(c['name']),
              fields: [
                ('Phone', _s(c['phone_number'])),
                ('Address', _s(c['address'])),
                if (showBranch) ('Branch', bn[c['branch_id'].toString()] ?? '—'),
                ('Loyalty Points', '${_i(c['loyalty_points'])}'),
                ('Opening Balance', rs(_n(c['opening_balance']))),
                ('Invoices (period)', '${inv.length}'),
                ('Sale (period)', rs(sale)),
                ('Return (period)', rs(ret)),
                ('Net Sale (period)', rs(sale - ret)),
              ],
              tableColumns: const ['Invoice #', 'Date', 'Amount'],
              tableRows: [
                for (final r in inv)
                  [
                    _s(r['invoice_number']),
                    fmtDateTime(_t(r['created_at'])),
                    rs(_n(r['total_amount'])),
                  ],
              ],
            ),
          );
        }(),
    ],
  );
}

// ── 4. Sale Claims ───────────────────────────────────────────────────────

Future<SimpleReportData> saleClaimReport(SimpleReportQuery q) async {
  final rows = await _all(() {
    var b = _c
        .from('sale_claims')
        .select()
        .gte('created_at', q.startIso)
        .lt('created_at', q.endIso);
    if (q.branchId != null) b = b.eq('branch_id', q.branchId!);
    return b.order('created_at', ascending: false).order('id');
  });
  final showBranch = q.branchId == null;
  final bn = showBranch ? await _branchNames() : const <String, String>{};
  final products =
      await _names('products', 'article_name', rows.map((r) => r['product_id']));
  final sizes = await _names('sizes', 'number', rows.map((r) => r['size_id']));
  final colors = await _names('colors', 'name', rows.map((r) => r['color_id']));
  final customers =
      await _names('customers', 'name', rows.map((r) => r['customer_id']));
  final invoices = await _names(
      'sale_invoices', 'invoice_number', rows.map((r) => r['sale_invoice_id']));

  int count(String s) => rows.where((r) => r['status'] == s).length;
  final value = rows.fold(0.0, (s, r) => s + _n(r['total_price']));

  return SimpleReportData(
    cards: [
      SimpleReportCard('Claims', '${rows.length}', AppIcons.listAlt, _blue),
      SimpleReportCard('Pending', '${count('pending')}',
          AppIcons.accessTimeOutlined, _orange),
      SimpleReportCard('Approved', '${count('approved')}',
          AppIcons.checkCircleOutline, _green),
      SimpleReportCard('Rejected', '${count('rejected')}',
          AppIcons.errorOutline, _red),
      SimpleReportCard('Claim Value', rs(value), AppIcons.paymentsOutlined, _blue),
    ],
    columns: [
      'Claim #',
      'Date',
      if (showBranch) 'Branch',
      'Article',
      'Size',
      'Qty',
      'Amount',
      'Status',
      'Reason',
    ],
    numericColumns: {showBranch ? 5 : 4, showBranch ? 6 : 5},
    rows: [
      for (final r in rows)
        SimpleReportRow(
          [
            _s(r['claim_number']),
            fmtDate(_t(r['created_at'])),
            if (showBranch) bn[r['branch_id'].toString()] ?? '—',
            products[r['product_id'].toString()] ?? '—',
            sizes[r['size_id'].toString()] ?? '—',
            '${_i(r['quantity'])}',
            rs(_n(r['total_price'])),
            _cap(r['status'] as String?),
            _s(r['reason']),
          ],
          detail: () async => SimpleDetail(
            title: 'Claim ${_s(r['claim_number'])}',
            fields: [
              if (showBranch) ('Branch', bn[r['branch_id'].toString()] ?? '—'),
              ('Status', _cap(r['status'] as String?)),
              ('Claim Date', fmtDateTime(_t(r['claim_date'] ?? r['created_at']))),
              ('Sale Date',
                  r['sale_date'] == null ? '—' : fmtDateTime(_t(r['sale_date']))),
              ('Invoice #', invoices[r['sale_invoice_id'].toString()] ?? '—'),
              ('Customer', customers[r['customer_id'].toString()] ?? '—'),
              ('Article', products[r['product_id'].toString()] ?? '—'),
              ('Size / Color',
                  '${sizes[r['size_id'].toString()] ?? '—'} / ${colors[r['color_id'].toString()] ?? '—'}'),
              ('Barcode', _s(r['barcode'])),
              ('Quantity', '${_i(r['quantity'])}'),
              ('Sale Price', rs(_n(r['sale_price']))),
              ('Total', rs(_n(r['total_price']))),
              ('Reason', _s(r['reason'])),
              ('Shoe Condition', _s(r['shoe_condition'])),
              ('Review Remarks', _s(r['review_remarks'])),
              ('Reviewed At',
                  r['reviewed_at'] == null ? '—' : fmtDateTime(_t(r['reviewed_at']))),
            ],
          ),
        ),
    ],
  );
}

// ── 5. Stock Assign ──────────────────────────────────────────────────────

Future<SimpleReportData> stockAssignReport(SimpleReportQuery q) async {
  final rows = await _all(() {
    var b = _c
        .from('assign_stock_to_branch')
        .select()
        .gte('created_at', q.startIso)
        .lt('created_at', q.endIso);
    if (q.branchId != null) {
      b = b.or('assigned_to.eq.${q.branchId},assigned_by.eq.${q.branchId}');
    }
    return b.order('created_at', ascending: false).order('id');
  });
  final bn = await _branchNames();
  final items = await _byIds(
      'assign_stock_to_branch_items', 'assignment_id', rows.map((r) => r['id']),
      select: 'id, assignment_id, product_id, size_id, barcode, quantity, sale_price');
  final itemsBy = <String, List<Map<String, dynamic>>>{};
  for (final it in items) {
    itemsBy.putIfAbsent(it['assignment_id'].toString(), () => []).add(it);
  }
  double valueOf(List<Map<String, dynamic>> l) =>
      l.fold(0.0, (s, r) => s + _i(r['quantity']) * _n(r['sale_price']));
  String nameOf(dynamic id) => bn[id.toString()] ?? 'Head Office';
  final own = q.branchId != null;

  int pairs = 0;
  double value = 0;
  for (final r in rows) {
    final l = itemsBy[r['id'].toString()] ?? const [];
    pairs += l.fold<int>(0, (s, x) => s + _i(x['quantity']));
    value += valueOf(l);
  }
  final pending = rows.where((r) => r['status'] == 'pending').length;

  return SimpleReportData(
    cards: [
      SimpleReportCard('Assignments', '${rows.length}', AppIcons.listAlt, _blue),
      SimpleReportCard('Pairs', '$pairs', AppIcons.inventory2Outlined, _green),
      SimpleReportCard('Value', rs(value), AppIcons.paymentsOutlined, _orange),
      SimpleReportCard('Pending', '$pending', AppIcons.accessTimeOutlined, _red),
    ],
    columns: [
      'Assignment #',
      'Date',
      if (own) 'Type',
      'From',
      'To',
      'Pairs',
      'Value',
      'Status',
    ],
    numericColumns: {own ? 5 : 4, own ? 6 : 5},
    rows: [
      for (final r in rows)
        () {
          final l = itemsBy[r['id'].toString()] ?? const <Map<String, dynamic>>[];
          return SimpleReportRow(
            [
              _s(r['assignment_number']),
              fmtDate(_t(r['created_at'])),
              if (own) r['assigned_to'].toString() == q.branchId ? 'Received' : 'Sent',
              nameOf(r['assigned_by']),
              nameOf(r['assigned_to']),
              _pairsOf(l),
              rs(valueOf(l)),
              _cap(r['status'] as String?),
            ],
            detail: () async {
              final products = await _names(
                  'products', 'article_name', l.map((x) => x['product_id']));
              final sizes =
                  await _names('sizes', 'number', l.map((x) => x['size_id']));
              return SimpleDetail(
                title: 'Assignment ${_s(r['assignment_number'])}',
                fields: [
                  ('From', nameOf(r['assigned_by'])),
                  ('To', nameOf(r['assigned_to'])),
                  ('Status', _cap(r['status'] as String?)),
                  ('Assigned', fmtDateTime(_t(r['assigned_at'] ?? r['created_at']))),
                  ('Accepted',
                      r['accepted_at'] == null ? '—' : fmtDateTime(_t(r['accepted_at']))),
                  ('Notes', _s(r['notes'])),
                  ('Pairs', _pairsOf(l)),
                  ('Value', rs(valueOf(l))),
                ],
                tableColumns: const ['Article', 'Size', 'Barcode', 'Qty', 'Sale Price'],
                tableRows: [
                  for (final x in l)
                    [
                      products[x['product_id'].toString()] ?? '—',
                      sizes[x['size_id'].toString()] ?? '—',
                      _s(x['barcode']),
                      '${_i(x['quantity'])}',
                      rs(_n(x['sale_price'])),
                    ],
                ],
              );
            },
          );
        }(),
    ],
  );
}

// ── 6. Stock Returns ─────────────────────────────────────────────────────

Future<SimpleReportData> stockReturnReport(SimpleReportQuery q) async {
  final toBranch = await _all(() {
    var b = _c
        .from('branch_stock_returns')
        .select()
        .gte('created_at', q.startIso)
        .lt('created_at', q.endIso);
    if (q.branchId != null) {
      b = b.or('from_branch_id.eq.${q.branchId},to_branch_id.eq.${q.branchId}');
    }
    return b.order('created_at', ascending: false).order('id');
  });
  final toAdmin = await _all(() {
    var b = _c
        .from('branch_return_to_warehouse')
        .select()
        .gte('created_at', q.startIso)
        .lt('created_at', q.endIso);
    if (q.branchId != null) b = b.eq('branch_id', q.branchId!);
    return b.order('created_at', ascending: false).order('id');
  });
  final bn = await _branchNames();
  final itemsB = await _byIds(
      'branch_stock_return_items', 'return_id', toBranch.map((r) => r['id']),
      select: 'id, return_id, product_id, size_id, barcode, quantity, sale_price');
  final itemsW = await _byIds('branch_return_to_warehouse_items', 'return_id',
      toAdmin.map((r) => r['id']),
      select: 'id, return_id, product_id, size_id, barcode, quantity, sale_price');
  Map<String, List<Map<String, dynamic>>> group(List<Map<String, dynamic>> l) {
    final m = <String, List<Map<String, dynamic>>>{};
    for (final it in l) {
      m.putIfAbsent(it['return_id'].toString(), () => []).add(it);
    }
    return m;
  }

  final byB = group(itemsB);
  final byW = group(itemsW);
  double valueOf(List<Map<String, dynamic>> l) =>
      l.fold(0.0, (s, r) => s + _i(r['quantity']) * _n(r['sale_price']));

  // Ek hi list: (date, cells, detail)
  final entries = <({DateTime at, SimpleReportRow row, int pairs, double value})>[];
  final own = q.branchId != null;

  for (final r in toBranch) {
    final l = byB[r['id'].toString()] ?? const <Map<String, dynamic>>[];
    final from = bn[r['from_branch_id'].toString()] ?? '—';
    final to = bn[r['to_branch_id'].toString()] ?? '—';
    final type = !own
        ? 'Branch to Branch'
        : (r['from_branch_id'].toString() == q.branchId ? 'Sent to Branch' : 'Incoming from Branch');
    entries.add((
      at: _t(r['created_at']),
      pairs: l.fold<int>(0, (s, x) => s + _i(x['quantity'])),
      value: valueOf(l),
      row: SimpleReportRow(
        [
          _s(r['return_number']),
          fmtDate(_t(r['created_at'])),
          type,
          from,
          to,
          _pairsOf(l),
          rs(valueOf(l)),
          _cap(r['status'] as String?),
        ],
        detail: () => _returnDetail(r, type, from, to, l),
      ),
    ));
  }
  for (final r in toAdmin) {
    final l = byW[r['id'].toString()] ?? const <Map<String, dynamic>>[];
    final from = bn[r['branch_id'].toString()] ?? '—';
    const type = 'Return to Admin';
    entries.add((
      at: _t(r['created_at']),
      pairs: l.fold<int>(0, (s, x) => s + _i(x['quantity'])),
      value: valueOf(l),
      row: SimpleReportRow(
        [
          _s(r['return_number']),
          fmtDate(_t(r['created_at'])),
          type,
          from,
          'Admin / Warehouse',
          _pairsOf(l),
          rs(valueOf(l)),
          _cap(r['status'] as String?),
        ],
        detail: () => _returnDetail(r, type, from, 'Admin / Warehouse', l),
      ),
    ));
  }
  entries.sort((a, b) => b.at.compareTo(a.at));

  final pairs = entries.fold<int>(0, (s, e) => s + e.pairs);
  final value = entries.fold(0.0, (s, e) => s + e.value);
  final pending = entries.where((e) => e.row.cells.last == 'Pending').length;

  return SimpleReportData(
    cards: [
      SimpleReportCard('Returns', '${entries.length}', AppIcons.listAlt, _blue),
      SimpleReportCard('Pairs', '$pairs', AppIcons.inventory2Outlined, _green),
      SimpleReportCard('Value', rs(value), AppIcons.paymentsOutlined, _orange),
      SimpleReportCard('Pending', '$pending', AppIcons.accessTimeOutlined, _red),
    ],
    columns: const [
      'Return #', 'Date', 'Type', 'From', 'To', 'Pairs', 'Value', 'Status'
    ],
    numericColumns: const {5, 6},
    rows: [for (final e in entries) e.row],
  );
}

Future<SimpleDetail> _returnDetail(Map<String, dynamic> r, String type,
    String from, String to, List<Map<String, dynamic>> l) async {
  final products =
      await _names('products', 'article_name', l.map((x) => x['product_id']));
  final sizes = await _names('sizes', 'number', l.map((x) => x['size_id']));
  return SimpleDetail(
    title: 'Return ${_s(r['return_number'])}',
    fields: [
      ('Type', type),
      ('From', from),
      ('To', to),
      ('Status', _cap(r['status'] as String?)),
      ('Returned', fmtDateTime(_t(r['returned_at'] ?? r['created_at']))),
      ('Accepted',
          r['accepted_at'] == null ? '—' : fmtDateTime(_t(r['accepted_at']))),
      ('Notes', _s(r['notes'])),
      ('Pairs', _pairsOf(l)),
    ],
    tableColumns: const ['Article', 'Size', 'Barcode', 'Qty', 'Sale Price'],
    tableRows: [
      for (final x in l)
        [
          products[x['product_id'].toString()] ?? '—',
          sizes[x['size_id'].toString()] ?? '—',
          _s(x['barcode']),
          '${_i(x['quantity'])}',
          rs(_n(x['sale_price'])),
        ],
    ],
  );
}

// ── 7. Stock (brand x category summary) ──────────────────────────────────

Future<SimpleReportData> stockReport(SimpleReportQuery q) async {
  final res = await _c.rpc('branch_stock_group_report',
      params: {'p_branch_id': q.branchId});
  final rows = [for (final r in res as List) (r as Map).cast<String, dynamic>()];
  final showBranch = q.branchId == null;

  int sum(String k) => rows.fold(0, (s, r) => s + _i(r[k]));
  final value = rows.fold(0.0, (s, r) => s + _n(r['stock_value']));

  return SimpleReportData(
    cards: [
      SimpleReportCard('Pairs in Stock', '${sum('pairs')}',
          AppIcons.inventory2Outlined, _blue),
      SimpleReportCard('Stock Value', rs(value), AppIcons.paymentsOutlined, _green),
      SimpleReportCard('Low Stock Sizes', '${sum('low_skus')}',
          AppIcons.accessTimeOutlined, _orange),
      SimpleReportCard('Out of Stock Sizes', '${sum('out_skus')}',
          AppIcons.errorOutline, _red),
      SimpleReportCard('Buy 1 Get 1 Sizes', '${sum('b1g1_skus')}',
          AppIcons.sellOutlined, _orange),
    ],
    columns: [
      if (showBranch) 'Branch',
      'Brand',
      'Category',
      'Articles',
      'Sizes',
      'Pairs',
      'Value',
      'Low',
      'Out',
      'Discount',
      'B1G1',
    ],
    numericColumns: {for (var i = showBranch ? 3 : 2; i < (showBranch ? 11 : 10); i++) i},
    rows: [
      for (final r in rows)
        SimpleReportRow(
          [
            if (showBranch) _s(r['branch_name']),
            _s(r['brand_name']),
            _s(r['category_name']),
            '${_i(r['articles'])}',
            '${_i(r['skus'])}',
            '${_i(r['pairs'])}',
            rs(_n(r['stock_value'])),
            '${_i(r['low_skus'])}',
            '${_i(r['out_skus'])}',
            '${_i(r['discount_skus'])}',
            '${_i(r['b1g1_skus'])}',
          ],
          detail: () async {
            final stock = await _all(() => _c
                .from('v_branch_stock')
                .select(
                    'product_name, color_name, type_name, size_name, quantity, sale_price, discount')
                .eq('branch_id', r['branch_id'] as String)
                .eq('brand_id', r['brand_id'] as String)
                .eq('category_id', r['category_id'] as String)
                .order('id'));
            // Article (naam + color + type) ke hisab se jama.
            final by = <String, ({int pairs, int sizes, double value, int low})>{};
            for (final s in stock) {
              final k =
                  '${_s(s['product_name'])} • ${_s(s['color_name'])} • ${_s(s['type_name'])}';
              final p = by[k] ?? (pairs: 0, sizes: 0, value: 0.0, low: 0);
              final qty = _i(s['quantity']);
              by[k] = (
                pairs: p.pairs + qty,
                sizes: p.sizes + 1,
                value: p.value + qty * _n(s['sale_price']),
                low: p.low + (qty < 5 ? 1 : 0),
              );
            }
            final list = by.entries.toList()
              ..sort((a, b) => b.value.pairs.compareTo(a.value.pairs));
            return SimpleDetail(
              title: '${_s(r['brand_name'])} — ${_s(r['category_name'])}',
              fields: [
                ('Branch', _s(r['branch_name'])),
                ('Articles', '${_i(r['articles'])}'),
                ('Sizes', '${_i(r['skus'])}'),
                ('Pairs', '${_i(r['pairs'])}'),
                ('Value', rs(_n(r['stock_value']))),
              ],
              tableColumns: const [
                'Article • Color • Type', 'Sizes', 'Pairs', 'Value', 'Low/Out Sizes'
              ],
              tableRows: [
                for (final e in list)
                  [
                    e.key,
                    '${e.value.sizes}',
                    '${e.value.pairs}',
                    rs(e.value.value),
                    '${e.value.low}',
                  ],
              ],
            );
          },
        ),
    ],
  );
}

// ── 8. Branch Payments ───────────────────────────────────────────────────

Future<SimpleReportData> branchPaymentReport(SimpleReportQuery q) async {
  final rows = await _all(() {
    var b = _c
        .from('branch_payments')
        .select()
        .gte('created_at', q.startIso)
        .lt('created_at', q.endIso);
    if (q.branchId != null) b = b.eq('branch_id', q.branchId!);
    return b.order('created_at', ascending: false).order('id');
  });
  final showBranch = q.branchId == null;
  final bn = showBranch ? await _branchNames() : const <String, String>{};

  double sumBy(String? status) => rows
      .where((r) => status == null || r['status'] == status)
      .fold(0.0, (s, r) => s + _n(r['amount']));
  int countBy(String status) => rows.where((r) => r['status'] == status).length;

  return SimpleReportData(
    cards: [
      SimpleReportCard('Payments', '${rows.length}', AppIcons.listAlt, _blue),
      SimpleReportCard('Accepted', rs(sumBy('accepted')),
          AppIcons.checkCircleOutline, _green),
      SimpleReportCard('Pending', rs(sumBy('pending')),
          AppIcons.accessTimeOutlined, _orange),
      SimpleReportCard('Rejected', '${countBy('rejected')}',
          AppIcons.errorOutline, _red),
    ],
    columns: [
      'Payment #',
      'Date',
      if (showBranch) 'Branch',
      'Amount',
      'Status',
      'Accepted At',
      'Notes',
    ],
    numericColumns: {showBranch ? 3 : 2},
    rows: [
      for (final r in rows)
        SimpleReportRow(
          [
            _s(r['payment_number']),
            fmtDate(_t(r['paid_at'] ?? r['created_at'])),
            if (showBranch) bn[r['branch_id'].toString()] ?? '—',
            rs(_n(r['amount'])),
            _cap(r['status'] as String?),
            r['accepted_at'] == null ? '—' : fmtDateTime(_t(r['accepted_at'])),
            _s(r['notes']),
          ],
          detail: () async => SimpleDetail(
            title: 'Payment ${_s(r['payment_number'])}',
            fields: [
              if (showBranch) ('Branch', bn[r['branch_id'].toString()] ?? '—'),
              ('Amount', rs(_n(r['amount']))),
              ('Status', _cap(r['status'] as String?)),
              ('Paid', fmtDateTime(_t(r['paid_at'] ?? r['created_at']))),
              ('Accepted',
                  r['accepted_at'] == null ? '—' : fmtDateTime(_t(r['accepted_at']))),
              ('Notes', _s(r['notes'])),
            ],
          ),
        ),
    ],
  );
}
