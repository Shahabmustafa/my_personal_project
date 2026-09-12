import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../branch/shared/current_branch_provider.dart';
import '../../data/datasources/employee_salary_datasource.dart';
import '../../data/repositories/employee_salary_repository.dart';
import '../../data/models/employee_salary_model.dart';
import '../../data/models/employee_salary_history_model.dart';

final employeeSalaryDatasourceProvider = Provider<EmployeeSalaryDatasource>(
  (_) => EmployeeSalaryDatasource(Supabase.instance.client),
);

final employeeSalaryRepositoryProvider = Provider<EmployeeSalaryRepository>(
  (ref) => EmployeeSalaryRepository(ref.watch(employeeSalaryDatasourceProvider)),
);

final employeeSalariesProvider = FutureProvider<List<EmployeeSalaryModel>>(
  (ref) => ref.watch(employeeSalaryRepositoryProvider).getEmployeeSalaries(),
);

/// Current branch ke employee_salary records — Branch Employee screen ke
/// Sale/Return columns isi se aate hain.
final employeeSalariesForBranchProvider = FutureProvider<List<EmployeeSalaryModel>>(
  (ref) => ref
      .watch(employeeSalaryRepositoryProvider)
      .getByBranch(ref.watch(currentBranchIdProvider)),
);

/// Ek employee_salary record ka past-months history — 1 tareekh ko har
/// mahine ke reset se pehle jo record archive hota hai wo yahan se milta hai.
final employeeSalaryHistoryProvider =
    FutureProvider.family<List<EmployeeSalaryHistoryModel>, String>(
  (ref, employeeSalaryId) =>
      ref.watch(employeeSalaryRepositoryProvider).getHistory(employeeSalaryId),
);
