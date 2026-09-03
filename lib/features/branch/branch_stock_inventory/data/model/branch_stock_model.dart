// ── Branch Stock Inventory Model ─────────────────────────────────────────

class BranchStockModel {
  final String id;
  final String branchId;
  final String stockId;
  final String barcode;
  final String productId;
  final String sizeId;
  final String colorId;
  final String brandId;
  final String categoryId;
  final String typeId;
  final int quantity;
  final double salePrice;
  final double purchasePrice;
  final double discount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? productName;
  final String? sizeName;
  final String? colorName;
  final String? brandName;
  final String? categoryName;
  final String? typeName;

  const BranchStockModel({
    required this.id,
    required this.branchId,
    required this.stockId,
    required this.barcode,
    required this.productId,
    required this.sizeId,
    required this.colorId,
    required this.brandId,
    required this.categoryId,
    required this.typeId,
    required this.quantity,
    required this.salePrice,
    required this.purchasePrice,
    this.discount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.productName,
    this.sizeName,
    this.colorName,
    this.brandName,
    this.categoryName,
    this.typeName,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  BranchStockModel copyWith({
    int? quantity,
    double? salePrice,
    double? purchasePrice,
    double? discount,
    DateTime? updatedAt,
  }) {
    return BranchStockModel(
      id: id,
      branchId: branchId,
      stockId: stockId,
      barcode: barcode,
      productId: productId,
      sizeId: sizeId,
      colorId: colorId,
      brandId: brandId,
      categoryId: categoryId,
      typeId: typeId,
      quantity: quantity ?? this.quantity,
      salePrice: salePrice ?? this.salePrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      discount: discount ?? this.discount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productName: productName,
      sizeName: sizeName,
      colorName: colorName,
      brandName: brandName,
      categoryName: categoryName,
      typeName: typeName,
    );
  }

  factory BranchStockModel.fromJson(Map<String, dynamic> json) {
    return BranchStockModel(
      id:          json['id'] as String,
      branchId:    json['branch_id'] as String,
      stockId:     json['stock_id'] as String,
      barcode:     json['barcode'] as String? ?? '',
      productId:   json['product_id'] as String,
      sizeId:      json['size_id'] as String,
      colorId:     json['color_id'] as String,
      brandId:     json['brand_id'] as String,
      categoryId:  json['category_id'] as String,
      typeId:      json['type_id'] as String,
      quantity:    (json['quantity'] as num? ?? 0).toInt(),
      salePrice:   _toDouble(json['sale_price']),
      purchasePrice: _toDouble(json['purchase_price']),
      discount:    _toDouble(json['discount']),
      createdAt:   DateTime.parse(json['created_at'] as String),
      updatedAt:   DateTime.parse(json['updated_at'] as String),
      productName:  (json['products']   as Map<String, dynamic>?)?['article_name'] as String?,
      sizeName:     (json['sizes']      as Map<String, dynamic>?)?['number']        as String?,
      colorName:    (json['colors']     as Map<String, dynamic>?)?['name']          as String?,
      brandName:    (json['brands']     as Map<String, dynamic>?)?['name']          as String?,
      categoryName: (json['categories'] as Map<String, dynamic>?)?['name']          as String?,
      typeName:     (json['types']      as Map<String, dynamic>?)?['name']          as String?,
    );
  }
}
