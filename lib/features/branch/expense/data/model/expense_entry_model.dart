class ExpenseEntryModel {
  final String id;
  final String branchId;
  final String branchCashCounterId;
  final String expenseHeadId;
  final String expenseHeadName;
  final double amount;
  final String? note;
  final DateTime createdAt;

  const ExpenseEntryModel({
    required this.id,
    required this.branchId,
    required this.branchCashCounterId,
    required this.expenseHeadId,
    required this.expenseHeadName,
    required this.amount,
    this.note,
    required this.createdAt,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory ExpenseEntryModel.fromJson(Map<String, dynamic> json) {
    final head = json['expense_heads'] as Map<String, dynamic>?;
    return ExpenseEntryModel(
      id: json['id']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ?? '',
      branchCashCounterId: json['branch_cash_counter_id']?.toString() ?? '',
      expenseHeadId: json['expense_head_id']?.toString() ?? '',
      expenseHeadName: head?['name']?.toString() ?? '—',
      amount: _toDouble(json['amount']),
      note: json['note']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
