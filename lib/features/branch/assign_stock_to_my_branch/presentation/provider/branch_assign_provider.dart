import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/current_branch_provider.dart';
import '../../../../warehouse/assign_stock_to_branch/data/models/assign_stock_model.dart';
import '../../data/datasoruce/branch_assign_datasource.dart';
import '../../data/repossitory/branch_assign_repository.dart';

// ── Infrastructure ────────────────────────────────────────────────────────
final branchAssignDatasourceProvider = Provider<BranchAssignDatasource>(
  (ref) => BranchAssignDatasource(Supabase.instance.client),
);

final branchAssignRepositoryProvider = Provider<BranchAssignRepository>(
  (ref) => BranchAssignRepository(ref.read(branchAssignDatasourceProvider)),
);

// ── Branch Assignment List State ──────────────────────────────────────────

class BranchAssignListState {
  final List<AssignStockModel> assignments;
  final bool isLoading;
  final String? error;

  const BranchAssignListState({
    this.assignments = const [],
    this.isLoading = false,
    this.error,
  });

  BranchAssignListState copyWith({
    List<AssignStockModel>? assignments,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      BranchAssignListState(
        assignments: assignments ?? this.assignments,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class BranchAssignNotifier extends StateNotifier<BranchAssignListState> {
  final BranchAssignRepository _repo;
  final String _branchId;

  BranchAssignNotifier(this._repo, this._branchId)
      : super(const BranchAssignListState()) {
    loadAssignments();
  }

  Future<void> loadAssignments() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getBranchAssignments(_branchId);
      state = state.copyWith(assignments: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Accept — branch inventory mein stock add ──────────────────────────
  Future<String?> acceptAssignment(String assignmentId) async {
    try {
      await _repo.acceptAssignment(assignmentId);
      await loadAssignments();
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return e.toString();
    }
  }

  // ── Reject — warehouse mein stock wapas ──────────────────────────────
  Future<String?> rejectAssignment(String assignmentId) async {
    try {
      await _repo.rejectAssignment(assignmentId);
      await loadAssignments();
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return e.toString();
    }
  }

  // ── Detail load ───────────────────────────────────────────────────────
  Future<AssignStockModel?> loadDetail(String assignmentId) async {
    try {
      return await _repo.getAssignmentDetail(assignmentId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

final branchAssignProvider = StateNotifierProvider<BranchAssignNotifier, BranchAssignListState>(
  (ref) => BranchAssignNotifier(
    ref.read(branchAssignRepositoryProvider),
    ref.watch(currentBranchIdProvider),
  ),
);
