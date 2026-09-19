class BranchPaymentModel {
  final String id;
  final String paymentNumber;
  final String branchId;
  final String? branchName;
  final String headOfficeId;
  final double amount;
  final String status; // pending | accepted | rejected
  final String? notes;
  final DateTime paidAt;
  final DateTime? acceptedAt;

  const BranchPaymentModel({
    required this.id,
    required this.paymentNumber,
    required this.branchId,
    this.branchName,
    required this.headOfficeId,
    required this.amount,
    required this.status,
    this.notes,
    required this.paidAt,
    this.acceptedAt,
  });

  factory BranchPaymentModel.fromJson(Map<String, dynamic> json) {
    final branch = json['branches'] as Map<String, dynamic>?;
    return BranchPaymentModel(
      id: json['id'] as String,
      paymentNumber: json['payment_number'] as String,
      branchId: json['branch_id'] as String,
      branchName: branch?['branch_name'] as String?,
      headOfficeId: json['head_office_id'] as String,
      amount: double.tryParse('${json['amount']}') ?? 0,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      paidAt: DateTime.parse(json['paid_at'] as String).toLocal(),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String).toLocal()
          : null,
    );
  }
}
