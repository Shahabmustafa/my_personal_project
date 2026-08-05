class SizeModel {
  final String id;
  final String number;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SizeModel({
    required this.id,
    required this.number,
    this.createdAt,
    this.updatedAt,
  });

  factory SizeModel.fromJson(Map<String, dynamic> json) {
    return SizeModel(
      id: json['id']?.toString() ?? '',
      number: json['number'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
      };

  SizeModel copyWith({
    String? id,
    String? number,
  }) {
    return SizeModel(
      id: id ?? this.id,
      number: number ?? this.number,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
