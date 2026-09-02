class HeadOfficeModel {
  final String id;
  final String headOfficeName;
  final String address;
  final String phoneNumber;
  final String city;
  final String status;
  final DateTime? createdAt;

  const HeadOfficeModel({
    required this.id,
    required this.headOfficeName,
    this.address = '',
    this.phoneNumber = '',
    this.city = '',
    this.status = 'active',
    this.createdAt,
  });

  factory HeadOfficeModel.fromJson(Map<String, dynamic> json) {
    return HeadOfficeModel(
      id: json['id']?.toString() ?? '',
      headOfficeName: json['head_office_name'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      city: json['city'] ?? '',
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'head_office_name': headOfficeName,
        'address': address,
        'phone_number': phoneNumber,
        'city': city,
        'status': status,
      };

  bool get isActive => status == 'active';

  HeadOfficeModel copyWith({
    String? id,
    String? headOfficeName,
    String? address,
    String? phoneNumber,
    String? city,
    String? status,
  }) {
    return HeadOfficeModel(
      id: id ?? this.id,
      headOfficeName: headOfficeName ?? this.headOfficeName,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      city: city ?? this.city,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
