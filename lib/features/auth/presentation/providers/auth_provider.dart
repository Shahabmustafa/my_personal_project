import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/auth_local_datasource.dart';
import '../../data/datasource/auth_remote_datasource.dart';
import '../../data/repository/auth_repository.dart';
import '../../data/model/user_model.dart';
import 'auth_state.dart';
import 'workspace_selection_provider.dart';
import 'package:flutter_riverpod/legacy.dart';


final authLocalDatasourceProvider = Provider<AuthLocalDatasource>((_) => AuthLocalDatasource());
final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((_) => AuthRemoteDatasource());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    remoteDatasource: ref.read(authRemoteDatasourceProvider),
    localDatasource: ref.read(authLocalDatasourceProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier(this._repo, this._ref) : super(const AuthState()) {
    _loadSavedUser();
  }

  Future<void> _loadSavedUser() async {
    UserModel? user;
    try {
      user = await _repo.getCurrentUser();
    } catch (_) {
      user = null;
    }
    if (!mounted) return;
    // initialized foran true — splash ab dashboard/login par ja sakta hai;
    // server se re-verify peeche chalta rehta hai.
    state = user != null
        ? state.copyWith(
            status: AuthStatus.success,
            user: user,
            initialized: true,
          )
        // errorMessage mat mitao (login restore se pehle fail ho chuka ho sakta hai).
        : AuthState(
            status: state.status,
            user: state.user,
            errorMessage: state.errorMessage,
            initialized: true,
          );
    if (user != null) {
      // Role/branches local storage se aaye hain (badle ja sakte hain) —
      // server se dobara verify karo. Offline ho to saved user chalta rehta hai.
      try {
        await refreshUser();
      } catch (_) {}
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repo.login(email: email, password: password);
      state = state.copyWith(status: AuthStatus.success, user: user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst(RegExp(r'^Exception: '), ''),
      );
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _ref.read(selectedBranchIdProvider.notifier).clear();
    _ref.read(selectedWarehouseIdProvider.notifier).clear();
    state = const AuthState(initialized: true);
  }

  Future<void> refreshUser() async {
    final user = await _repo.refreshUser();
    if (user != null) state = state.copyWith(user: user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider), ref);
});
