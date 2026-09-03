class SaleInvoiceModel {
  final String id;
  final String invoiceNumber;
  final String branchId;
  final String? printerId;
  final String? cashierId;
  final String? customerId;
  final String? customerName;
  final String? branchName;
  final String? salesmanId;
  final String? salesmanName;
  final String? managerId;
  final String? managerName;
  final double subtotal;
  final double totalDiscount;
  final double invoiceDiscount;
  final double totalAmount;
  final double salesmanCommissionPercent;
  final double salesmanCommissionAmount;
  final double managerCommissionPercent;
  final double managerCommissionAmount;
  final String? note;
  final DateTime createdAt;
  final List<SaleInvoiceItemModel> items;
  final List<SaleInvoicePaymentModel> payments;
  final bool hasReturn;
  final bool hasExchange;

  const SaleInvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.branchId,
    this.printerId,
    this.cashierId,
    this.customerId,
    this.customerName,
    this.branchName,
    this.salesmanId,
    this.salesmanName,
    this.managerId,
    this.managerName,
    required this.subtotal,
    required this.totalDiscount,
    this.invoiceDiscount = 0,
    required this.totalAmount,
    this.salesmanCommissionPercent = 0,
    this.salesmanCommissionAmount = 0,
    this.managerCommissionPercent = 0,
    this.managerCommissionAmount = 0,
    this.note,
    required this.createdAt,
    this.items = const [],
    this.payments = const [],
    this.hasReturn = false,
    this.hasExchange = false,
  });

  /// Payments se resolve hone wala payment type (cash/card/cash+card) — display ke liye.
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

  factory SaleInvoiceModel.fromJson(Map<String, dynamic> json,
      {List<SaleInvoiceItemModel> items = const [],
      List<SaleInvoicePaymentModel> payments = const []}) {
    final salesmanUser =
        (json['salesman'] as Map<String, dynamic>?)?['users'] as Map<String, dynamic>?;
    final managerUser =
        (json['manager'] as Map<String, dynamic>?)?['users'] as Map<String, dynamic>?;
    final customer = json['customers'] as Map<String, dynamic>?;
    final branch = json['branches'] as Map<String, dynamic>?;
    final paymentsJson = payments.isNotEmpty
        ? payments
        : ((json['sale_invoice_payments'] as List?) ?? const [])
            .map((e) => SaleInvoicePaymentModel.fromJson(e as Map<String, dynamic>))
            .toList();
    final itemsJson = items.isNotEmpty
        ? items
        : ((json['sale_invoice_items'] as List?) ?? const [])
            .map((e) => SaleInvoiceItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
    return SaleInvoiceModel(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ?? '',
      printerId: json['printer_id']?.toString(),
      cashierId: json['cashier_id']?.toString(),
      customerId: json['customer_id']?.toString(),
      customerName: customer?['name']?.toString(),
      branchName: branch?['branch_name']?.toString(),
      salesmanId: json['salesman_id']?.toString(),
      salesmanName: salesmanUser?['username']?.toString(),
      managerId: json['manager_id']?.toString(),
      managerName: managerUser?['username']?.toString(),
      subtotal: _toDouble(json['subtotal']),
      totalDiscount: _toDouble(json['total_discount']),
      invoiceDiscount: _toDouble(json['invoice_discount']),
      totalAmount: _toDouble(json['total_amount']),
      salesmanCommissionPercent: _toDouble(json['salesman_commission_percent']),
      salesmanCommissionAmount: _toDouble(json['salesman_commission_amount']),
      managerCommissionPercent: _toDouble(json['manager_commission_percent']),
      managerCommissionAmount: _toDouble(json['manager_commission_amount']),
      note: json['note']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: itemsJson,
      payments: paymentsJson,
      hasReturn: ((json['sale_returns'] as List?) ?? const []).isNotEmpty,
      hasExchange: ((json['sale_exchanges'] as List?) ?? const []).isNotEmpty,
    );
  }
}

/// One payment leg to insert for an invoice/return — a 'cash + card' sale
/// results in two of these (one 'cash', one 'card') against the same invoice.
class PaymentInput {
  final String type; // cash | card
  final double amount;
  final String? bankEntryId;

  const PaymentInput({required this.type, required this.amount, this.bankEntryId});
}

class SaleInvoicePaymentModel {
  final String id;
  final String saleInvoiceId;
  final String branchId;
  final String? bankEntryId;
  final String paymentType; // cash | card
  final double amount;
  final DateTime createdAt;

  const SaleInvoicePaymentModel({
    required this.id,
    required this.saleInvoiceId,
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

  factory SaleInvoicePaymentModel.fromJson(Map<String, dynamic> json) {
    return SaleInvoicePaymentModel(
      id: json['id']?.toString() ?? '',
      saleInvoiceId: json['sale_invoice_id']?.toString() ?? '',
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

class SaleInvoiceItemModel {
  final String id;
  final String saleInvoiceId;
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

  const SaleInvoiceItemModel({
    required this.id,
    required this.saleInvoiceId,
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

  factory SaleInvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return SaleInvoiceItemModel(
      id: json['id']?.toString() ?? '',
      saleInvoiceId: json['sale_invoice_id']?.toString() ?? '',
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

/// Local cart item used in the sale invoice UI before saving
class SaleCartItem {
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
  final int availableStock;
  int quantity;
  double salePrice;
  final double purchasePrice;
  double discountPct;

  SaleCartItem({
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
    required this.availableStock,
    required this.quantity,
    required this.salePrice,
    required this.purchasePrice,
    required this.discountPct,
  });

  double get discountAmount => salePrice * discountPct / 100;
  double get netPrice => salePrice - discountAmount;
  double get lineTotal => netPrice * quantity;

  SaleCartItem copyWith({
    int? quantity,
    double? salePrice,
    double? discountPct,
  }) {
    return SaleCartItem(
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
      availableStock: availableStock,
      quantity: quantity ?? this.quantity,
      salePrice: salePrice ?? this.salePrice,
      purchasePrice: purchasePrice,
      discountPct: discountPct ?? this.discountPct,
    );
  }
}

/// Lightweight employee lookup (salesman / manager) with default commission %
class EmployeeLookupItem {
  final String id; // employee_salary.id
  final String userId; // users.id — cashier_id is a users FK, not employee_salary
  final String name;
  final String role;
  final double commissionPercent;

  const EmployeeLookupItem({
    required this.id,
    this.userId = '',
    required this.name,
    required this.role,
    required this.commissionPercent,
  });

  @override
  bool operator ==(Object other) =>
      other is EmployeeLookupItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Lightweight bank entry lookup (for card sales)
class BankEntryLookupItem {
  final String id;
  final String label;

  const BankEntryLookupItem({required this.id, required this.label});

  @override
  bool operator ==(Object other) =>
      other is BankEntryLookupItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Lightweight printer lookup. [label] is the printer head's name — also
/// used to match the physical OS printer for direct silent printing on
/// desktop. [address]/[phoneNumber] come from the same printer head record
/// and are printed on the receipt as the shop's branch header.
class PrinterLookupItem {
  final String id;
  final String label;
  final String address;
  final String phoneNumber;
  final String imageUrl;

  const PrinterLookupItem({
    required this.id,
    required this.label,
    this.address = '',
    this.phoneNumber = '',
    this.imageUrl = '',
  });

  @override
  bool operator ==(Object other) =>
      other is PrinterLookupItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
