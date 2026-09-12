import 'package:supabase_flutter/supabase_flutter.dart';

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
    final res = await _client
        .from('branch_cash_counter')
        .select('total_sale, expense')
        .eq('branch_id', branchId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (res == null) return (todaySale: 0.0, todayExpense: 0.0);
    return (
      todaySale: _toDouble(res['total_sale']),
      todayExpense: _toDouble(res['expense']),
    );
  }

  /// Branch ka monthly sale target (Rs.) — admin/superadmin "Branch Target"
  /// screen se set karta hai. 0 = target set nahi.
  Future<double> fetchMonthlyTarget(String branchId) async {
    if (branchId.isEmpty) return 0.0;
    final res = await _client
        .from('branches')
        .select('monthly_target')
        .eq('id', branchId)
        .maybeSingle();
    if (res == null) return 0.0;
    return _toDouble(res['monthly_target']);
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
