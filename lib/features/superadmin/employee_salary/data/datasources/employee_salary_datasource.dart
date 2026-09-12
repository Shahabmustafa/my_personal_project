import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/employee_salary_model.dart';
import '../models/employee_salary_history_model.dart';

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

  Future<List<EmployeeSalaryModel>> fetchByBranch(String branchId) async {
    final response = await _client
        .from('employee_salary')
        .select('*, users(username, role), branches(branch_name)')
        .eq('branch_id', branchId)
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

  /// Pichle mahinon ka archived total_sales/total_sales_return/net_salary —
  /// har mahine ki 1 tareekh ko cron job yahan record daal deta hai.
  Future<List<EmployeeSalaryHistoryModel>> fetchHistory(
      String employeeSalaryId) async {
    final response = await _client
        .from('employee_salary_history')
        .select()
        .eq('employee_salary_id', employeeSalaryId)
        .order('period_month', ascending: false);

    return (response as List)
        .map((e) =>
            EmployeeSalaryHistoryModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
