class SaleClaimModel {
  final String id;
  final String claimNumber;
  final String branchId;
  final String? branchName;
  final String headOfficeId;
  final String saleInvoiceId;
  final String? invoiceNumber;
  final String saleInvoiceItemId;
  final String? customerId;
  final String? customerName;
  final String branchStockId;
  final String productId;
  final String? productName;
  final String? sizeName;
  final String? colorName;
  final String? brandName;
  final String? categoryName;
  final String? typeName;
  final String? barcode;
  final int quantity;
  final double salePrice;
  final double purchasePrice;
  final double totalPrice;
  final String reason;
  final DateTime saleDate;
  final DateTime claimDate;
  final String status; // pending | approved | rejected
  final DateTime? reviewedAt;
  final String? reviewRemarks;

  const SaleClaimModel({
    required this.id,
    required this.claimNumber,
    required this.branchId,
    this.branchName,
    required this.headOfficeId,
    required this.saleInvoiceId,
    this.invoiceNumber,
    required this.saleInvoiceItemId,
    this.customerId,
    this.customerName,
    required this.branchStockId,
    required this.productId,
    this.productName,
    this.sizeName,
    this.colorName,
    this.brandName,
    this.categoryName,
    this.typeName,
    this.barcode,
    required this.quantity,
    required this.salePrice,
    required this.purchasePrice,
    required this.totalPrice,
    required this.reason,
    required this.saleDate,
    required this.claimDate,
    required this.status,
    this.reviewedAt,
    this.reviewRemarks,
  });

  bool get isPending => status == 'pending';

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static String? _name(dynamic rel, String key) =>
      (rel as Map<String, dynamic>?)?[key]?.toString();

  static DateTime _date(dynamic v) =>
      DateTime.tryParse(v?.toString() ?? '')?.toLocal() ?? DateTime.now();

  factory SaleClaimModel.fromJson(Map<String, dynamic> json) {
    return SaleClaimModel(
      id: json['id']?.toString() ?? '',
      claimNumber: json['claim_number']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ?? '',
      branchName: _name(json['branches'], 'branch_name'),
      headOfficeId: json['head_office_id']?.toString() ?? '',
      saleInvoiceId: json['sale_invoice_id']?.toString() ?? '',
      invoiceNumber: _name(json['sale_invoices'], 'invoice_number'),
      saleInvoiceItemId: json['sale_invoice_item_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString(),
      customerName: _name(json['customers'], 'name'),
      branchStockId: json['branch_stock_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: _name(json['products'], 'article_name'),
      sizeName: _name(json['sizes'], 'number'),
      colorName: _name(json['colors'], 'name'),
      brandName: _name(json['brands'], 'name'),
      categoryName: _name(json['categories'], 'name'),
      typeName: _name(json['types'], 'name'),
      barcode: json['barcode']?.toString(),
      quantity: (json['quantity'] as num? ?? 0).toInt(),
      salePrice: _toDouble(json['sale_price']),
      purchasePrice: _toDouble(json['purchase_price']),
      totalPrice: _toDouble(json['total_price']),
      reason: json['reason']?.toString() ?? '',
      saleDate: _date(json['sale_date']),
      claimDate: _date(json['claim_date']),
      status: json['status']?.toString() ?? 'pending',
      reviewedAt: json['reviewed_at'] == null ? null : _date(json['reviewed_at']),
      reviewRemarks: json['review_remarks']?.toString(),
    );
  }
}
