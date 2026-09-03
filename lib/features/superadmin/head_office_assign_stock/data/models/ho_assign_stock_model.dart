// ── Head Office → Assign Stock to Branch — Models ────────────────────────
// Warehouse feature ke models jaisa hi, bas warehouseId ki jagah headOfficeId.

class HoAssignStockModel {
  final String id;
  final String assignmentNumber;
  final String? headOfficeId;
  final String branchId;
  final String? branchName;
  final String status; // pending | accepted | rejected
  final String? notes;
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final List<HoAssignStockItemModel> items;

  /// Assignment ki total pairs / kitni product lines — list screen ke
  /// summary cards ke liye. `assign_stock_to_branch_items(quantity)` embed
  /// se aata hai (ya poore items load hon to unse).
  final int totalPairs;
  final int lineCount;

  const HoAssignStockModel({
    required this.id,
    required this.assignmentNumber,
    this.headOfficeId,
    required this.branchId,
    this.branchName,
    required this.status,
    this.notes,
    required this.assignedAt,
    this.acceptedAt,
    required this.createdAt,
    this.items = const [],
    this.totalPairs = 0,
    this.lineCount = 0,
  });

  factory HoAssignStockModel.fromJson(Map<String, dynamic> json,
      {List<HoAssignStockItemModel> items = const []}) {
    final embedded =
        (json['assign_stock_to_branch_items'] as List?) ?? const [];
    final resolvedPairs = items.isNotEmpty
        ? items.fold<int>(0, (s, it) => s + it.quantity)
        : embedded.fold<int>(
            0,
            (s, it) =>
                s + ((it as Map)['quantity'] as num? ?? 0).toInt(),
          );
    final resolvedLines = items.isNotEmpty ? items.length : embedded.length;
    return HoAssignStockModel(
      id: json['id'] as String,
      assignmentNumber: json['assignment_number'] as String,
      headOfficeId: json['head_office_id'] as String?,
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
      totalPairs: resolvedPairs,
      lineCount: resolvedLines,
    );
  }
}

class HoAssignStockItemModel {
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
  final double discount;

  final String? productName;
  final String? sizeName;
  final String? colorName;
  final String? brandName;
  final String? categoryName;
  final String? typeName;

  const HoAssignStockItemModel({
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
    this.discount = 0,
    this.productName,
    this.sizeName,
    this.colorName,
    this.brandName,
    this.categoryName,
    this.typeName,
  });

  factory HoAssignStockItemModel.fromJson(Map<String, dynamic> json) {
    return HoAssignStockItemModel(
      id: json['id'] as String,
      assignmentId: json['assignment_id'] as String,
      stockId: json['stock_id'] as String,
      barcode: json['barcode'] as String,
      productId: json['product_id'] as String,
      sizeId: json['size_id'] as String,
      colorId: json['color_id'] as String,
      brandId: json['brand_id'] as String,
      categoryId: json['category_id'] as String,
      typeId: json['type_id'] as String,
      quantity: json['quantity'] as int,
      salePrice: (json['sale_price'] as num? ?? 0).toDouble(),
      purchasePrice: (json['purchase_price'] as num? ?? 0).toDouble(),
      discount: (json['discount'] as num? ?? 0).toDouble(),
      productName:
          (json['products'] as Map<String, dynamic>?)?['article_name'] as String?,
      sizeName: (json['sizes'] as Map<String, dynamic>?)?['number'] as String?,
      colorName: (json['colors'] as Map<String, dynamic>?)?['name'] as String?,
      brandName: (json['brands'] as Map<String, dynamic>?)?['name'] as String?,
      categoryName:
          (json['categories'] as Map<String, dynamic>?)?['name'] as String?,
      typeName: (json['types'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }
}

/// Branch model (for dropdown)
class HoBranchModel {
  final String id;
  final String branchName;
  final String? city;
  final String? phone;
  final String status;

  const HoBranchModel({
    required this.id,
    required this.branchName,
    this.city,
    this.phone,
    required this.status,
  });

  factory HoBranchModel.fromJson(Map<String, dynamic> json) {
    return HoBranchModel(
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
class HoAssignCartItem {
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
  final int headOfficeStock; // available qty in head office
  int quantity;
  final double salePrice;
  final double purchasePrice;
  final double discount;

  HoAssignCartItem({
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
    required this.headOfficeStock,
    required this.quantity,
    required this.salePrice,
    required this.purchasePrice,
    this.discount = 0,
  });

  double get lineTotal => salePrice * quantity;

  HoAssignCartItem copyWith({int? quantity}) {
    return HoAssignCartItem(
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
      headOfficeStock: headOfficeStock,
      quantity: quantity ?? this.quantity,
      salePrice: salePrice,
      purchasePrice: purchasePrice,
      discount: discount,
    );
  }
}
