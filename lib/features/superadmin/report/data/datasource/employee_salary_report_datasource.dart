import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/employee_salary_report_row.dart';

/// Employee Salary report — current mahina live `employee_salary` se, pichle
/// mahine `employee_salary_history` se (cron 1 tareekh ko archive karta hai).
class EmployeeSalaryReportDatasource {
  final SupabaseClient _client;
  EmployeeSalaryReportDatasource(this._client);

  static const _joins = '*, users(username), branches(branch_name)';

  /// Abhi chal rahe mahine ka live hisaab.
  Future<List<EmployeeSalaryReportRow>> fetchLive({String? branchId}) async {
    var query = _client.from('employee_salary').select(_joins);
    if (branchId != null) query = query.eq('branch_id', branchId);
    final res = await query;
    return (res as List)
        .map((e) => EmployeeSalaryReportRow.fromMap(
            e as Map<String, dynamic>,
            isLive: true))
        .toList();
  }

  /// [month] (pehla din) ka archived hisaab.
  Future<List<EmployeeSalaryReportRow>> fetchMonth(DateTime month,
      {String? branchId}) async {
    var query = _client
        .from('employee_salary_history')
        .select(_joins)
        .eq('period_month', _date(month));
    if (branchId != null) query = query.eq('branch_id', branchId);
    final res = await query;
    return (res as List)
        .map((e) => EmployeeSalaryReportRow.fromMap(
            e as Map<String, dynamic>,
            isLive: false))
        .toList();
  }

  /// Ek employee ke saare mahine — live current mahina + poori history,
  /// naya mahina pehle.
  Future<List<EmployeeSalaryReportRow>> fetchEmployeeMonths(
      String employeeSalaryId) async {
    final results = await Future.wait([
      _client
          .from('employee_salary')
          .select(_joins)
          .eq('id', employeeSalaryId)
          .maybeSingle(),
      _client
          .from('employee_salary_history')
          .select(_joins)
          .eq('employee_salary_id', employeeSalaryId)
          .order('period_month', ascending: false),
    ]);
    final live = results[0] as Map<String, dynamic>?;
    final history = results[1] as List;
    return [
      if (live != null) EmployeeSalaryReportRow.fromMap(live, isLive: true),
      for (final e in history)
        EmployeeSalaryReportRow.fromMap(e as Map<String, dynamic>,
            isLive: false),
    ];
  }

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
