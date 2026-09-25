/// Branch Target report ki ek row — branch ka aaj ka target (admin ne din-wise
/// set kiya), aaj ki net sale, aur target achieve hua ya nahi.
class BranchTargetRow {
  final String branchId;
  final String branchName;

  /// Aaj ka target — 0 = aaj ke liye target set nahi.
  final double todayTarget;
  final double netSaleToday;

  const BranchTargetRow({
    required this.branchId,
    required this.branchName,
    required this.todayTarget,
    required this.netSaleToday,
  });

  bool get hasTarget => todayTarget > 0;

  bool get isAchieved => hasTarget && netSaleToday >= todayTarget;

  double get progress =>
      hasTarget ? (netSaleToday / todayTarget).clamp(0, 1).toDouble() : 0;
}
