import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/datasource/user_remote_datasource.dart';
import '../../data/repository/user_repository.dart';
import 'user_state.dart';

final userRemoteDatasourceProvider =
    Provider<UserRemoteDatasource>((_) => UserRemoteDatasource());

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(
      remoteDatasource: ref.read(userRemoteDatasourceProvider));
});

class UserNotifier extends StateNotifier<UserState> {
  final UserRepository _repo;
  UserNotifier(this._repo) : super(const UserState());

  Future<void> loadAllUsers() async {
    state = state.copyWith(status: UserStatus.loading, errorMessage: null);
    try {
      final users = await _repo.getAllUsers();
      state = state.copyWith(status: UserStatus.success, users: users);
    } catch (e) {
      state = state.copyWith(
          status: UserStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadUsersByBranch(String branchId) async {
    state = state.copyWith(status: UserStatus.loading, errorMessage: null);
    try {
      final users = await _repo.getUsersByBranch(branchId);
      state = state.copyWith(status: UserStatus.success, users: users);
    } catch (e) {
      state = state.copyWith(
          status: UserStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Create user — branchIds auto assign (current user ki branches)
  Future<bool> createUser({
    required String email,
    required String password,
    required String username,
    required String role,
    String phoneNumber = '',
    List<String> branchIds = const [],
  }) async {
    state = state.copyWith(status: UserStatus.loading, errorMessage: null);
    try {
      final created = await _repo.createUser(
        email: email,
        password: password,
        username: username,
        role: role,
        phoneNumber: phoneNumber,
        branchIds: branchIds,
      );
      state = state.copyWith(
        status: UserStatus.success,
        users: [created, ...state.users],
      );
      return true;
    } catch (e) {
      state = state.copyWith(
          status: UserStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    state = state.copyWith(status: UserStatus.loading, errorMessage: null);
    try {
      final updated = await _repo.updateUser(userId: userId, role: role);
      final list =
          state.users.map((u) => u.id == updated.id ? updated : u).toList();
      state = state.copyWith(status: UserStatus.success, users: list);
    } catch (e) {
      state = state.copyWith(
          status: UserStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> toggleUserActive({
    required String userId,
    required bool isActive,
  }) async {
    state = state.copyWith(status: UserStatus.loading, errorMessage: null);
    try {
      final updated =
          await _repo.updateUser(userId: userId, isActive: isActive);
      final list =
          state.users.map((u) => u.id == updated.id ? updated : u).toList();
      state = state.copyWith(status: UserStatus.success, users: list);
    } catch (e) {
      state = state.copyWith(
          status: UserStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> assignBranchesToUser({
    required String userId,
    required List<String> branchIds,
  }) async {
    try {
      await _repo.assignBranchesToUser(userId: userId, branchIds: branchIds);
      final updated = await _repo.getUserById(userId);
      final list =
          state.users.map((u) => u.id == updated.id ? updated : u).toList();
      state = state.copyWith(users: list);
    } catch (e) {
      state = state.copyWith(
          status: UserStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> assignWarehousesToUser({
    required String userId,
    required List<String> warehouseIds,
  }) async {
    try {
      await _repo.assignWarehousesToUser(
          userId: userId, warehouseIds: warehouseIds);
      final updated = await _repo.getUserById(userId);
      final list =
          state.users.map((u) => u.id == updated.id ? updated : u).toList();
      state = state.copyWith(users: list);
    } catch (e) {
      state = state.copyWith(
          status: UserStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final userProvider =
    StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref.read(userRepositoryProvider));
});
