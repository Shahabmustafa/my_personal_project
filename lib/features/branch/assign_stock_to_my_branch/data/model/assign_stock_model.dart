// ── Assign Stock to Branch — Models ──────────────────────────────────────

class AssignStockModel {
  final String id;
  final String assignmentNumber;
  final String warehouseId;
  final String branchId;
  final String? branchName;
  final String status; // pending | accepted | rejected
  final String? notes;
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final List<AssignStockItemModel> items;

  const AssignStockModel({
    required this.id,
    required this.assignmentNumber,
    required this.warehouseId,
    required this.branchId,
    this.branchName,
    required this.status,
    this.notes,
    required this.assignedAt,
    this.acceptedAt,
    required this.createdAt,
    this.items = const [],
  });

  factory AssignStockModel.fromJson(Map<String, dynamic> json,
      {List<AssignStockItemModel> items = const []}) {
    return AssignStockModel(
      id: json['id'] as String,
      assignmentNumber: json['assignment_number'] as String,
      warehouseId: json['warehouse_id'] as String,
      branchId: json['branch_id'] as String,
      branchName:
          (json['branches'] as Map<String, dynamic>?)?['branch_name'] as String?,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: items,
    );
  }
}

class AssignStockItemModel {
  final String id;
  final String assignmentId;
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

  // Display names (joined from other tables)
  final String? productName;
  final String? sizeName;
  final String? colorName;
  final String? brandName;
  final String? categoryName;
  final String? typeName;

  const AssignStockItemModel({
    required this.id,
    required this.assignmentId,
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
    this.productName,
    this.sizeName,
    this.colorName,
    this.brandName,
    this.categoryName,
    this.typeName,
  });

  // Helper: Supabase NUMERIC String ya num dono handle karta hai
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory AssignStockItemModel.fromJson(Map<String, dynamic> json) {
    return AssignStockItemModel(
      id: json['id'] as String,
      assignmentId: json['assignment_id'] as String,
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
      productName:
          (json['products'] as Map<String, dynamic>?)?['article_name'] as String?,
      sizeName:
          (json['sizes'] as Map<String, dynamic>?)?['number'] as String?,
      colorName:
          (json['colors'] as Map<String, dynamic>?)?['name'] as String?,
      brandName:
          (json['brands'] as Map<String, dynamic>?)?['name'] as String?,
      categoryName:
          (json['categories'] as Map<String, dynamic>?)?['name'] as String?,
      typeName:
          (json['types'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }
}

/// Branch model (for dropdown)
class BranchModel {
  final String id;
  final String branchName;
  final String? city;
  final String? phone;
  final String status;

  const BranchModel({
    required this.id,
    required this.branchName,
    this.city,
    this.phone,
    required this.status,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] as String,
      branchName: json['branch_name'] as String,
      city: json['city'] as String?,
      phone: json['phone_number'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }

  String get label => branchName + (city != null ? ' — $city' : '');
}

/// Local cart item used in assign stock UI before saving
class AssignCartItem {
  final String stockId;
  final String barcode;
  final String productId;
  final String productName;
  final String sizeId;
  final String sizeName;
  final String colorId;
  final String colorName;
  final String brandId;
  final String brandName;
  final String categoryId;
  final String categoryName;
  final String typeId;
  final String typeName;
  final int warehouseStock; // available qty in warehouse
  int quantity;
  final double salePrice;
  final double purchasePrice;

  AssignCartItem({
    required this.stockId,
    required this.barcode,
    required this.productId,
    required this.productName,
    required this.sizeId,
    required this.sizeName,
    required this.colorId,
    required this.colorName,
    required this.brandId,
    required this.brandName,
    required this.categoryId,
    required this.categoryName,
    required this.typeId,
    required this.typeName,
    required this.warehouseStock,
    required this.quantity,
    required this.salePrice,
    required this.purchasePrice,
  });

  double get lineTotal => salePrice * quantity;

  AssignCartItem copyWith({int? quantity}) {
    return AssignCartItem(
      stockId: stockId,
      barcode: barcode,
      productId: productId,
      productName: productName,
      sizeId: sizeId,
      sizeName: sizeName,
      colorId: colorId,
      colorName: colorName,
      brandId: brandId,
      brandName: brandName,
      categoryId: categoryId,
      categoryName: categoryName,
      typeId: typeId,
      typeName: typeName,
      warehouseStock: warehouseStock,
      quantity: quantity ?? this.quantity,
      salePrice: salePrice,
      purchasePrice: purchasePrice,
    );
  }
}
