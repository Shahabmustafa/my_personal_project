// ── Purchase Return Models ────────────────────────────────────────────────

class PurchaseReturnModel {
  final String id;
  final String returnNumber;
  final String? originalInvoiceId;
  final String? companyId;
  final String? companyName;
  final String warehouseId;
  final DateTime returnDate;
  final double totalAmount;
  final double totalDiscount;
  final double netAmount;
  final String? notes;
  final DateTime createdAt;
  final List<PurchaseReturnItemModel> items;

  const PurchaseReturnModel({
    required this.id,
    required this.returnNumber,
    this.originalInvoiceId,
    this.companyId,
    this.companyName,
    required this.warehouseId,
    required this.returnDate,
    required this.totalAmount,
    required this.totalDiscount,
    required this.netAmount,
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  factory PurchaseReturnModel.fromJson(
      Map<String, dynamic> json, {
        List<PurchaseReturnItemModel> items = const [],
      }) {
    return PurchaseReturnModel(
      id: json['id'] as String,
      returnNumber: json['return_number'] as String,
      originalInvoiceId: json['original_invoice_id'] as String?,
      companyId: json['company_id'] as String?,
      companyName:
      (json['companies'] as Map<String, dynamic>?)?['name'] as String?,
      warehouseId: json['warehouse_id'] as String? ?? '',
      returnDate: DateTime.parse(json['return_date'] as String),
      totalAmount: (json['total_amount'] as num).toDouble(),
      totalDiscount: (json['total_discount'] as num).toDouble(),
      netAmount: (json['net_amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: items,
    );
  }
}

class PurchaseReturnItemModel {
  final String id;
  final String purchaseReturnId;
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
  final double discountPct;
  final double discountAmount;
  final double netPrice;
  final double lineTotal;

  final String? productName;
  final String? sizeName;
  final String? colorName;
  final String? brandName;
  final String? categoryName;
  final String? typeName;

  const PurchaseReturnItemModel({
    required this.id,
    required this.purchaseReturnId,
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
    required this.discountPct,
    required this.discountAmount,
    required this.netPrice,
    required this.lineTotal,
    this.productName,
    this.sizeName,
    this.colorName,
    this.brandName,
    this.categoryName,
    this.typeName,
  });

  factory PurchaseReturnItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnItemModel(
      id: json['id'] as String,
      purchaseReturnId: json['purchase_return_id'] as String,
      stockId: json['stock_id'] as String,
      barcode: json['barcode'] as String,
      productId: json['product_id'] as String,
      sizeId: json['size_id'] as String,
      colorId: json['color_id'] as String,
      brandId: json['brand_id'] as String,
      categoryId: json['category_id'] as String,
      typeId: json['type_id'] as String,
      quantity: json['quantity'] as int,
      salePrice: (json['sale_price'] as num).toDouble(),
      purchasePrice: (json['purchase_price'] as num? ?? 0).toDouble(),
      discountPct: (json['discount_pct'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num).toDouble(),
      netPrice: (json['net_price'] as num).toDouble(),
      lineTotal: (json['line_total'] as num).toDouble(),
      productName: (json['products'] as Map<String, dynamic>?)?['article_name']
      as String?,
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

/// Local cart item for purchase return UI (before saving)
class ReturnCartItem {
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
  final int totalStock;
  int quantity;
  double salePrice;
  double purchasePrice;
  double discountPct;

  ReturnCartItem({
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
    required this.totalStock,
    required this.quantity,
    required this.salePrice,
    required this.purchasePrice,
    required this.discountPct,
  });

  // Sale price based (branch mein sale ke liye)
  double get discountAmount => salePrice * discountPct / 100;
  double get netPrice => salePrice - discountAmount;
  double get lineTotal => netPrice * quantity;

  // Purchase price based (company ko/se payment ke liye)
  double get purchaseDiscountAmount => purchasePrice * discountPct / 100;
  double get purchaseNetPrice => purchasePrice - purchaseDiscountAmount;
  double get purchaseLineTotal => purchaseNetPrice * quantity;

  ReturnCartItem copyWith({
    int? quantity,
    double? salePrice,
    double? purchasePrice,
    double? discountPct,
  }) {
    return ReturnCartItem(
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
      totalStock: totalStock,
      quantity: quantity ?? this.quantity,
      salePrice: salePrice ?? this.salePrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      discountPct: discountPct ?? this.discountPct,
    );
  }
}

/// Warehouse cash counter model (replaces WarehouseCashInHand)
class WarehouseCashCounter {
  final String id;
  final String warehouseId;
  final DateTime counterDate;
  final double netAmount;           // cash in hand
  final double totalPurchase;       // aaj ki purchases (0 se start)
  final double totalReturnPurchase; // aaj ki returns (0 se start)
  final double expense;             // aaj ka expense (0 se start)

  const WarehouseCashCounter({
    required this.id,
    required this.warehouseId,
    required this.counterDate,
    required this.netAmount,
    required this.totalPurchase,
    required this.totalReturnPurchase,
    required this.expense,
  });

  factory WarehouseCashCounter.fromJson(Map<String, dynamic> json) {
    return WarehouseCashCounter(
      id: json['id'] as String,
      warehouseId: json['warehouse_id'] as String? ?? '',
      counterDate: DateTime.parse(json['counter_date'] as String),
      netAmount: (json['net_amount'] as num? ?? 0).toDouble(),
      totalPurchase: (json['total_purchase'] as num? ?? 0).toDouble(),
      totalReturnPurchase:
      (json['total_return_purchase'] as num? ?? 0).toDouble(),
      expense: (json['expense'] as num? ?? 0).toDouble(),
    );
  }
}