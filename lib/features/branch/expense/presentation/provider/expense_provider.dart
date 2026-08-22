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

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final ExpenseRepository _repo;
  final String _branchId;

  ExpenseNotifier(this._repo, this._branchId) : super(const ExpenseState()) {
    if (_branchId.isNotEmpty) load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repo.getEntriesByBranch(_branchId),
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
        error: e.toString().replaceAll('Exception: ', ''),
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
      final message = e.toString().replaceAll('Exception: ', '');
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
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> deleteExpense(String id) async {
    try {
      await _repo.deleteEntry(id);
      await load();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>(
  (ref) => ExpenseNotifier(
    ref.read(expenseRepositoryProvider),
    ref.watch(currentBranchIdProvider),
  ),
);
