class WarehouseModel {
  final String id;
  final String warehouseName;
  final String address;
  final String phoneNumber;
  final String city;
  final String status;
  final DateTime? createdAt;

  const WarehouseModel({
    required this.id,
    required this.warehouseName,
    this.address = '',
    this.phoneNumber = '',
    this.city = '',
    this.status = 'active',
    this.createdAt,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      id: json['id']?.toString() ?? '',
      warehouseName: json['warehouse_name'] ?? '',
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
        'warehouse_name': warehouseName,
        'address': address,
        'phone_number': phoneNumber,
        'city': city,
        'status': status,
      };

  bool get isActive => status == 'active';

  WarehouseModel copyWith({
    String? id,
    String? warehouseName,
    String? address,
    String? phoneNumber,
    String? city,
    String? status,
  }) {
    return WarehouseModel(
      id: id ?? this.id,
      warehouseName: warehouseName ?? this.warehouseName,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      city: city ?? this.city,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
