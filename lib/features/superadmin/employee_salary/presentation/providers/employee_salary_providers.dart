import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/employee_salary_datasource.dart';
import '../../data/repositories/employee_salary_repository.dart';
import '../../data/models/employee_salary_model.dart';

final employeeSalaryDatasourceProvider = Provider<EmployeeSalaryDatasource>(
  (_) => EmployeeSalaryDatasource(Supabase.instance.client),
);

final employeeSalaryRepositoryProvider = Provider<EmployeeSalaryRepository>(
  (ref) => EmployeeSalaryRepository(ref.watch(employeeSalaryDatasourceProvider)),
);

final employeeSalariesProvider = FutureProvider<List<EmployeeSalaryModel>>(
  (ref) => ref.watch(employeeSalaryRepositoryProvider).getEmployeeSalaries(),
);
