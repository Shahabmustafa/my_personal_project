export '../../../sale_invoice/data/model/sale_invoice_model.dart'
    show SaleCartItem, BankEntryLookupItem, PrinterLookupItem, PaymentInput, EmployeeLookupItem;

class SaleReturnModel {
  final String id;
  final String returnNumber;
  final String branchId;
  final String? printerId;
  final String? cashierId;
  final String? customerId;
  final String? customerName;
  final String? salesmanId;
  final String? salesmanName;
  final double subtotal;
  final double totalDiscount;
  final double totalAmount;
  final String? note;
  final DateTime createdAt;
  final List<SaleReturnItemModel> items;
  final List<SaleReturnPaymentModel> payments;

  const SaleReturnModel({
    required this.id,
    required this.returnNumber,
    required this.branchId,
    this.printerId,
    this.cashierId,
    this.customerId,
    this.customerName,
    this.salesmanId,
    this.salesmanName,
    required this.subtotal,
    required this.totalDiscount,
    required this.totalAmount,
    this.note,
    required this.createdAt,
    this.items = const [],
    this.payments = const [],
  });

  /// Payments se resolve hone wala refund type (cash/card/cash+card) — display ke liye.
  String get paymentTypeLabel {
    if (payments.isEmpty) return '—';
    final types = payments.map((p) => p.paymentType).toSet();
    if (types.length > 1) return 'cash + card';
    return types.first;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory SaleReturnModel.fromJson(Map<String, dynamic> json,
      {List<SaleReturnItemModel> items = const [],
      List<SaleReturnPaymentModel> payments = const []}) {
    final paymentsJson = payments.isNotEmpty
        ? payments
        : ((json['sale_return_payments'] as List?) ?? const [])
            .map((e) => SaleReturnPaymentModel.fromJson(e as Map<String, dynamic>))
            .toList();
    final customer = json['customers'] as Map<String, dynamic>?;
    return SaleReturnModel(
      id: json['id']?.toString() ?? '',
      returnNumber: json['return_number']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ?? '',
      printerId: json['printer_id']?.toString(),
      cashierId: json['cashier_id']?.toString(),
      customerId: json['customer_id']?.toString(),
      customerName: customer?['name']?.toString(),
      salesmanId: json['salesman_id']?.toString(),
      subtotal: _toDouble(json['subtotal']),
      totalDiscount: _toDouble(json['total_discount']),
      totalAmount: _toDouble(json['total_amount']),
      note: json['note']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: items,
      payments: paymentsJson,
    );
  }
}

class SaleReturnPaymentModel {
  final String id;
  final String saleReturnId;
  final String branchId;
  final String? bankEntryId;
  final String paymentType; // cash | card
  final double amount;
  final DateTime createdAt;

  const SaleReturnPaymentModel({
    required this.id,
    required this.saleReturnId,
    required this.branchId,
    this.bankEntryId,
    required this.paymentType,
    required this.amount,
    required this.createdAt,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory SaleReturnPaymentModel.fromJson(Map<String, dynamic> json) {
    return SaleReturnPaymentModel(
      id: json['id']?.toString() ?? '',
      saleReturnId: json['sale_return_id']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ?? '',
      bankEntryId: json['bank_entry_id']?.toString(),
      paymentType: json['payment_type']?.toString() ?? 'cash',
      amount: _toDouble(json['amount']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SaleReturnItemModel {
  final String id;
  final String saleReturnId;
  final String branchStockId;
  final String productId;
  final String? sizeId;
  final String? colorId;
  final String? brandId;
  final String? categoryId;
  final String? typeId;
  final String? barcode;
  final int quantity;
  final double salePrice;
  final double purchasePrice;
  final double discountPct;
  final double discount;
  final double totalPrice;

  final String? productName;
  final String? sizeName;
  final String? colorName;
  final String? brandName;
  final String? categoryName;
  final String? typeName;

  const SaleReturnItemModel({
    required this.id,
    required this.saleReturnId,
    required this.branchStockId,
    required this.productId,
    this.sizeId,
    this.colorId,
    this.brandId,
    this.categoryId,
    this.typeId,
    this.barcode,
    required this.quantity,
    required this.salePrice,
    required this.purchasePrice,
    required this.discountPct,
    required this.discount,
    required this.totalPrice,
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

  factory SaleReturnItemModel.fromJson(Map<String, dynamic> json) {
    return SaleReturnItemModel(
      id: json['id']?.toString() ?? '',
      saleReturnId: json['sale_return_id']?.toString() ?? '',
      branchStockId: json['branch_stock_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      sizeId: json['size_id']?.toString(),
      colorId: json['color_id']?.toString(),
      brandId: json['brand_id']?.toString(),
      categoryId: json['category_id']?.toString(),
      typeId: json['type_id']?.toString(),
      barcode: json['barcode']?.toString(),
      quantity: (json['quantity'] as num? ?? 0).toInt(),
      salePrice: _toDouble(json['sale_price']),
      purchasePrice: _toDouble(json['purchase_price']),
      discountPct: _toDouble(json['discount_pct']),
      discount: _toDouble(json['discount']),
      totalPrice: _toDouble(json['total_price']),
      productName: (json['products'] as Map<String, dynamic>?)?['article_name'] as String?,
      sizeName: (json['sizes'] as Map<String, dynamic>?)?['number'] as String?,
      colorName: (json['colors'] as Map<String, dynamic>?)?['name'] as String?,
      brandName: (json['brands'] as Map<String, dynamic>?)?['name'] as String?,
      categoryName: (json['categories'] as Map<String, dynamic>?)?['name'] as String?,
      typeName: (json['types'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }
}
