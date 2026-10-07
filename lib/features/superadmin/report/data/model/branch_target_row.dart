/// Branch Target report ki ek row — branch ka aaj ka target (admin ne din-wise
/// set kiya), aaj ki net sale, aur target achieve hua ya nahi.
class BranchTargetRow {
  final String branchId;
  final String branchName;

  /// Chune hue period (aaj / mahina / saal) ka total target — 0 = us period
  /// mein target set nahi. Naam purana hai, ab sirf "aaj" ke liye nahi.
  final double todayTarget;

  /// Usi period ki net sale.
  final double netSaleToday;

  /// Sirf yearly report mein — Jan..Dec (12 entries) ka target/sale.
  final List<BranchMonthTarget> months;

  const BranchTargetRow({
    required this.branchId,
    required this.branchName,
    required this.todayTarget,
    required this.netSaleToday,
    this.months = const [],
  });

  bool get hasTarget => todayTarget > 0;

  bool get isAchieved => hasTarget && netSaleToday >= todayTarget;

  double get progress =>
      hasTarget ? (netSaleToday / todayTarget).clamp(0, 1).toDouble() : 0;

  /// Sale ÷ target × 100 — 100 se upar bhi ja sakta hai.
  double get achievedPercent => targetPercent(netSaleToday, todayTarget);

  /// Target poora hone mein kitna baqi — achieve ho gaya to 0.
  double get remainingAmount =>
      hasTarget ? (todayTarget - netSaleToday).clamp(0, double.infinity).toDouble() : 0;

  double get remainingPercent =>
      hasTarget ? (100 - achievedPercent).clamp(0, 100).toDouble() : 0;
}

/// Yearly Branch Target report mein ek branch ka ek mahina.
class BranchMonthTarget {
  /// Mahine ka pehla din.
  final DateTime month;
  final double target;
  final double sale;

  const BranchMonthTarget({
    required this.month,
    required this.target,
    required this.sale,
  });

  bool get hasTarget => target > 0;

  bool get isAchieved => hasTarget && sale >= target;

  /// Mahina abhi shuru nahi hua.
  bool get isFuture {
    final now = DateTime.now();
    return month.isAfter(DateTime(now.year, now.month, 1));
  }

  bool get isCurrent {
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }

  double get achievedPercent => targetPercent(sale, target);

  double get remainingAmount =>
      hasTarget ? (target - sale).clamp(0, double.infinity).toDouble() : 0;

  double get remainingPercent =>
      hasTarget ? (100 - achievedPercent).clamp(0, 100).toDouble() : 0;
}

double targetPercent(double sale, double target) =>
    target > 0 ? sale / target * 100 : 0;
