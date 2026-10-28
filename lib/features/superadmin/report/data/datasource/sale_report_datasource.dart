import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../branch/sale_exchange/data/model/sale_exchange_model.dart';
import '../../../../branch/sale_invoice/data/model/sale_invoice_model.dart';
import '../../../../branch/sale_return/data/model/sale_return_model.dart';
import '../model/report_page_result.dart';
import '../model/sale_summary_totals.dart';
import '../model/sale_transaction_row.dart';

/// Admin-side reports — sab branches ka data (koi branch_id filter nahi),
/// optional start/end date range ke sath. Har method do queries chalata hai:
/// ek halki "totals" query (poori filtered list, sirf jitne columns totals
/// ke liye chahiye) aur ek "page" query (`.range()` se server-side
/// paginated, full embeds ke sath — table mein dikhane ke liye).
class SaleReportDatasource {
  final SupabaseClient _client;
  SaleReportDatasource(this._client);

  /// Local (Asia/Karachi) calendar date ko us din ki shuruat ka UTC instant
  /// deta hai (Karachi = UTC+5, is liye local midnight = UTC 19:00 pichla din).
  static DateTime _startOfDayUtc(DateTime local) =>
      DateTime.utc(local.year, local.month, local.day).subtract(const Duration(hours: 5));

  /// Agle din ki shuruat ka UTC instant — exclusive upper bound ke liye.
  static DateTime _startOfNextDayUtc(DateTime local) =>
      _startOfDayUtc(local.add(const Duration(days: 1)));

  PostgrestFilterBuilder<T> _applyDateRange<T>(
    PostgrestFilterBuilder<T> query,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    var q = query;
    if (startDate != null) {
      q = q.gte('created_at', _startOfDayUtc(startDate).toIso8601String());
    }
    if (endDate != null) {
      q = q.lt('created_at', _startOfNextDayUtc(endDate).toIso8601String());
    }
    return q;
  }

  // ── Printer lookup (logo/address/phone header when printing a report row) ──
  // Report print buttons don't have a printer picker like the branch POS
  // screens do, so this resolves whichever printer is assigned to the
  // invoice/return/exchange's own branch and uses that for the receipt header.

  Future<PrinterLookupItem?> fetchBranchPrinter(String branchId) async {
    final res = await _client
        .from('assign_printer')
        .select('id, printer_heads(*)')
        .eq('branch_id', branchId)
        .limit(1);
    final rows = res as List;
    if (rows.isEmpty) return null;
    final row = rows.first as Map<String, dynamic>;
    return PrinterLookupItem.fromHead(
      row['id'].toString(),
      row['printer_heads'] as Map<String, dynamic>?,
    );
  }

  // ── Sale Invoice report ──────────────────────────────────────────────────

  static const _itemProductJoin =
      'quantity, sale_price, discount, total_price, '
      'products(article_name), sizes(number), colors(name)';

  static const _invoiceSelect =
      '*, sale_invoice_payments(payment_type, amount), sale_invoice_items($_itemProductJoin), '
      'customers(name), branches(branch_name)';

