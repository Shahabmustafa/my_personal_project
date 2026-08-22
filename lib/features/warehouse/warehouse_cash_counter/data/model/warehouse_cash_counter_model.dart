class WarehouseCashCounterModel {
  final String id;
  final String warehouseId;
  final DateTime counterDate;
  final double netAmount;
  final double totalPurchase;
  final double totalReturnPurchase;
  final double expense;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WarehouseCashCounterModel({
    required this.id,
    required this.warehouseId,
    required this.counterDate,
    this.netAmount = 0,
    this.totalPurchase = 0,
    this.totalReturnPurchase = 0,
    this.expense = 0,
    this.createdAt,
    this.updatedAt,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory WarehouseCashCounterModel.fromJson(Map<String, dynamic> json) {
    return WarehouseCashCounterModel(
      id: json['id']?.toString() ?? '',
      warehouseId: json['warehouse_id']?.toString() ?? '',
      counterDate: json['counter_date'] != null
          ? DateTime.tryParse(json['counter_date'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      netAmount: _toDouble(json['net_amount']),
      totalPurchase: _toDouble(json['total_purchase']),
      totalReturnPurchase: _toDouble(json['total_return_purchase']),
      expense: _toDouble(json['expense']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'warehouse_id': warehouseId,
        'counter_date':
            '${counterDate.year}-${counterDate.month.toString().padLeft(2, '0')}-${counterDate.day.toString().padLeft(2, '0')}',
        'net_amount': netAmount,
        'total_purchase': totalPurchase,
        'total_return_purchase': totalReturnPurchase,
        'expense': expense,
      };

  WarehouseCashCounterModel copyWith({
    String? id,
    String? warehouseId,
    DateTime? counterDate,
    double? netAmount,
    double? totalPurchase,
    double? totalReturnPurchase,
    double? expense,
  }) {
    return WarehouseCashCounterModel(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      counterDate: counterDate ?? this.counterDate,
      netAmount: netAmount ?? this.netAmount,
      totalPurchase: totalPurchase ?? this.totalPurchase,
      totalReturnPurchase: totalReturnPurchase ?? this.totalReturnPurchase,
      expense: expense ?? this.expense,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
