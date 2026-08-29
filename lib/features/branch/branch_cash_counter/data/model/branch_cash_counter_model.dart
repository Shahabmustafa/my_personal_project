class BranchCashCounterModel {
  final String id;
  final String branchId;
  final double cashSale;
  final double cardSale;
  final double totalSale;
  final double returnSale;
  final double returnAmountInExchange;
  final double receivedAmountInExchange;
  final double expense;
  final double gross;
  final double paidAmount;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BranchCashCounterModel({
    required this.id,
    required this.branchId,
    this.cashSale = 0,
    this.cardSale = 0,
    this.totalSale = 0,
    this.returnSale = 0,
    this.returnAmountInExchange = 0,
    this.receivedAmountInExchange = 0,
    this.expense = 0,
    this.gross = 0,
    this.paidAmount = 0,
    this.totalAmount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory BranchCashCounterModel.fromJson(Map<String, dynamic> json) {
    return BranchCashCounterModel(
      id: json['id']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ?? '',
      cashSale: _toDouble(json['cash_sale']),
      cardSale: _toDouble(json['card_sale']),
      totalSale: _toDouble(json['total_sale']),
      returnSale: _toDouble(json['return_sale']),
      returnAmountInExchange: _toDouble(json['return_amount_in_exchange']),
      receivedAmountInExchange:
          _toDouble(json['received_amount_in_exchange']),
      expense: _toDouble(json['expense']),
      gross: _toDouble(json['gross']),
      paidAmount: _toDouble(json['paid_amount']),
      totalAmount: _toDouble(json['total_amount']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  /// Gross sale mein se sale-return aur exchange refund minus, aur exchange
  /// mein mila extra amount plus — taake poora return hone par ye 0 ho jaye.
  double get netSale =>
      totalSale - returnSale - returnAmountInExchange + receivedAmountInExchange;
}
