class ExpenseHeadModel {
  final String id;
  final String name;
  final String? description;
  final bool isActive;

  const ExpenseHeadModel({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  factory ExpenseHeadModel.fromJson(Map<String, dynamic> json) {
    return ExpenseHeadModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
