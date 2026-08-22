import '../datasources/employee_salary_datasource.dart';
import '../models/employee_salary_model.dart';

class EmployeeSalaryRepository {
  final EmployeeSalaryDatasource _datasource;
  EmployeeSalaryRepository(this._datasource);

  Future<List<EmployeeSalaryModel>> getEmployeeSalaries() =>
      _datasource.fetchEmployeeSalaries();

  Future<void> addEmployeeSalary({
    required String userId,
    required String branchId,
    required double salary,
    required double commissionPercent,
    required double totalSales,
    required double totalSalesReturn,
  }) =>
      _datasource.insertEmployeeSalary(
        userId:            userId,
        branchId:          branchId,
        salary:            salary,
        commissionPercent: commissionPercent,
        totalSales:        totalSales,
        totalSalesReturn:  totalSalesReturn,
      );

  Future<void> removeEmployeeSalary(String id) =>
      _datasource.deleteEmployeeSalary(id);
}
