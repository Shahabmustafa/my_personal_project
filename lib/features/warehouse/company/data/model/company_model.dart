class CompanyModel {
  final String id;
  final String headOfficeId;
  final String name;
  final String phoneNumber;
  final String email;
  final String address;
  final double openingBalance;
  final DateTime? createdAt;

  const CompanyModel({
    required this.id,
    required this.headOfficeId,
    required this.name,
    this.phoneNumber = '',
    this.email = '',
    this.address = '',
    this.openingBalance = 0,
    this.createdAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id']?.toString() ?? '',
      headOfficeId: json['head_office_id']?.toString() ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'head_office_id': headOfficeId,
        'name': name,
        'phone_number': phoneNumber,
        'email': email,
        'address': address,
        'opening_balance': openingBalance,
      };

  CompanyModel copyWith({
    String? id,
    String? headOfficeId,
    String? name,
    String? phoneNumber,
    String? email,
    String? address,
    double? openingBalance,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      headOfficeId: headOfficeId ?? this.headOfficeId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      openingBalance: openingBalance ?? this.openingBalance,
      createdAt: createdAt,
    );
  }
}
