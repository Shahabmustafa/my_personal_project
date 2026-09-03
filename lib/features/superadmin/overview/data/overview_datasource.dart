import 'package:supabase_flutter/supabase_flutter.dart';

/// SuperAdmin dashboard — sab high-level numbers ek jagah.
class OverviewStats {
  final int totalArticles;
  final int totalBranches;
  final int totalWarehouses;
  final int totalUsers;
  final int totalCustomers;
  final int totalCompanies;
  final int pendingAssignments;

  final double todaySale; // all branches
  final int todayInvoiceCount;
  final double todaySaleReturn;
  final double monthSale;

  final int headOfficeStockPairs;
  final int warehouseStockPairs;
  final int branchStockPairs;

  /// Aaj ki sale har branch ke hisaab se.
  final List<BranchSaleToday> todaySaleByBranch;

  /// Sab branches ka lifetime total (RPC `superadmin_dashboard_stats` se).
  final double totalSale;
  final double totalReturn;
  final double totalProfit;

  /// Pichle 7 din (Asia/Karachi) ki daily sale — line graph ke liye.
  final List<DaySale> weeklySale;

  /// Sab se zyada bikne wala article.
  final TopArticle? topArticle;

  const OverviewStats({
    this.totalArticles = 0,
    this.totalBranches = 0,
    this.totalWarehouses = 0,
    this.totalUsers = 0,
    this.totalCustomers = 0,
    this.totalCompanies = 0,
    this.pendingAssignments = 0,
    this.todaySale = 0,
    this.todayInvoiceCount = 0,
    this.todaySaleReturn = 0,
    this.monthSale = 0,
    this.headOfficeStockPairs = 0,
    this.warehouseStockPairs = 0,
    this.branchStockPairs = 0,
    this.todaySaleByBranch = const [],
    this.totalSale = 0,
    this.totalReturn = 0,
    this.totalProfit = 0,
    this.weeklySale = const [],
    this.topArticle,
  });
}

class DaySale {
  final DateTime day;
  final double amount;
  const DaySale({required this.day, required this.amount});
}

class TopArticle {
  final String productId;
  final String articleName;
  final int quantity;
  final double amount;
  const TopArticle({
    required this.productId,
    required this.articleName,
    required this.quantity,
    required this.amount,
  });
}

class BranchSaleToday {
  final String branchId;
  final String branchName;
  final double amount;
  final int invoiceCount;

  const BranchSaleToday({
    required this.branchId,
    required this.branchName,
    required this.amount,
    required this.invoiceCount,
  });
}

class OverviewDatasource {
  final SupabaseClient _client;
  OverviewDatasource(this._client);

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// Karachi (UTC+5) calendar date ke liye din ki shuruat ka UTC instant.
  static String _startOfTodayUtc() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day)
        .subtract(const Duration(hours: 5))
        .toIso8601String();
  }

  static String _startOfMonthUtc() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, 1)
        .subtract(const Duration(hours: 5))
        .toIso8601String();
  }

  Future<OverviewStats> fetchStats() async {
    final todayUtc = _startOfTodayUtc();
    final monthUtc = _startOfMonthUtc();

    // Lifetime totals / weekly series / top article — sab ek RPC call mein
    // (server-side aggregate, indexes ke sath).
    final extrasFuture = _client.rpc('superadmin_dashboard_stats');

    final results = await Future.wait<List<dynamic>>([
      _client.from('products').select('id'),
      _client.from('branches').select('id, branch_name'),
      _client.from('warehouses').select('id'),
      _client.from('users').select('id'),
      _client.from('customers').select('id'),
      _client.from('companies').select('id'),
      _client
          .from('assign_stock_to_branch')
          .select('id')
          .eq('status', 'pending'),
      _client.from('stock_inventory').select('quantity'),
      _client.from('warehouse_stock_inventory').select('quantity'),
      _client.from('branch_stock_inventory').select('quantity'),
      _client
          .from('sale_invoices')
          .select('total_amount, branch_id')
          .gte('created_at', todayUtc),
      _client
          .from('sale_invoices')
          .select('total_amount')
          .gte('created_at', monthUtc),
      _client
          .from('sale_returns')
          .select('total_amount')
          .gte('created_at', todayUtc),
    ]);

    int sumQty(List<dynamic> rows) {
      var total = 0;
      for (final r in rows) {
        total += _toInt((r as Map<String, dynamic>)['quantity']);
      }
      return total;
    }

    double sumAmount(List<dynamic> rows) {
      var total = 0.0;
      for (final r in rows) {
        total += _toDouble((r as Map<String, dynamic>)['total_amount']);
      }
      return total;
    }

    final branches = results[1];
    final branchNameMap = <String, String>{};
    for (final r in branches) {
      final m = r as Map<String, dynamic>;
      branchNameMap[m['id'] as String] =
          (m['branch_name'] as String?) ?? 'Branch';
    }

    final perBranch = <String, BranchSaleToday>{};
    var todaySaleTotal = 0.0;
    var todayInvoiceCount = 0;
    for (final r in results[10]) {
      final m = r as Map<String, dynamic>;
      final bid = m['branch_id'] as String? ?? '';
      final amt = _toDouble(m['total_amount']);
      todaySaleTotal += amt;
      todayInvoiceCount++;
      final existing = perBranch[bid];
      perBranch[bid] = BranchSaleToday(
        branchId: bid,
        branchName: branchNameMap[bid] ?? 'Branch',
        amount: (existing?.amount ?? 0) + amt,
        invoiceCount: (existing?.invoiceCount ?? 0) + 1,
      );
    }
    final todayByBranch = perBranch.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final extras = (await extrasFuture) as Map<String, dynamic>? ?? const {};
    final weekly = <DaySale>[
      for (final r in (extras['weekly_sale'] as List? ?? const []))
        DaySale(
          day: DateTime.tryParse('${(r as Map)['day']}') ?? DateTime.now(),
          amount: _toDouble(r['amount']),
        ),
    ];
    final topRaw = extras['top_article'] as Map<String, dynamic>?;
    final topArticle = topRaw == null
        ? null
        : TopArticle(
            productId: '${topRaw['product_id']}',
            articleName: '${topRaw['article_name'] ?? '—'}',
            quantity: _toInt(topRaw['quantity']),
            amount: _toDouble(topRaw['amount']),
          );

    return OverviewStats(
      totalArticles: results[0].length,
      totalBranches: branches.length,
      totalWarehouses: results[2].length,
      totalUsers: results[3].length,
      totalCustomers: results[4].length,
      totalCompanies: results[5].length,
      pendingAssignments: results[6].length,
      headOfficeStockPairs: sumQty(results[7]),
      warehouseStockPairs: sumQty(results[8]),
      branchStockPairs: sumQty(results[9]),
      todaySale: todaySaleTotal,
      todayInvoiceCount: todayInvoiceCount,
      monthSale: sumAmount(results[11]),
      todaySaleReturn: sumAmount(results[12]),
      todaySaleByBranch: todayByBranch,
      totalSale: _toDouble(extras['total_sale']),
      totalReturn: _toDouble(extras['total_return']),
      totalProfit: _toDouble(extras['total_profit']),
      weeklySale: weekly,
      topArticle: topArticle,
    );
  }
}
