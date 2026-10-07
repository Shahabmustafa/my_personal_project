/// Employee Salary report ki ek row — ek employee ka ek mahine ka hisaab.
/// Current mahina `employee_salary` (live) se aata hai, pichle mahine
/// `employee_salary_history` (1 tareekh ko archive) se.
class EmployeeSalaryReportRow {
  final String employeeSalaryId;
  final String userName;
  final String branchId;
  final String branchName;

  /// Mahine ka pehla din.
  final DateTime month;
  final double salary;
  final double commissionPercent;
  final double totalSales;
  final double totalSalesReturn;
  final double netSalary;

  /// true = abhi chal raha mahina (numbers abhi badal sakte hain).
  final bool isLive;

  const EmployeeSalaryReportRow({
    required this.employeeSalaryId,
    required this.userName,
    required this.branchId,
    required this.branchName,
    required this.month,
    required this.salary,
    required this.commissionPercent,
    required this.totalSales,
    required this.totalSalesReturn,
    required this.netSalary,
    required this.isLive,
  });

  double get netSale => totalSales - totalSalesReturn;

  /// Net salary − basic salary = (sale − return) × commission%.
  double get commissionAmount => netSalary - salary;

  factory EmployeeSalaryReportRow.fromMap(
    Map<String, dynamic> map, {
    required bool isLive,
    DateTime? month,
  }) {
    final user = map['users'] as Map<String, dynamic>? ?? {};
    final branch = map['branches'] as Map<String, dynamic>? ?? {};
    final now = DateTime.now();
    return EmployeeSalaryReportRow(
      employeeSalaryId:
          (isLive ? map['id'] : map['employee_salary_id']) as String,
      userName: user['username'] as String? ?? '',
      branchId: map['branch_id'] as String,
      branchName: branch['branch_name'] as String? ?? '',
      month: month ??
          (isLive
              ? DateTime(now.year, now.month, 1)
              : DateTime.parse(map['period_month'] as String)),
      salary: _toDouble(map['salary']),
      commissionPercent: _toDouble(map['commission_percent']),
      totalSales: _toDouble(map['total_sales']),
      totalSalesReturn: _toDouble(map['total_sales_return']),
      netSalary: _toDouble(map['net_salary']),
      isLive: isLive,
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
