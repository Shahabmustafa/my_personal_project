class TypeModel {
  final String id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TypeModel({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory TypeModel.fromJson(Map<String, dynamic> json) {
    return TypeModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
      };

  TypeModel copyWith({
    String? id,
    String? name,
  }) {
    return TypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
