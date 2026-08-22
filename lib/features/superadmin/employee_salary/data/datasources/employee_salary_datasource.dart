import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/employee_salary_model.dart';

class EmployeeSalaryDatasource {
  final SupabaseClient _client;
  EmployeeSalaryDatasource(this._client);

  Future<List<EmployeeSalaryModel>> fetchEmployeeSalaries() async {
    final response = await _client
        .from('employee_salary')
        .select('*, users(username, role), branches(branch_name)')
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => EmployeeSalaryModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertEmployeeSalary({
    required String userId,
    required String branchId,
    required double salary,
    required double commissionPercent,
    required double totalSales,
    required double totalSalesReturn,
  }) async {
    await _client.from('employee_salary').insert({
      'user_id':            userId,
      'branch_id':          branchId,
      'salary':             salary,
      'commission_percent': commissionPercent,
      'total_sales':        totalSales,
      'total_sales_return': totalSalesReturn,
    });
  }

  Future<void> deleteEmployeeSalary(String id) async {
    await _client.from('employee_salary').delete().eq('id', id);
  }
}
