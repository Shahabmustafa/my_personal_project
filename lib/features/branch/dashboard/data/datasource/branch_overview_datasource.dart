import 'package:supabase_flutter/supabase_flutter.dart';

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
}
