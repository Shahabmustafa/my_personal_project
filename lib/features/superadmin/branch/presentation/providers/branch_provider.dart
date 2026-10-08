import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/branch_remote_datasource.dart';
import '../../data/model/branch_model.dart';
import '../../data/repository/branch_repository.dart';
import 'branch_state.dart';
import 'package:flutter_riverpod/legacy.dart';


final branchRemoteDatasourceProvider =
    Provider<BranchRemoteDatasource>((_) => BranchRemoteDatasource());

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  return BranchRepository(remoteDatasource: ref.read(branchRemoteDatasourceProvider));
});

class BranchNotifier extends StateNotifier<BranchState> {
  final BranchRepository _repo;
  BranchNotifier(this._repo) : super(const BranchState());

  Future<void> loadAllBranches() async {
    state = state.copyWith(status: BranchStatus.loading, errorMessage: null);
    try {
      final branches = await _repo.getAllBranches();
      state = state.copyWith(status: BranchStatus.success, branches: branches);
    } catch (e) {
      state = state.copyWith(status: BranchStatus.error, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadUserBranches(List<String> branchIds) async {
    state = state.copyWith(status: BranchStatus.loading, errorMessage: null);
    try {
      final branches = await _repo.getBranchesForUser(branchIds);
      state = state.copyWith(status: BranchStatus.success, branches: branches);
    } catch (e) {
      state = state.copyWith(status: BranchStatus.error, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> createBranch(BranchModel branch) async {
    state = state.copyWith(status: BranchStatus.loading, errorMessage: null);
    try {
      final created = await _repo.createBranch(branch);
      state = state.copyWith(status: BranchStatus.success, branches: [...state.branches, created]);
    } catch (e) {
      state = state.copyWith(status: BranchStatus.error, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> updateBranch(BranchModel branch) async {
    state = state.copyWith(status: BranchStatus.loading, errorMessage: null);
    try {
      final updated = await _repo.updateBranch(branch);
      final list = state.branches.map((b) => b.id == updated.id ? updated : b).toList();
      state = state.copyWith(status: BranchStatus.success, branches: list);
    } catch (e) {
      state = state.copyWith(status: BranchStatus.error, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteBranch(String id) async {
    state = state.copyWith(status: BranchStatus.loading, errorMessage: null);
    try {
      await _repo.deleteBranch(id);
      state = state.copyWith(status: BranchStatus.success, branches: state.branches.where((b) => b.id != id).toList());
    } catch (e) {
      state = state.copyWith(status: BranchStatus.error, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final branchProvider = StateNotifierProvider<BranchNotifier, BranchState>((ref) {
  return BranchNotifier(ref.read(branchRepositoryProvider));
});
