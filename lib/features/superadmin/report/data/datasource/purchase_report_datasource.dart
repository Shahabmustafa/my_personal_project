import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../head_office_purchase/data/datasources/purchase_invoice_datasource.dart';
import '../../../head_office_purchase/data/datasources/purchase_return_datasource.dart';
import '../../../head_office_purchase/data/models/purchase_invoice_model.dart';
import '../../../head_office_purchase/data/models/purchase_return_model.dart';
import '../model/purchase_transaction_row.dart';

/// Purchase Summary report — purchase_invoices + purchase_returns (head
/// office aur warehouse dono), optional date range aur company filter ke sath.
class PurchaseReportDatasource {
  final SupabaseClient _client;
  PurchaseReportDatasource(this._client);

  /// Local (Asia/Karachi) date ki shuruat ka UTC instant — Sale reports jaisa.
  static DateTime _startOfDayUtc(DateTime local) =>
      DateTime.utc(local.year, local.month, local.day).subtract(const Duration(hours: 5));

  static DateTime _startOfNextDayUtc(DateTime local) =>
      _startOfDayUtc(local.add(const Duration(days: 1)));

  PostgrestFilterBuilder<T> _applyFilters<T>(
    PostgrestFilterBuilder<T> query,
    DateTime? startDate,
    DateTime? endDate,
    String? companyId,
  ) {
    var q = query;
    if (startDate != null) {
      q = q.gte('created_at', _startOfDayUtc(startDate).toIso8601String());
    }
    if (endDate != null) {
      q = q.lt('created_at', _startOfNextDayUtc(endDate).toIso8601String());
    }
    if (companyId != null && companyId.isNotEmpty) {
      q = q.eq('company_id', companyId);
    }
    return q;
  }

  /// Totals aur combined list dono ek hi fetch se — [load] ka result.
  Future<(PurchaseSummaryTotals, List<PurchaseTransactionRow>)> fetchSummary({
    DateTime? startDate,
    DateTime? endDate,
    String? companyId,
  }) async {
    const cols = 'id, created_at, net_amount, head_office_id, companies(name)';
    final invoicesRes = await _applyFilters(
        _client
            .from('purchase_invoices')
            .select('$cols, invoice_number, paid_amount, credit_amount'),
        startDate,
        endDate,
        companyId) as List;
    final returnsRes = await _applyFilters(
        _client.from('purchase_returns').select('$cols, return_number'),
        startDate,
        endDate,
        companyId) as List;

    double num_(Map<String, dynamic> r, String k) => (r[k] as num? ?? 0).toDouble();
    String? company(Map<String, dynamic> r) =>
        (r['companies'] as Map<String, dynamic>?)?['name']?.toString();
    String source(Map<String, dynamic> r) =>
        r['head_office_id'] != null ? 'Head Office' : 'Warehouse';

    final invoices = invoicesRes.cast<Map<String, dynamic>>();
    final returns = returnsRes.cast<Map<String, dynamic>>();

    final totals = PurchaseSummaryTotals(
      totalPurchase: invoices.fold(0.0, (s, r) => s + num_(r, 'net_amount')),
      totalReturn: returns.fold(0.0, (s, r) => s + num_(r, 'net_amount')),
      totalPaid: invoices.fold(0.0, (s, r) => s + num_(r, 'paid_amount')),
      totalCredit: invoices.fold(0.0, (s, r) => s + num_(r, 'credit_amount')),
    );

    final rows = <PurchaseTransactionRow>[
      for (final r in invoices)
        PurchaseTransactionRow(
          id: r['id'].toString(),
          type: PurchaseTransactionType.purchase,
          number: r['invoice_number']?.toString() ?? '',
          companyName: company(r),
          source: source(r),
          createdAt: DateTime.parse(r['created_at'].toString()),
          amount: num_(r, 'net_amount'),
        ),
      for (final r in returns)
        PurchaseTransactionRow(
          id: r['id'].toString(),
          type: PurchaseTransactionType.purchaseReturn,
          number: r['return_number']?.toString() ?? '',
          companyName: company(r),
          source: source(r),
          createdAt: DateTime.parse(r['created_at'].toString()),
          amount: -num_(r, 'net_amount'),
        ),
    ];
    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return (totals, rows);
  }

  Future<PurchaseInvoiceModel> fetchInvoiceById(String id) =>
      PurchaseInvoiceDatasource(_client).fetchInvoiceDetail(id);

  Future<PurchaseReturnModel> fetchReturnById(String id) =>
      PurchaseReturnDatasource(_client).fetchReturnDetail(id);

  /// Company filter dropdown ke liye.
  Future<List<(String, String)>> fetchCompanies() async {
    final res = await _client.from('companies').select('id, name').order('name');
    return (res as List)
        .map((e) => (e['id'].toString(), e['name']?.toString() ?? ''))
        .toList();
  }
}
