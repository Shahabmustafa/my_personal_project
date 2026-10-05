enum PurchaseTransactionType { purchase, purchaseReturn }

/// Purchase Summary screen ki combined list ka ek row — purchase invoice ya
/// purchase return, dono isi shape mein normalize ho kar ek hi list mein date
/// ke hisab se (newest first) dikhte hain.
class PurchaseTransactionRow {
  final String id;
  final PurchaseTransactionType type;
  final String number;
  final String? companyName;

  /// 'Head Office' ya 'Warehouse' — record kis taraf se bana.
  final String source;
  final DateTime createdAt;

  /// Purchase = +net_amount, Return = -net_amount.
  final double amount;

  const PurchaseTransactionRow({
    required this.id,
    required this.type,
    required this.number,
    this.companyName,
    required this.source,
    required this.createdAt,
    required this.amount,
  });
}

/// Purchase Summary screen ke top cards ke liye totals.
class PurchaseSummaryTotals {
  final double totalPurchase;
  final double totalReturn;

  /// Purchase invoices par company ko diya gaya cash (paid_amount ka sum).
  final double totalPaid;

  /// Purchase invoices par company ka udhaar (credit_amount ka sum).
  final double totalCredit;

  const PurchaseSummaryTotals({
    this.totalPurchase = 0,
    this.totalReturn = 0,
    this.totalPaid = 0,
    this.totalCredit = 0,
  });

  double get netPurchase => totalPurchase - totalReturn;
}
