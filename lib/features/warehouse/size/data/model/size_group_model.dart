class SizeGroupModel {
  final String id;
  final String name;
  final List<String> sizeIds;

  const SizeGroupModel({
    required this.id,
    required this.name,
    this.sizeIds = const [],
  });

  factory SizeGroupModel.fromJson(Map<String, dynamic> json) {
    return SizeGroupModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      sizeIds: ((json['size_ids'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'size_ids': sizeIds,
      };
}
