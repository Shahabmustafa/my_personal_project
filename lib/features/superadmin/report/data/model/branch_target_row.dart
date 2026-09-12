/// Branch Target report ki ek row — branch ka monthly target (30 din se
/// divide karke daily target), aaj ki net sale, aur target achieve hua ya
/// nahi.
class BranchTargetRow {
  final String branchId;
  final String branchName;
  final double monthlyTarget;
  final double netSaleToday;

  const BranchTargetRow({
    required this.branchId,
    required this.branchName,
    required this.monthlyTarget,
    required this.netSaleToday,
  });

  double get dailyTarget => monthlyTarget / 30;

  /// Target set hi nahi (0) to "achieved" nahi dikhate — sirf jab target ho
  /// aur aaj ki net sale usse bhar ya zyada ho.
  bool get isAchieved => monthlyTarget > 0 && netSaleToday >= dailyTarget;

  double get progress => dailyTarget <= 0 ? 0 : (netSaleToday / dailyTarget).clamp(0, 1);
}
