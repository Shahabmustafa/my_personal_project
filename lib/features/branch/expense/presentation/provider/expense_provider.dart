import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/current_branch_provider.dart';
import '../../data/datasource/expense_datasource.dart';
import '../../data/model/expense_entry_model.dart';
import '../../data/model/expense_head_model.dart';
import '../../data/repository/expense_repository.dart';

// ── Infrastructure ────────────────────────────────────────────────────────

final expenseDatasourceProvider = Provider<ExpenseDatasource>(
  (ref) => ExpenseDatasource(Supabase.instance.client),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(ref.read(expenseDatasourceProvider)),
);

// ── State ──────────────────────────────────────────────────────────────────

class ExpenseState {
  final List<ExpenseEntryModel> entries;
  final List<ExpenseHeadModel> heads;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const ExpenseState({
    this.entries = const [],
    this.heads = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  double get totalExpense => entries.fold(0, (s, e) => s + e.amount);

  ExpenseState copyWith({
    List<ExpenseEntryModel>? entries,
    List<ExpenseHeadModel>? heads,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) =>
      ExpenseState(
        entries: entries ?? this.entries,
        heads: heads ?? this.heads,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : error ?? this.error,
      );
}

/// Kis ka expense — ek branch ka (`expense_entries`) ya head office ka apna
/// (`head_office_expenses`). Superadmin dono choose kar sakta hai.
class ExpenseScope {
  final String id;
  final bool isHeadOffice;

  /// Superadmin ka "All Branches" view — saari branches ki entries.
  final bool isAllBranches;
  const ExpenseScope.branch(this.id)
      : isHeadOffice = false,
        isAllBranches = false;
  const ExpenseScope.headOffice(this.id)
      : isHeadOffice = true,
        isAllBranches = false;
  const ExpenseScope.allBranches()
      : id = '',
        isHeadOffice = false,
        isAllBranches = true;

  @override
  bool operator ==(Object other) =>
      other is ExpenseScope &&
      other.id == id &&
      other.isHeadOffice == isHeadOffice &&
      other.isAllBranches == isAllBranches;

  @override
  int get hashCode => Object.hash(id, isHeadOffice, isAllBranches);
}

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final ExpenseRepository _repo;
  final ExpenseScope _scope;

  ExpenseNotifier(this._repo, this._scope) : super(const ExpenseState()) {
    if (_scope.id.isNotEmpty || _scope.isAllBranches) load();
  }

  String get _branchId => _scope.id;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _scope.isAllBranches
            ? _repo.getAllBranchEntries()
            : _scope.isHeadOffice
            ? _repo.getEntriesByHeadOffice(_scope.id)
            : _repo.getEntriesByBranch(_branchId),
        _repo.getHeads(),
      ]);
      state = state.copyWith(
        isLoading: false,
        entries: results[0] as List<ExpenseEntryModel>,
        heads: results[1] as List<ExpenseHeadModel>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst(RegExp(r'^Exception: '), ''),
      );
    }
  }

  Future<String?> addExpense({
    required String expenseHeadId,
    required double amount,
    String? note,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      if (_scope.isHeadOffice) {
        await _repo.addHeadOfficeEntry(
          headOfficeId: _scope.id,
          expenseHeadId: expenseHeadId,
          amount: amount,
          note: note,
        );
        await load();
        state = state.copyWith(isSaving: false);
        return null;
      }
      final counterId = await _repo.getTodaysCashCounterId(_branchId);
      if (counterId == null) {
        state = state.copyWith(isSaving: false);
        return "Today's cash counter not found for this branch yet.";
      }
      await _repo.addEntry(
        branchId: _branchId,
        branchCashCounterId: counterId,
        expenseHeadId: expenseHeadId,
        amount: amount,
        note: note,
      );
      await load();
      state = state.copyWith(isSaving: false);
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      state = state.copyWith(isSaving: false, error: message);
      return message;
    }
  }

  Future<String?> updateExpense({
    required ExpenseEntryModel entry,
    required String expenseHeadId,
    required double amount,
    String? note,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      if (_scope.isHeadOffice) {
        await _repo.updateHeadOfficeEntry(
          entry: entry,
          expenseHeadId: expenseHeadId,
          amount: amount,
          note: note,
        );
      } else {
        await _repo.updateEntry(
          id: entry.id,
          expenseHeadId: expenseHeadId,
          amount: amount,
          note: note,
        );
      }
      await load();
      state = state.copyWith(isSaving: false);
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      state = state.copyWith(isSaving: false, error: message);
      return message;
    }
  }

  Future<String?> addHead({required String name, String? description}) async {
    try {
      final head = await _repo.addHead(name: name, description: description);
      state = state.copyWith(heads: [...state.heads, head]);
      return null;
    } catch (e) {
      return e.toString().replaceFirst(RegExp(r'^Exception: '), '');
    }
  }

  Future<String?> deleteExpense(ExpenseEntryModel entry) async {
    try {
      if (_scope.isHeadOffice) {
        await _repo.deleteHeadOfficeEntry(entry);
      } else {
        await _repo.deleteEntry(entry.id);
      }
      await load();
      return null;
    } catch (e) {
      return e.toString().replaceFirst(RegExp(r'^Exception: '), '');
    }
  }
}

final expenseProvider = StateNotifierProvider.family<ExpenseNotifier,
    ExpenseState, ExpenseScope>(
  (ref, scope) => ExpenseNotifier(ref.read(expenseRepositoryProvider), scope),
);

/// Branch user ka apna scope (logged-in branch).
final currentBranchExpenseScopeProvider = Provider<ExpenseScope>(
  (ref) => ExpenseScope.branch(ref.watch(currentBranchIdProvider)),
);
