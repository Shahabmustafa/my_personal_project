class WarehouseStockModel {
  final String id;
  final String barcode;
  final String warehouseId;
  final String productId;
  final String sizeId;
  final String brandId;
  final String? companyId;
  final String colorId;
  final String categoryId;
  final String typeId;
  final int quantity;
  final double salePrice;
  final double purchasePrice;
  final double discountPct;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? productName;
  final String? sizeName;
  final String? brandName;
  final String? companyName;
  final String? colorName;
  final String? categoryName;
  final String? typeName;
  final String? warehouseName;

  const WarehouseStockModel({
    required this.id,
    required this.barcode,
    required this.warehouseId,
    required this.productId,
    required this.sizeId,
    required this.brandId,
    this.companyId,
    required this.colorId,
    required this.categoryId,
    required this.typeId,
    required this.quantity,
    this.salePrice = 0,
    this.purchasePrice = 0,
    this.discountPct = 0,
    required this.createdAt,
    required this.updatedAt,
    this.productName,
    this.sizeName,
    this.brandName,
    this.companyName,
    this.colorName,
    this.categoryName,
    this.typeName,
    this.warehouseName,
  });

  factory WarehouseStockModel.fromJson(Map<String, dynamic> json) {
    // sale_price comes from products table join
    final productMap = json['products'] as Map<String, dynamic>?;
    return WarehouseStockModel(
      id: json['id'] as String,
      barcode: json['barcode'] as String,
      warehouseId: json['warehouse_id'] as String,
      productId: json['product_id'] as String,
      sizeId: json['size_id'] as String,
      brandId: json['brand_id'] as String,
      companyId: json['company_id'] as String?,
      colorId: json['color_id'] as String,
      categoryId: json['category_id'] as String,
      typeId: json['type_id'] as String,
      quantity: json['quantity'] as int,
      // sale_price & purchase_price from products join
      salePrice: (productMap?['sale_price'] as num?)?.toDouble() ??
          (json['sale_price'] as num?)?.toDouble() ??
          0,
      purchasePrice: (productMap?['purchase_price'] as num?)?.toDouble() ??
          (json['purchase_price'] as num?)?.toDouble() ??
          0,
      discountPct: (json['discount_pct'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      productName: productMap?['article_name'] as String?,
      sizeName: (json['sizes'] as Map<String, dynamic>?)?['number'] as String?,
      brandName: (json['brands'] as Map<String, dynamic>?)?['name'] as String?,
      companyName:
          (json['companies'] as Map<String, dynamic>?)?['name'] as String?,
      colorName: (json['colors'] as Map<String, dynamic>?)?['name'] as String?,
      categoryName:
          (json['categories'] as Map<String, dynamic>?)?['name'] as String?,
      typeName: (json['types'] as Map<String, dynamic>?)?['name'] as String?,
      warehouseName:
          (json['warehouses'] as Map<String, dynamic>?)?['warehouse_name']
              as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'barcode': barcode,
      'warehouse_id': warehouseId,
      'product_id': productId,
      'size_id': sizeId,
      'brand_id': brandId,
      if (companyId != null) 'company_id': companyId,
      'color_id': colorId,
      'category_id': categoryId,
      'type_id': typeId,
      'quantity': quantity,
      'discount_pct': discountPct,
    };
  }

  WarehouseStockModel copyWith({
    double? discountPct,
    int? quantity,
  }) {
    return WarehouseStockModel(
      id: id,
      barcode: barcode,
      warehouseId: warehouseId,
      productId: productId,
      sizeId: sizeId,
      brandId: brandId,
      companyId: companyId,
      colorId: colorId,
      categoryId: categoryId,
      typeId: typeId,
      quantity: quantity ?? this.quantity,
      salePrice: salePrice,
      purchasePrice: purchasePrice,
      discountPct: discountPct ?? this.discountPct,
      createdAt: createdAt,
      updatedAt: updatedAt,
      productName: productName,
      sizeName: sizeName,
      brandName: brandName,
      companyName: companyName,
      colorName: colorName,
      categoryName: categoryName,
      typeName: typeName,
      warehouseName: warehouseName,
    );
  }
}

/// Lightweight lookup model used in dropdowns
class StockLookupItem {
  final String id;
  final String label;

  const StockLookupItem({required this.id, required this.label});

  @override
  bool operator ==(Object other) =>
      other is StockLookupItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
