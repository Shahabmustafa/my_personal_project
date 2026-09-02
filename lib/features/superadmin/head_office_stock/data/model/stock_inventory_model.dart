class StockInventoryModel {
  final String id;
  final String barcode;
  final String productId;
  final String sizeId;
  final String brandId;
  final String? companyId;
  final String colorId;
  final String categoryId;
  final String typeId;
  final int quantity;
  final double discount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields (from select with foreign tables)
  final String? productName;
  final String? sizeName;
  final String? brandName;
  final String? companyName;
  final String? colorName;
  final String? categoryName;
  final String? typeName;

  const StockInventoryModel({
    required this.id,
    required this.barcode,
    required this.productId,
    required this.sizeId,
    required this.brandId,
    this.companyId,
    required this.colorId,
    required this.categoryId,
    required this.typeId,
    required this.quantity,
    this.discount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.productName,
    this.sizeName,
    this.brandName,
    this.companyName,
    this.colorName,
    this.categoryName,
    this.typeName,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory StockInventoryModel.fromJson(Map<String, dynamic> json) {
    return StockInventoryModel(
      id: json['id'] as String,
      barcode: json['barcode'] as String,
      productId: json['product_id'] as String,
      sizeId: json['size_id'] as String,
      brandId: json['brand_id'] as String,
      companyId: json['company_id'] as String?,
      colorId: json['color_id'] as String,
      categoryId: json['category_id'] as String,
      typeId: json['type_id'] as String,
      quantity: json['quantity'] as int,
      discount: _toDouble(json['discount']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      productName:
          (json['products'] as Map<String, dynamic>?)?['article_name'] as String?,
      sizeName: (json['sizes'] as Map<String, dynamic>?)?['number'] as String?,
      brandName: (json['brands'] as Map<String, dynamic>?)?['name'] as String?,
      companyName:
          (json['companies'] as Map<String, dynamic>?)?['name'] as String?,
      colorName: (json['colors'] as Map<String, dynamic>?)?['name'] as String?,
      categoryName:
          (json['categories'] as Map<String, dynamic>?)?['name'] as String?,
      typeName: (json['types'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'barcode': barcode,
      'product_id': productId,
      'size_id': sizeId,
      'brand_id': brandId,
      if (companyId != null) 'company_id': companyId,
      'color_id': colorId,
      'category_id': categoryId,
      'type_id': typeId,
      'quantity': quantity,
      'discount': discount,
    };
  }
}