  Future<ReportPageResult<SaleInvoiceModel>> fetchInvoiceReport({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    required int page,
    required int pageSize,
  }) async {
    var totalsQuery = _client.from('sale_invoices').select('total_amount, sale_invoice_items(quantity)');
    if (branchId != null && branchId.isNotEmpty) totalsQuery = totalsQuery.eq('branch_id', branchId);
    final totalsRes = await _applyDateRange(totalsQuery, startDate, endDate);
    final totalsList = totalsRes as List;
    var totalQuantity = 0;
    var totalAmount = 0.0;
    for (final row in totalsList) {
      final r = row as Map<String, dynamic>;
      totalAmount += (r['total_amount'] as num? ?? 0).toDouble();
      final items = (r['sale_invoice_items'] as List?) ?? const [];
      for (final it in items) {
        totalQuantity += ((it as Map<String, dynamic>)['quantity'] as num? ?? 0).toInt();
      }
    }

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    var pageQuery = _client.from('sale_invoices').select(_invoiceSelect);
    if (branchId != null && branchId.isNotEmpty) pageQuery = pageQuery.eq('branch_id', branchId);
    final pageRes = await _applyDateRange(pageQuery, startDate, endDate)
        .order('created_at', ascending: false)
        .range(from, to);

    final rows = (pageRes as List)
        .map((e) => SaleInvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReportPageResult(
      rows: rows,
      totalCount: totalsList.length,
      totalQuantity: totalQuantity,
      totalAmount: totalAmount,
    );
  }

  Future<SaleInvoiceModel> fetchInvoiceById(String id) async {
    final row = await _client.from('sale_invoices').select(_invoiceSelect).eq('id', id).single();
    return SaleInvoiceModel.fromJson(row);
  }

  // ── Sale Return report ───────────────────────────────────────────────────

  static const _returnSelect =
      '*, sale_return_payments(payment_type, amount), sale_return_items($_itemProductJoin), '
      'customers(name), branches(branch_name), sale_invoices(invoice_number)';

  Future<ReportPageResult<SaleReturnModel>> fetchReturnReport({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    required int page,
    required int pageSize,
  }) async {
    var totalsQuery = _client.from('sale_returns').select('total_amount, sale_return_items(quantity)');
    if (branchId != null && branchId.isNotEmpty) totalsQuery = totalsQuery.eq('branch_id', branchId);
    final totalsRes = await _applyDateRange(totalsQuery, startDate, endDate);
    final totalsList = totalsRes as List;
    var totalQuantity = 0;
    var totalAmount = 0.0;
    for (final row in totalsList) {
      final r = row as Map<String, dynamic>;
      totalAmount += (r['total_amount'] as num? ?? 0).toDouble();
      final items = (r['sale_return_items'] as List?) ?? const [];
      for (final it in items) {
        totalQuantity += ((it as Map<String, dynamic>)['quantity'] as num? ?? 0).toInt();
      }
    }

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    var pageQuery = _client.from('sale_returns').select(_returnSelect);
    if (branchId != null && branchId.isNotEmpty) pageQuery = pageQuery.eq('branch_id', branchId);
    final pageRes = await _applyDateRange(pageQuery, startDate, endDate)
        .order('created_at', ascending: false)
        .range(from, to);

    final rows = (pageRes as List)
        .map((e) => SaleReturnModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReportPageResult(
      rows: rows,
      totalCount: totalsList.length,
      totalQuantity: totalQuantity,
      totalAmount: totalAmount,
    );
  }

  Future<SaleReturnModel> fetchReturnById(String id) async {
    final row = await _client.from('sale_returns').select(_returnSelect).eq('id', id).single();
    return SaleReturnModel.fromJson(row);
  }

  // ── Sale Exchange report ─────────────────────────────────────────────────
  // "Quantity"/"Sale" yahan naye (exchange mein diye gaye) items se liya
  // jata hai — wahi customer asal mein le kar ja raha hai.

  static const _exchangeSelect =
      '*, sale_exchange_payments(direction, payment_type, amount), '
      'sale_exchange_return_items($_itemProductJoin), sale_exchange_new_items($_itemProductJoin), '
      'customers(name), branches(branch_name), sale_invoices(invoice_number)';

  Future<ReportPageResult<SaleExchangeModel>> fetchExchangeReport({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    required int page,
    required int pageSize,
  }) async {
    var totalsQuery =
        _client.from('sale_exchanges').select('new_total, sale_exchange_new_items(quantity)');
    if (branchId != null && branchId.isNotEmpty) totalsQuery = totalsQuery.eq('branch_id', branchId);
    final totalsRes = await _applyDateRange(totalsQuery, startDate, endDate);
    final totalsList = totalsRes as List;
    var totalQuantity = 0;
    var totalAmount = 0.0;
    for (final row in totalsList) {
      final r = row as Map<String, dynamic>;
      totalAmount += (r['new_total'] as num? ?? 0).toDouble();
      final items = (r['sale_exchange_new_items'] as List?) ?? const [];
      for (final it in items) {
        totalQuantity += ((it as Map<String, dynamic>)['quantity'] as num? ?? 0).toInt();
      }
    }

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    var pageQuery = _client.from('sale_exchanges').select(_exchangeSelect);
    if (branchId != null && branchId.isNotEmpty) pageQuery = pageQuery.eq('branch_id', branchId);
    final pageRes = await _applyDateRange(pageQuery, startDate, endDate)
        .order('created_at', ascending: false)
        .range(from, to);

    final rows = (pageRes as List)
        .map((e) => SaleExchangeModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReportPageResult(
      rows: rows,
      totalCount: totalsList.length,
      totalQuantity: totalQuantity,
      totalAmount: totalAmount,
    );
  }

  Future<SaleExchangeModel> fetchExchangeById(String id) async {
    final row = await _client.from('sale_exchanges').select(_exchangeSelect).eq('id', id).single();
    return SaleExchangeModel.fromJson(row);
  }

  // ── Combined summary (Sale + Return + Exchange cards) ───────────────────
  // Server-side aggregate (RPC `sale_summary_totals`) — rows client tak fetch
  // nahi hoti, is liye bade date range mein bhi tez rehta hai.

  Map<String, dynamic> _summaryParams(
          DateTime? startDate, DateTime? endDate, String? branchId) =>
      {
        'p_start': startDate == null ? null : _startOfDayUtc(startDate).toIso8601String(),
        'p_end': endDate == null ? null : _startOfNextDayUtc(endDate).toIso8601String(),
        'p_branch': (branchId == null || branchId.isEmpty) ? null : branchId,
      };

  Future<SaleSummaryTotals> fetchSummaryTotals({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
  }) async {
    final res = await _client.rpc('sale_summary_totals',
        params: _summaryParams(startDate, endDate, branchId));
    final m = (res as Map).cast<String, dynamic>();
    double d(String k) => (m[k] as num? ?? 0).toDouble();
    int i(String k) => (m[k] as num? ?? 0).toInt();

    return SaleSummaryTotals(
      totalSale: d('total_sale'),
      totalReturn: d('total_return'),
      exchangeChange: d('exchange_change'),
      exchangeReceived: d('exchange_received'),
      exchangeRefunded: d('exchange_refunded'),
      invoiceCount: i('invoice_count'),
      returnCount: i('return_count'),
      exchangeCount: i('exchange_count'),
    );
  }

  // ── Combined transaction list (Sale + Return + Exchange in one feed) ────
  // Server-side pagination (RPC `sale_summary_page`) — sirf ek page aata hai.

  Future<List<SaleTransactionRow>> fetchTransactionsPage({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    required int page,
    required int pageSize,
  }) async {
    final res = await _client.rpc('sale_summary_page', params: {
      ..._summaryParams(startDate, endDate, branchId),
      'p_limit': pageSize,
      'p_offset': (page - 1) * pageSize,
    });
    return [
      for (final row in (res as List).cast<Map<String, dynamic>>())
        SaleTransactionRow(
          id: row['id'].toString(),
          type: switch (row['type']) {
            'return' => SaleTransactionType.saleReturn,
            'exchange' => SaleTransactionType.exchange,
            _ => SaleTransactionType.sale,
          },
          number: row['number']?.toString() ?? '',
          branchName: row['branch_name']?.toString(),
          customerName: row['customer_name']?.toString(),
          createdAt: DateTime.parse(row['created_at'].toString()),
          amount: (row['amount'] as num? ?? 0).toDouble(),
        ),
    ];
  }

  // ── Branch Target report ─────────────────────────────────────────────────
  // Har branch ki ek din (default: aaj) ki net sale — invoice + return +
  // exchange, [SaleSummaryTotals.netTotalSale] jaisa hi formula
  // (sale − return + exchange difference), lekin branch_id ke hisaab se
  // grouped taake Branch Target report har branch ka target achieve hua ya
  // nahi check kar sake.

  /// [date] se [to] tak (dono din samet; [to] na ho to sirf [date] ka din)
  /// har branch ki net sale — {branchId: amount}. Monthly/yearly report ke
  /// liye bhi yehi use hota hai.
  Future<Map<String, double>> fetchNetSaleByBranch({DateTime? date, DateTime? to}) async {
    final day = date ?? DateTime.now();
    final start = _startOfDayUtc(day).toIso8601String();
    final end = _startOfNextDayUtc(to ?? day).toIso8601String();

    Future<List<Map<String, dynamic>>> load(String table, String col) => _fetchAll(
        () => _client
            .from(table)
            .select('id, branch_id, $col')
            .gte('created_at', start)
            .lt('created_at', end)
            .order('id'));

    final invoicesRes = await load('sale_invoices', 'total_amount');
    final returnsRes = await load('sale_returns', 'total_amount');
    final exchangesRes = await load('sale_exchanges', 'difference_amount');

    final net = <String, double>{};
    void add(String branchId, double amount) =>
        net[branchId] = (net[branchId] ?? 0) + amount;

    for (final row in invoicesRes) {
      add(row['branch_id'].toString(), (row['total_amount'] as num? ?? 0).toDouble());
    }
    for (final row in returnsRes) {
      add(row['branch_id'].toString(), -(row['total_amount'] as num? ?? 0).toDouble());
    }
    for (final row in exchangesRes) {
      add(row['branch_id'].toString(), (row['difference_amount'] as num? ?? 0).toDouble());
    }
    return net;
  }

  /// PostgREST ek request mein max ~1000 rows deta hai — saal bhar ka data
  /// is se zyada ho sakta hai, is liye 1000-1000 ke pages mein sab le aata hai.
  /// [build] har page ke liye nayi (ordered) query banata hai.
  Future<List<Map<String, dynamic>>> _fetchAll(
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

  /// Ek branch ki [from]..[to] (dono din samet) har din ki net sale —
  /// {sirf-date: amount}. Din ki hadd fetchNetSaleByBranch jaisi (UTC+5).
  Future<Map<DateTime, double>> fetchNetSaleByDay(
      String branchId, DateTime from, DateTime to) async {
    final start = _startOfDayUtc(from).toIso8601String();
    final end = _startOfNextDayUtc(to).toIso8601String();

    Future<List<Map<String, dynamic>>> load(String table, String col) => _fetchAll(
        () => _client
            .from(table)
            .select('id, created_at, $col')
            .eq('branch_id', branchId)
            .gte('created_at', start)
            .lt('created_at', end)
            .order('id'));

    final invoices = await load('sale_invoices', 'total_amount');
    final returns = await load('sale_returns', 'total_amount');
    final exchanges = await load('sale_exchanges', 'difference_amount');

    final net = <DateTime, double>{};
    void add(Map<String, dynamic> row, String col, double sign) {
      final t = DateTime.parse(row['created_at'].toString()).toUtc().add(const Duration(hours: 5));
      final day = DateTime(t.year, t.month, t.day);
      net[day] = (net[day] ?? 0) + sign * (row[col] as num? ?? 0).toDouble();
    }

    for (final r in invoices) {
      add(r, 'total_amount', 1);
    }
    for (final r in returns) {
      add(r, 'total_amount', -1);
    }
    for (final r in exchanges) {
      add(r, 'difference_amount', 1);
    }
    return net;
  }
}
