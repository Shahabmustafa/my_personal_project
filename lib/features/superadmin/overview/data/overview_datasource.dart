import 'package:supabase_flutter/supabase_flutter.dart';

/// SuperAdmin dashboard — sab high-level numbers ek jagah.
class OverviewStats {
  final int totalArticles;
  final int totalBranches;
  final int totalWarehouses;
  final int branchStockPairs;

  /// Aaj ka profit (RPC `superadmin_dashboard_stats` se, server-side).
  final double todayProfit;

  /// Aaj ki sale har branch ke hisaab se.
  final List<BranchSaleToday> todaySaleByBranch;

  /// Pichle 7 din (Asia/Karachi) ki daily sale — line graph ke liye.
  final List<DaySale> weeklySale;

  /// Sab se zyada bikne wala article.
  final TopArticle? topArticle;

  const OverviewStats({
    this.totalArticles = 0,
    this.totalBranches = 0,
    this.totalWarehouses = 0,
    this.branchStockPairs = 0,
    this.todayProfit = 0,
    this.todaySaleByBranch = const [],
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
    return DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(hours: 5)).toIso8601String();
  }

  Future<OverviewStats> fetchStats() async {
    final todayUtc = _startOfTodayUtc();

    // Counts, sums, profit, weekly series, top article — sab ek RPC call
    // mein server-side aggregate hote hain (indexes ke sath), poori tables
    // client tak fetch nahi hoti.
    final results = await Future.wait([
      _client.rpc('superadmin_dashboard_stats'),
      _client
          .from('sale_invoices')
          .select('total_amount, branch_id, branches(branch_name)')
          .gte('created_at', todayUtc),
    ]);

    final extras = results[0] as Map<String, dynamic>? ?? const {};
    final todayInvoices = results[1] as List<dynamic>;

    final perBranch = <String, BranchSaleToday>{};
    for (final r in todayInvoices) {
      final m = r as Map<String, dynamic>;
      final bid = m['branch_id'] as String? ?? '';
      final branchName =
          (m['branches'] as Map<String, dynamic>?)?['branch_name'] as String?;
      final amt = _toDouble(m['total_amount']);
      final existing = perBranch[bid];
      perBranch[bid] = BranchSaleToday(
        branchId: bid,
        branchName: branchName ?? existing?.branchName ?? 'Branch',
        amount: (existing?.amount ?? 0) + amt,
        invoiceCount: (existing?.invoiceCount ?? 0) + 1,
      );
    }
    final todayByBranch = perBranch.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

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
      totalArticles: _toInt(extras['total_articles']),
      totalBranches: _toInt(extras['total_branches']),
      totalWarehouses: _toInt(extras['total_warehouses']),
      branchStockPairs: _toInt(extras['branch_stock_pairs']),
      todayProfit: _toDouble(extras['today_profit']),
      todaySaleByBranch: todayByBranch,
      weeklySale: weekly,
      topArticle: topArticle,
    );
  }
}
