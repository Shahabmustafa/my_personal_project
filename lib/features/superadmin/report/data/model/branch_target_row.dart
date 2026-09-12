/// Branch Target report ki ek row — branch ka monthly target (baaki bache
/// dinon se divide karke aaj ka target), aaj ki net sale, aur target
/// achieve hua ya nahi.
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

  double get dailyTarget => dailyTargetFor(monthlyTarget);

  /// 1 tareekh se poore mahine ka average nikalne ke bajaye, current date se
  /// mahine ke aakhir (30) tak jitne din bache hain unme target taqseem
  /// karta hai — e.g. aaj 13 hai to 13 se 30 tak (18 din). Jitna month mein
  /// aage badhte jayein utna hi daily target zyada hota jata hai agar target
  /// abhi tak achieve nahi hua.
  static double dailyTargetFor(double monthlyTarget, {DateTime? now}) {
    final today = (now ?? DateTime.now()).day;
    final remainingDays = (30 - today + 1).clamp(1, 30);
    return monthlyTarget / remainingDays;
  }

  /// Target set hi nahi (0) to "achieved" nahi dikhate — sirf jab target ho
  /// aur aaj ki net sale usse bhar ya zyada ho.
  bool get isAchieved => monthlyTarget > 0 && netSaleToday >= dailyTarget;

  double get progress => dailyTarget <= 0 ? 0 : (netSaleToday / dailyTarget).clamp(0, 1);
}
