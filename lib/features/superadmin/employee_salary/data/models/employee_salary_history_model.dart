class EmployeeSalaryHistoryModel {
  final String id;
  final String employeeSalaryId;
  final DateTime periodMonth;
  final double salary;
  final double commissionPercent;
  final double totalSales;
  final double totalSalesReturn;
  final double netSalary;

  EmployeeSalaryHistoryModel({
    required this.id,
    required this.employeeSalaryId,
    required this.periodMonth,
    required this.salary,
    required this.commissionPercent,
    required this.totalSales,
    required this.totalSalesReturn,
    required this.netSalary,
  });

  factory EmployeeSalaryHistoryModel.fromMap(Map<String, dynamic> map) {
    return EmployeeSalaryHistoryModel(
      id: map['id'] as String,
      employeeSalaryId: map['employee_salary_id'] as String,
      periodMonth: DateTime.parse(map['period_month'] as String),
      salary: _toDouble(map['salary']),
      commissionPercent: _toDouble(map['commission_percent']),
      totalSales: _toDouble(map['total_sales']),
      totalSalesReturn: _toDouble(map['total_sales_return']),
      netSalary: _toDouble(map['net_salary']),
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
