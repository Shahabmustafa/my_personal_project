export '../../../sale_invoice/data/model/sale_invoice_model.dart'
    show SaleCartItem, EmployeeLookupItem, BankEntryLookupItem, PrinterLookupItem;

class SaleExchangeModel {
  final String id;
  final String exchangeNumber;
  final String branchId;
  final String? originalInvoiceId;
  final String? originalInvoiceNumber;
  final String? printerId;
  final String? cashierId;
  final String? customerId;
  final String? customerName;
  final String? branchName;
  final String? salesmanId;
  final String? salesmanName;
  final double returnSubtotal;
  final double returnDiscount;
  final double returnTotal;
  final double newSubtotal;
  final double newDiscount;
  final double newTotal;
  final double differenceAmount;
  final double salesmanCommissionPercent;
  final double salesmanCommissionAmount;
  final String? note;
  final DateTime createdAt;
  final List<SaleExchangeReturnItemModel> returnItems;
  final List<SaleExchangeNewItemModel> newItems;
  final List<SaleExchangePaymentModel> payments;

  const SaleExchangeModel({
    required this.id,
    required this.exchangeNumber,
    required this.branchId,
    this.originalInvoiceId,
    this.originalInvoiceNumber,
    this.printerId,
    this.cashierId,
    this.customerId,
    this.customerName,
    this.branchName,
    this.salesmanId,
    this.salesmanName,
    required this.returnSubtotal,
    required this.returnDiscount,
    required this.returnTotal,
    required this.newSubtotal,
    required this.newDiscount,
    required this.newTotal,
    required this.differenceAmount,
    this.salesmanCommissionPercent = 0,
    this.salesmanCommissionAmount = 0,
    this.note,
    required this.createdAt,
    this.returnItems = const [],
    this.newItems = const [],
    this.payments = const [],
  });

