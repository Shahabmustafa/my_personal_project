class BranchModel {
  final String id;
  final String branchName;
  final String address;
  final String phoneNumber;
  final String city;
  final String status;
  final bool canApplyInvoiceDiscount;

  /// Max percentage (0..100) is branch ka cashier sale invoice par extra
  /// (invoice-wise) discount ke taur par laga sakta hai. Superadmin isko
  /// "Discount → Branch Invoice Discount" screen se set karta hai.
  /// 0 = branch koi invoice discount nahi laga sakta.
  final double maxInvoiceDiscountPct;
  final DateTime? createdAt;

  const BranchModel({
    required this.id,
    required this.branchName,
    this.address = '',
    this.phoneNumber = '',
    this.city = '',
    this.status = 'active',
    this.canApplyInvoiceDiscount = false,
    this.maxInvoiceDiscountPct = 0,
    this.createdAt,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id']?.toString() ?? '',
      branchName: json['branch_name'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      city: json['city'] ?? '',
      status: json['status'] ?? 'active',
      canApplyInvoiceDiscount: json['can_apply_invoice_discount'] as bool? ?? false,
      maxInvoiceDiscountPct:
          (json['max_invoice_discount_pct'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'branch_name': branchName,
        'address': address,
        'phone_number': phoneNumber,
        'city': city,
        'status': status,
        'can_apply_invoice_discount': canApplyInvoiceDiscount,
        'max_invoice_discount_pct': maxInvoiceDiscountPct,
      };

  bool get isActive => status == 'active';

  BranchModel copyWith({
    String? id,
    String? branchName,
    String? address,
    String? phoneNumber,
    String? city,
    String? status,
    bool? canApplyInvoiceDiscount,
    double? maxInvoiceDiscountPct,
  }) {
    return BranchModel(
      id: id ?? this.id,
      branchName: branchName ?? this.branchName,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      city: city ?? this.city,
      status: status ?? this.status,
      canApplyInvoiceDiscount: canApplyInvoiceDiscount ?? this.canApplyInvoiceDiscount,
      maxInvoiceDiscountPct: maxInvoiceDiscountPct ?? this.maxInvoiceDiscountPct,
      createdAt: createdAt,
    );
  }
}
