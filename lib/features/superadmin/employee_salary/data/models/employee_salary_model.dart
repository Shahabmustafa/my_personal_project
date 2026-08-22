class EmployeeSalaryModel {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String branchId;
  final String branchName;
  final double salary;
  final double commissionPercent;
  final double totalSales;
  final double totalSalesReturn;
  final double netSalary;
  final DateTime createdAt;

  EmployeeSalaryModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userRole = '',
    required this.branchId,
    required this.branchName,
    required this.salary,
    required this.commissionPercent,
    required this.totalSales,
    required this.totalSalesReturn,
    required this.netSalary,
    required this.createdAt,
  });

  factory EmployeeSalaryModel.fromMap(Map<String, dynamic> map) {
    final user   = map['users']    as Map<String, dynamic>? ?? {};
    final branch = map['branches'] as Map<String, dynamic>? ?? {};

    return EmployeeSalaryModel(
      id:                map['id'] as String,
      userId:            map['user_id'] as String,
      userName:          user['username'] as String? ?? '',
      userRole:          user['role'] as String? ?? '',
      branchId:          map['branch_id'] as String,
      branchName:        branch['branch_name'] as String? ?? '',
      salary:            _toDouble(map['salary']),
      commissionPercent: _toDouble(map['commission_percent']),
      totalSales:        _toDouble(map['total_sales']),
      totalSalesReturn:  _toDouble(map['total_sales_return']),
      netSalary:         _toDouble(map['net_salary']),
      createdAt:         DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id':            userId,
        'branch_id':          branchId,
        'salary':             salary,
        'commission_percent': commissionPercent,
        'total_sales':        totalSales,
        'total_sales_return': totalSalesReturn,
      };

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
