class PurchaseInvoiceModel {
  final String id;
  final String invoiceNumber;
  final String? companyId;
  final String? companyName;
  final String warehouseId;
  final DateTime invoiceDate;
  final double totalAmount;
  final double totalDiscount;
  final double netAmount;
  final double paidAmount;
  final double creditAmount;
  final String paymentMode; // 'cash' | 'credit' | 'partial'
  final String? notes;
  final DateTime createdAt;
  final List<PurchaseInvoiceItemModel> items;

  const PurchaseInvoiceModel({
    required this.id,
    required this.invoiceNumber,
    this.companyId,
    this.companyName,
    required this.warehouseId,
    required this.invoiceDate,
    required this.totalAmount,
    required this.totalDiscount,
    required this.netAmount,
    this.paidAmount = 0,
    this.creditAmount = 0,
    this.paymentMode = 'cash',
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  factory PurchaseInvoiceModel.fromJson(Map<String, dynamic> json,
      {List<PurchaseInvoiceItemModel> items = const []}) {
    return PurchaseInvoiceModel(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      companyId: json['company_id'] as String?,
      companyName:
      (json['companies'] as Map<String, dynamic>?)?['name'] as String?,
      warehouseId: json['warehouse_id'] as String? ?? '',
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      totalAmount: (json['total_amount'] as num).toDouble(),
      totalDiscount: (json['total_discount'] as num).toDouble(),
      netAmount: (json['net_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num? ?? 0).toDouble(),
      creditAmount: (json['credit_amount'] as num? ?? 0).toDouble(),
      paymentMode: json['payment_mode'] as String? ?? 'cash',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: items,
    );
  }
}

class PurchaseInvoiceItemModel {
  final String id;
  final String purchaseInvoiceId;
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

  const PurchaseInvoiceItemModel({
    required this.id,
    required this.purchaseInvoiceId,
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

  factory PurchaseInvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoiceItemModel(
      id: json['id'] as String,
      purchaseInvoiceId: json['purchase_invoice_id'] as String,
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
      productName:
      (json['products'] as Map<String, dynamic>?)?['article_name']
      as String?,
      sizeName: (json['sizes'] as Map<String, dynamic>?)?['number'] as String?,
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

/// Local cart item used in the purchase invoice UI before saving
class PurchaseCartItem {
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

  PurchaseCartItem({
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

  // Purchase price based (company ko payment ke liye)
  double get purchaseDiscountAmount => purchasePrice * discountPct / 100;
  double get purchaseNetPrice => purchasePrice - purchaseDiscountAmount;
  double get purchaseLineTotal => purchaseNetPrice * quantity;

  PurchaseCartItem copyWith({
    int? quantity,
    double? salePrice,
    double? purchasePrice,
    double? discountPct,
  }) {
    return PurchaseCartItem(
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

/// Warehouse cash in hand model
class WarehouseCashInHand {
  final String id;
  final String warehouseId;
  final double amount;

  const WarehouseCashInHand({
    required this.id,
    required this.warehouseId,
    required this.amount,
  });

  factory WarehouseCashInHand.fromJson(Map<String, dynamic> json) {
    return WarehouseCashInHand(
      id: json['id'] as String,
      warehouseId: json['warehouse_id'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

/// Lightweight company info with balance (from companies table)
class CompanyWithBalance {
  final String id;
  final String name;
  final double openingBalance;

  const CompanyWithBalance({
    required this.id,
    required this.name,
    required this.openingBalance,
  });

  factory CompanyWithBalance.fromJson(Map<String, dynamic> json) {
    return CompanyWithBalance(
      id: json['id'] as String,
      name: json['name'] as String,
      openingBalance: (json['opening_balance'] as num? ?? 0).toDouble(),
    );
  }
}