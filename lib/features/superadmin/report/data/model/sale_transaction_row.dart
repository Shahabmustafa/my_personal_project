enum SaleTransactionType { sale, saleReturn, exchange }

/// Sale Summary screen ki combined list ka ek row — invoice, return ya
/// exchange, teeno isi shape mein normalize ho kar ek hi list mein date ke
/// hisab se (newest first) dikhte hain.
class SaleTransactionRow {
  final String id;
  final SaleTransactionType type;
  final String number;
  final String? branchName;
  final String? customerName;
  final DateTime createdAt;

  /// Sale = +total_amount, Return = -total_amount, Exchange = difference
  /// amount (>0 collected from customer, <0 refunded to customer).
  final double amount;

  const SaleTransactionRow({
    required this.id,
    required this.type,
    required this.number,
    this.branchName,
    this.customerName,
    required this.createdAt,
    required this.amount,
  });

  String get typeLabel => switch (type) {
        SaleTransactionType.sale => 'Sale',
        SaleTransactionType.saleReturn => 'Return',
        SaleTransactionType.exchange => 'Exchange',
      };
}
