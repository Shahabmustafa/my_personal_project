class CustomerModel {
  final String id;
  final String branchId;
  final String name;
  final String email;
  final String address;
  final String phoneNumber;
  final double openingBalance;
  final int loyaltyPoints;
  final bool isActive;
  final DateTime? createdAt;

  /// True only for the single shared "Walk-in Customer" record — it has no
  /// branch_id and is visible/selectable from every branch's sale screens.
  final bool isWalkIn;

  const CustomerModel({
    required this.id,
    required this.branchId,
    required this.name,
    this.email = '',
    this.address = '',
    this.phoneNumber = '',
    this.openingBalance = 0,
    this.loyaltyPoints = 0,
    this.isActive = true,
    this.createdAt,
    this.isWalkIn = false,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0,
      loyaltyPoints: (json['loyalty_points'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      isWalkIn: json['is_walkin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'branch_id': branchId,
    'name': name,
    'email': email,
    'address': address,
    'phone_number': phoneNumber,
    'opening_balance': openingBalance,
    'loyalty_points': loyaltyPoints,
    'is_active': isActive,
  };

  CustomerModel copyWith({
    String? id,
    String? branchId,
    String? name,
    String? email,
    String? address,
    String? phoneNumber,
    double? openingBalance,
    int? loyaltyPoints,
    bool? isActive,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      openingBalance: openingBalance ?? this.openingBalance,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      isWalkIn: isWalkIn,
    );
  }

  String get loyaltyTier {
    if (loyaltyPoints >= 1000) return 'Gold';
    if (loyaltyPoints >= 500) return 'Silver';
    return 'Bronze';
  }
}