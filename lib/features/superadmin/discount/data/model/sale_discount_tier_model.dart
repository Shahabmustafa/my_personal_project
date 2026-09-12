enum DiscountTierType { flat, percent }

/// Head office ka ek global sale-amount discount tier — jab kisi invoice ka
/// items total [minSaleAmount] tak pohanch jaye, ye discount (flat Rs. ya %)
/// automatically laga di jati hai. Koi branch_id nahi — sab branches ko
/// yeksaan lagu hota hai.
class SaleDiscountTierModel {
  final String id;
  final double minSaleAmount;
  final DiscountTierType discountType;
  final double discountValue;
  final DateTime? createdAt;

  const SaleDiscountTierModel({
    required this.id,
    required this.minSaleAmount,
    required this.discountType,
    required this.discountValue,
    this.createdAt,
  });

  String get typeLabel => discountType == DiscountTierType.flat ? 'Flat' : 'Percent';

  /// Diya gaya sale amount is tier ke discount ke sath — flat ho to seedha
  /// Rs., percent ho to amount ka % (amount se zyada kabhi nahi).
  double discountFor(double saleAmount) {
    final raw = discountType == DiscountTierType.flat
        ? discountValue
        : saleAmount * discountValue / 100;
    return raw.clamp(0, saleAmount);
  }

  factory SaleDiscountTierModel.fromJson(Map<String, dynamic> json) {
    return SaleDiscountTierModel(
      id: json['id']?.toString() ?? '',
      minSaleAmount: (json['min_sale_amount'] as num?)?.toDouble() ?? 0,
      discountType: json['discount_type'] == 'flat' ? DiscountTierType.flat : DiscountTierType.percent,
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'min_sale_amount': minSaleAmount,
        'discount_type': discountType == DiscountTierType.flat ? 'flat' : 'percent',
        'discount_value': discountValue,
      };
}
