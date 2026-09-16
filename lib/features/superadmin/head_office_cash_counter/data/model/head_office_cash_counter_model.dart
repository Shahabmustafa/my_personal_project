class HeadOfficeCashCounterModel {
  final String id;
  final DateTime counterDate;
  final double netAmount;
  final double totalPurchase;
  final double totalReturnPurchase;
  final double expense;

  const HeadOfficeCashCounterModel({
    required this.id,
    required this.counterDate,
    this.netAmount = 0,
    this.totalPurchase = 0,
    this.totalReturnPurchase = 0,
    this.expense = 0,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory HeadOfficeCashCounterModel.fromJson(Map<String, dynamic> json) {
    return HeadOfficeCashCounterModel(
      id: json['id']?.toString() ?? '',
      counterDate: json['counter_date'] != null
          ? DateTime.tryParse(json['counter_date'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      netAmount: _toDouble(json['net_amount']),
      totalPurchase: _toDouble(json['total_purchase']),
      totalReturnPurchase: _toDouble(json['total_return_purchase']),
      expense: _toDouble(json['expense']),
    );
  }
}
