import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/employee_salary_report_datasource.dart';
import '../../data/model/employee_salary_report_row.dart';

final employeeSalaryReportDatasourceProvider =
    Provider<EmployeeSalaryReportDatasource>(
  (ref) => EmployeeSalaryReportDatasource(Supabase.instance.client),
);

class EmployeeSalaryReportState {
  final List<EmployeeSalaryReportRow> rows;
  final bool isLoading;
  final String? error;

  /// Chuna hua mahina (pehla din).
  final DateTime month;

  /// null = sab branches.
  final String? branchId;

  EmployeeSalaryReportState({
    this.rows = const [],
    this.isLoading = false,
    this.error,
    DateTime? month,
    this.branchId,
  }) : month = month ?? _thisMonth();

  static DateTime _thisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String monthLabel(DateTime m) => '${_months[m.month - 1]} ${m.year}';

  String get periodLabel => monthLabel(month);

  bool get isCurrentMonth => month == _thisMonth();

  /// Aage wala mahina abhi shuru nahi hua.
  bool get canGoNext => month.isBefore(_thisMonth());

  double get totalSalary => rows.fold(0, (s, r) => s + r.salary);
  double get totalCommission => rows.fold(0, (s, r) => s + r.commissionAmount);
  double get totalNetSalary => rows.fold(0, (s, r) => s + r.netSalary);
  double get totalNetSale => rows.fold(0, (s, r) => s + r.netSale);

  EmployeeSalaryReportState copyWith({
    List<EmployeeSalaryReportRow>? rows,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? month,
    String? branchId,
    bool clearBranch = false,
  }) =>
      EmployeeSalaryReportState(
        rows: rows ?? this.rows,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        month: month ?? this.month,
        branchId: clearBranch ? null : branchId ?? this.branchId,
      );
}

/// Har employee ka chune hue mahine ka salary + commission hisaab.
class EmployeeSalaryReportNotifier
    extends StateNotifier<EmployeeSalaryReportState> {
  final EmployeeSalaryReportDatasource _ds;
  EmployeeSalaryReportNotifier(this._ds) : super(EmployeeSalaryReportState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final requested = state.month;
    try {
      final rows = state.isCurrentMonth
          ? await _ds.fetchLive(branchId: state.branchId)
          : await _ds.fetchMonth(requested, branchId: state.branchId);
      // Jaldi jaldi mahina badla ho to purana jawab ignore.
      if (state.month != requested) return;
      rows.sort((a, b) {
        final byBranch = a.branchName.compareTo(b.branchName);
        return byBranch != 0
            ? byBranch
            : a.userName.toLowerCase().compareTo(b.userName.toLowerCase());
      });
      state = state.copyWith(rows: rows, isLoading: false);
    } catch (e) {
      if (state.month != requested) return;
      state = state.copyWith(
          isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Pichla (-1) ya agla (+1) mahina.
  void shift(int delta) {
    final m = state.month;
    state = state.copyWith(month: DateTime(m.year, m.month + delta, 1));
    load();
  }

  void setBranch(String? branchId) {
    if (branchId == state.branchId) return;
    state = branchId == null
        ? state.copyWith(clearBranch: true)
        : state.copyWith(branchId: branchId);
    load();
  }
}

final employeeSalaryReportProvider = StateNotifierProvider<
    EmployeeSalaryReportNotifier, EmployeeSalaryReportState>(
  (ref) => EmployeeSalaryReportNotifier(
      ref.read(employeeSalaryReportDatasourceProvider)),
);

/// Ek employee ke saare mahine (detail screen).
final employeeSalaryMonthsProvider = FutureProvider.autoDispose
    .family<List<EmployeeSalaryReportRow>, String>(
  (ref, employeeSalaryId) => ref
      .read(employeeSalaryReportDatasourceProvider)
      .fetchEmployeeMonths(employeeSalaryId),
);
