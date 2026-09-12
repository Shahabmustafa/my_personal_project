class BranchOverviewData {
  final int totalArticles;
  final int totalInvoices;
  final double todaySale;
  final int totalSalesman;
  final double todayExpense;

  /// Branch ka monthly target ho to aaj ka target (current date se mahine
  /// ke aakhir tak bache dinon mein taqseem karke) — 0 = target set nahi.
  final double todayTarget;
  final List<DaySale> weeklySale;
  final List<TopArticle> topArticles;

  const BranchOverviewData({
    this.totalArticles = 0,
    this.totalInvoices = 0,
    this.todaySale = 0,
    this.totalSalesman = 0,
    this.todayExpense = 0,
    this.todayTarget = 0,
    this.weeklySale = const [],
    this.topArticles = const [],
  });
}

/// Ek calendar din ki total sale (branch weekly bar graph ke liye).
class DaySale {
  final DateTime day;
  final double amount;
  const DaySale({required this.day, required this.amount});
}

/// Sab se zyada bikne wala article (branch, top 10 list).
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
