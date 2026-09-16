import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../superadmin/employee_salary/data/models/employee_salary_history_model.dart';
import '../../../../superadmin/employee_salary/data/models/employee_salary_model.dart';
import '../../../../superadmin/employee_salary/presentation/providers/employee_salary_providers.dart';

/// Logged-in salesman ka apna salary/commission record.
final salesmanProfileProvider = FutureProvider<EmployeeSalaryModel?>((ref) {
  final userId = ref.watch(authProvider).user?.id ?? '';
  if (userId.isEmpty) return Future.value(null);
  return ref.read(employeeSalaryRepositoryProvider).getByUser(userId);
});

/// Pichle mahinon ka salary/commission archive — profile record milne ke
/// baad hi resolve hoti hai.
final salesmanSalaryHistoryProvider =
    FutureProvider<List<EmployeeSalaryHistoryModel>>((ref) async {
  final profile = await ref.watch(salesmanProfileProvider.future);
  if (profile == null) return const [];
  return ref.read(employeeSalaryRepositoryProvider).getHistory(profile.id);
});
