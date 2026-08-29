export '../../../../superadmin/warehouse/data/model/warehouse_model.dart'
    show WarehouseModel;

class BranchWarehouseReturnModel {
  final String id;
  final String returnNumber;
  final String branchId;
  final String? branchName;
  final String warehouseId;
  final String? warehouseName;
  final String status; // pending | accepted | rejected
  final String? notes;
  final DateTime returnedAt;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final List<BranchWarehouseReturnItemModel> items;

  const BranchWarehouseReturnModel({
    required this.id,
    required this.returnNumber,
    required this.branchId,
    this.branchName,
    required this.warehouseId,
    this.warehouseName,
    required this.status,
    this.notes,
    required this.returnedAt,
    this.acceptedAt,
    required this.createdAt,
    this.items = const [],
  });

  factory BranchWarehouseReturnModel.fromJson(Map<String, dynamic> json,
      {List<BranchWarehouseReturnItemModel> items = const []}) {
    final branch = json['branches'] as Map<String, dynamic>?;
    final warehouse = json['warehouses'] as Map<String, dynamic>?;
    final itemsJson = items.isNotEmpty
        ? items
        : ((json['branch_return_to_warehouse_items'] as List?) ?? const [])
            .map((e) => BranchWarehouseReturnItemModel.fromJson(e as Map<String, dynamic>))
            .toList();

    return BranchWarehouseReturnModel(
      id: json['id'] as String,
      returnNumber: json['return_number'] as String,
      branchId: json['branch_id'] as String,
      branchName: branch?['branch_name'] as String?,
      warehouseId: json['warehouse_id'] as String,
      warehouseName: warehouse?['warehouse_name'] as String?,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      returnedAt: DateTime.parse(json['returned_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: itemsJson,
    );
  }
}

class BranchWarehouseReturnItemModel {
  final String id;
  final String returnId;
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

  final String? productName;
  final String? sizeName;
  final String? colorName;
  final String? brandName;
  final String? categoryName;
  final String? typeName;

  const BranchWarehouseReturnItemModel({
    required this.id,
    required this.returnId,
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
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory BranchWarehouseReturnItemModel.fromJson(Map<String, dynamic> json) {
    return BranchWarehouseReturnItemModel(
      id: json['id'] as String,
      returnId: json['return_id'] as String,
      stockId: json['stock_id'] as String,
      barcode: json['barcode'] as String? ?? '',
      productId: json['product_id'] as String,
      sizeId: json['size_id'] as String,
      colorId: json['color_id'] as String,
      brandId: json['brand_id'] as String,
      categoryId: json['category_id'] as String,
      typeId: json['type_id'] as String,
      quantity: (json['quantity'] as num? ?? 0).toInt(),
      salePrice: _toDouble(json['sale_price']),
      purchasePrice: _toDouble(json['purchase_price']),
      discount: _toDouble(json['discount']),
      productName: (json['products'] as Map<String, dynamic>?)?['article_name'] as String?,
      sizeName: (json['sizes'] as Map<String, dynamic>?)?['number'] as String?,
      colorName: (json['colors'] as Map<String, dynamic>?)?['name'] as String?,
      brandName: (json['brands'] as Map<String, dynamic>?)?['name'] as String?,
      categoryName: (json['categories'] as Map<String, dynamic>?)?['name'] as String?,
      typeName: (json['types'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }
}
