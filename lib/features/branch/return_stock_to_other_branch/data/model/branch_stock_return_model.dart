export '../../../../warehouse/assign_stock_to_branch/data/models/assign_stock_model.dart'
    show BranchModel;

class BranchStockReturnModel {
  final String id;
  final String returnNumber;
  final String fromBranchId;
  final String? fromBranchName;
  final String toBranchId;
  final String? toBranchName;
  final String status; // pending | accepted | rejected
  final String? notes;
  final DateTime returnedAt;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final List<BranchStockReturnItemModel> items;

  const BranchStockReturnModel({
    required this.id,
    required this.returnNumber,
    required this.fromBranchId,
    this.fromBranchName,
    required this.toBranchId,
    this.toBranchName,
    required this.status,
    this.notes,
    required this.returnedAt,
    this.acceptedAt,
    required this.createdAt,
    this.items = const [],
  });

  factory BranchStockReturnModel.fromJson(Map<String, dynamic> json,
      {List<BranchStockReturnItemModel> items = const []}) {
    final fromBranch = json['from_branch'] as Map<String, dynamic>?;
    final toBranch = json['to_branch'] as Map<String, dynamic>?;
    final itemsJson = items.isNotEmpty
        ? items
        : ((json['branch_stock_return_items'] as List?) ?? const [])
            .map((e) => BranchStockReturnItemModel.fromJson(e as Map<String, dynamic>))
            .toList();

    return BranchStockReturnModel(
      id: json['id'] as String,
      returnNumber: json['return_number'] as String,
      fromBranchId: json['from_branch_id'] as String,
      fromBranchName: fromBranch?['branch_name'] as String?,
      toBranchId: json['to_branch_id'] as String,
      toBranchName: toBranch?['branch_name'] as String?,
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

class BranchStockReturnItemModel {
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

  const BranchStockReturnItemModel({
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

  factory BranchStockReturnItemModel.fromJson(Map<String, dynamic> json) {
    return BranchStockReturnItemModel(
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
