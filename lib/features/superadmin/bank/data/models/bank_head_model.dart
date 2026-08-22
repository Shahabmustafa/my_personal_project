class BankHeadModel {
  final String id;
  final String bankName;
  final DateTime createdAt;

  BankHeadModel({
    required this.id,
    required this.bankName,
    required this.createdAt,
  });

  factory BankHeadModel.fromMap(Map<String, dynamic> map) {
    return BankHeadModel(
      id:        map['id'] as String,
      bankName:  map['bank_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {'bank_name': bankName};
}
