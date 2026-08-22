class BankEntryModel {
  final String id;
  final String bankId;
  final String bankName;
  final String branchId;
  final String branchName;
  final String branchAddress;
  final String branchCity;
  final String accountNumber;
  final double openingBalance;
  final DateTime createdAt;

  BankEntryModel({
    required this.id,
    required this.bankId,
    required this.bankName,
    required this.branchId,
    required this.branchName,
    this.branchAddress = '',
    this.branchCity = '',
    required this.accountNumber,
    required this.openingBalance,
    required this.createdAt,
  });

  factory BankEntryModel.fromMap(Map<String, dynamic> map) {
    final bankHead = map['bank_heads'] as Map<String, dynamic>? ?? {};
    final branch   = map['branches']  as Map<String, dynamic>? ?? {};

    return BankEntryModel(
      id:             map['id'] as String,
      bankId:         map['bank_id'] as String,
      bankName:       bankHead['bank_name']    as String? ?? '',
      branchId:       map['branch_id'] as String,
      branchName:     branch['branch_name']    as String? ?? '',
      branchAddress:  branch['address']        as String? ?? '',
      branchCity:     branch['city']           as String? ?? '',
      accountNumber:  map['account_number']    as String? ?? '',
      openingBalance: _toDouble(map['opening_balance']),
      createdAt:      DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'bank_id':         bankId,
        'branch_id':       branchId,
        'account_number':  accountNumber,
        'opening_balance': openingBalance,
      };

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
