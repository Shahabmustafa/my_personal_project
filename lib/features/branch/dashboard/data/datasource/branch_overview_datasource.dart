import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../superadmin/branch_target/data/branch_target_datasource.dart';

import '../model/branch_overview_model.dart';

class BranchOverviewDatasource {
  final SupabaseClient _client;
  BranchOverviewDatasource(this._client);

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Future<int> fetchArticleCount(String branchId) async {
    if (branchId.isEmpty) return 0;
    final res = await _client
        .from('branch_stock_inventory')
        .select('id')
        .eq('branch_id', branchId);
    return (res as List).length;
  }

  Future<int> fetchInvoiceCount(String branchId) async {
    if (branchId.isEmpty) return 0;
    final res =
        await _client.from('sale_invoices').select('id').eq('branch_id', branchId);
    return (res as List).length;
  }

  Future<int> fetchSalesmanCount(String branchId) async {
    if (branchId.isEmpty) return 0;
    final res = await _client
        .from('employee_salary')
        .select('id, users!inner(role)')
        .eq('branch_id', branchId)
        .eq('users.role', 'salesman');
    return (res as List).length;
  }

  /// Aaj ke din ka branch_cash_counter row — total_sale aur expense
  /// dono yahan se milte hain (nightly cron se banta hai).
  Future<({double todaySale, double todayExpense})> fetchTodayCounter(
      String branchId) async {
    if (branchId.isEmpty) return (todaySale: 0.0, todayExpense: 0.0);
    final todayUtc = _startOfTodayUtc();
    final results = await Future.wait<dynamic>([
      _client
          .from('branch_cash_counter')
          .select('total_sale, expense')
          .eq('branch_id', branchId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle(),
      _client
          .from('sale_returns')
          .select('total_amount')
          .eq('branch_id', branchId)
          .gte('created_at', todayUtc),
      _client
          .from('sale_exchanges')
          .select('difference_amount')
          .eq('branch_id', branchId)
          .gte('created_at', todayUtc),
    ]);

    final res = results[0] as Map<String, dynamic>?;
    if (res == null) return (todaySale: 0.0, todayExpense: 0.0);

    // Net sale = sale − returns + exchange ka farq (admin dashboard jaisa).
    final returns = (results[1] as List<dynamic>)
        .fold<double>(0, (s, r) => s + _toDouble((r as Map)['total_amount']));
    final exchangeDiff = (results[2] as List<dynamic>).fold<double>(
        0, (s, r) => s + _toDouble((r as Map)['difference_amount']));

    return (
      todaySale: _toDouble(res['total_sale']) - returns + exchangeDiff,
      todayExpense: _toDouble(res['expense']),
    );
  }

  /// Aaj ka din (Pakistan time, UTC+5) shuru hone ka waqt, UTC mein.
  static String _startOfTodayUtc() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day)
        .subtract(const Duration(hours: 5))
        .toIso8601String();
  }

  /// Aaj ka sale target (Rs.) — admin "Branch Target" screen se din-wise set
  /// hota hai. 0 = aaj ka target set nahi.
  Future<double> fetchTodayTarget(String branchId) async {
    if (branchId.isEmpty) return 0.0;
    final res = await _client
        .from('branch_daily_targets')
        .select('amount')
        .eq('branch_id', branchId)
        .eq('target_date', BranchTargetDatasource.dateKey(DateTime.now()))
        .maybeSingle();
    if (res == null) return 0.0;
    return _toDouble(res['amount']);
  }

  /// Pichhle 7 din ki din-wise sale + top 10 bikne wale articles.
  /// Sab kuch server-side aggregate hota hai (RPC `branch_dashboard_stats`,
  /// indexes ke sath) — poori tables client tak fetch nahi hoti.
  Future<({List<DaySale> weekly, List<TopArticle> topArticles})>
      fetchDashboardExtras(String branchId) async {
    if (branchId.isEmpty) return (weekly: <DaySale>[], topArticles: <TopArticle>[]);

    final res = await _client
        .rpc('branch_dashboard_stats', params: {'p_branch_id': branchId});
    final map = (res as Map).cast<String, dynamic>();

    final weekly = <DaySale>[
      for (final r in (map['weekly_sale'] as List? ?? const []))
        DaySale(
          day: DateTime.tryParse('${(r as Map)['day']}') ?? DateTime.now(),
          amount: _toDouble(r['amount']),
        ),
    ];

    final topArticles = <TopArticle>[
      for (final r in (map['top_articles'] as List? ?? const []))
        TopArticle(
          productId: '${(r as Map)['product_id']}',
          articleName: '${r['article_name'] ?? '—'}',
          quantity: (r['quantity'] as num?)?.toInt() ?? 0,
          amount: _toDouble(r['amount']),
        ),
    ];

    return (weekly: weekly, topArticles: topArticles);
  }
}