  /// >0 => customer se extra collect hua, <0 => customer ko refund hua, 0 => even swap
  String get differenceLabel {
    if (differenceAmount > 0) return 'Collect';
    if (differenceAmount < 0) return 'Refund';
    return 'Even';
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory SaleExchangeModel.fromJson(Map<String, dynamic> json,
      {List<SaleExchangeReturnItemModel> returnItems = const [],
      List<SaleExchangeNewItemModel> newItems = const [],
      List<SaleExchangePaymentModel> payments = const []}) {
    final salesmanUser =
        (json['salesman'] as Map<String, dynamic>?)?['users'] as Map<String, dynamic>?;
    final customer = json['customers'] as Map<String, dynamic>?;
    final originalInvoice = json['sale_invoices'] as Map<String, dynamic>?;
    final branch = json['branches'] as Map<String, dynamic>?;
    final paymentsJson = payments.isNotEmpty
        ? payments
        : ((json['sale_exchange_payments'] as List?) ?? const [])
            .map((e) => SaleExchangePaymentModel.fromJson(e as Map<String, dynamic>))
            .toList();
    final newItemsJson = newItems.isNotEmpty
        ? newItems
        : ((json['sale_exchange_new_items'] as List?) ?? const [])
            .map((e) => SaleExchangeNewItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
    final returnItemsJson = returnItems.isNotEmpty
        ? returnItems
        : ((json['sale_exchange_return_items'] as List?) ?? const [])
            .map((e) => SaleExchangeReturnItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
    return SaleExchangeModel(
      id: json['id']?.toString() ?? '',
      exchangeNumber: json['exchange_number']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ?? '',
      originalInvoiceId: json['original_invoice_id']?.toString(),
      originalInvoiceNumber: originalInvoice?['invoice_number']?.toString(),
      printerId: json['printer_id']?.toString(),
      cashierId: json['cashier_id']?.toString(),
      customerId: json['customer_id']?.toString(),
      customerName: customer?['name']?.toString(),
      branchName: branch?['branch_name']?.toString(),
      salesmanId: json['salesman_id']?.toString(),
      salesmanName: salesmanUser?['username']?.toString(),
      returnSubtotal: _toDouble(json['return_subtotal']),
      returnDiscount: _toDouble(json['return_discount']),
      returnTotal: _toDouble(json['return_total']),
      newSubtotal: _toDouble(json['new_subtotal']),
      newDiscount: _toDouble(json['new_discount']),
      newTotal: _toDouble(json['new_total']),
      differenceAmount: _toDouble(json['difference_amount']),
      salesmanCommissionPercent: _toDouble(json['salesman_commission_percent']),
      salesmanCommissionAmount: _toDouble(json['salesman_commission_amount']),
      note: json['note']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      returnItems: returnItemsJson,
      newItems: newItemsJson,
      payments: paymentsJson,
    );
  }
}

/// Local input for a payment leg to insert against a saved exchange —
/// direction tells the DB trigger whether to bump received_amount_in_exchange
/// (collect) or return_amount_in_exchange (refund) on branch_cash_counter.
class ExchangePaymentInput {
  final String direction; // collect | refund
  final String type; // cash | card
  final double amount;
  final String? bankEntryId;

  const ExchangePaymentInput({
    required this.direction,
    required this.type,
    required this.amount,
    this.bankEntryId,
  });
}

class SaleExchangePaymentModel {
  final String id;
  final String saleExchangeId;
  final String branchId;
  final String? bankEntryId;
  final String direction; // collect | refund
  final String paymentType; // cash | card
  final double amount;
  final DateTime createdAt;

  const SaleExchangePaymentModel({
    required this.id,
    required this.saleExchangeId,
    required this.branchId,
    this.bankEntryId,
    required this.direction,
    required this.paymentType,
    required this.amount,
    required this.createdAt,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory SaleExchangePaymentModel.fromJson(Map<String, dynamic> json) {
    return SaleExchangePaymentModel(
      id: json['id']?.toString() ?? '',
      saleExchangeId: json['sale_exchange_id']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ?? '',
      bankEntryId: json['bank_entry_id']?.toString(),
      direction: json['direction']?.toString() ?? 'collect',
      paymentType: json['payment_type']?.toString() ?? 'cash',
      amount: _toDouble(json['amount']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SaleExchangeReturnItemModel {
  final String id;
  final String saleExchangeId;
  final String branchStockId;
  final String? originalSaleInvoiceItemId;
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

  const SaleExchangeReturnItemModel({
    required this.id,
    required this.saleExchangeId,
    required this.branchStockId,
    this.originalSaleInvoiceItemId,
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

  factory SaleExchangeReturnItemModel.fromJson(Map<String, dynamic> json) {
    return SaleExchangeReturnItemModel(
      id: json['id']?.toString() ?? '',
      saleExchangeId: json['sale_exchange_id']?.toString() ?? '',
      branchStockId: json['branch_stock_id']?.toString() ?? '',
      originalSaleInvoiceItemId: json['original_sale_invoice_item_id']?.toString(),
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

class SaleExchangeNewItemModel {
  final String id;
  final String saleExchangeId;
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

  const SaleExchangeNewItemModel({
    required this.id,
    required this.saleExchangeId,
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

  factory SaleExchangeNewItemModel.fromJson(Map<String, dynamic> json) {
    return SaleExchangeNewItemModel(
      id: json['id']?.toString() ?? '',
      saleExchangeId: json['sale_exchange_id']?.toString() ?? '',
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

/// Local cart row for the "returning" side of the exchange UI — built from
/// the original invoice's items, quantity starts at 0 until the cashier
/// opts a line in (capped at maxQuantity = what was actually sold on that line).
class ReturnCartItem {
  final String originalItemId;
  final String branchStockId;
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
  final int maxQuantity;
  final int quantity;
  final double salePrice;
  final double purchasePrice;
  final double discountPct;

  const ReturnCartItem({
    required this.originalItemId,
    required this.branchStockId,
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
    required this.maxQuantity,
    required this.quantity,
    required this.salePrice,
    required this.purchasePrice,
    required this.discountPct,
  });

  double get discountAmount => salePrice * discountPct / 100;
  double get netPrice => salePrice - discountAmount;
  double get lineTotal => netPrice * quantity;

  ReturnCartItem copyWith({int? quantity}) {
    return ReturnCartItem(
      originalItemId: originalItemId,
      branchStockId: branchStockId,
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
      maxQuantity: maxQuantity,
      quantity: quantity ?? this.quantity,
      salePrice: salePrice,
      purchasePrice: purchasePrice,
      discountPct: discountPct,
    );
  }
}
