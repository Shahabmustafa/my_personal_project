import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/auth_local_datasource.dart';
import '../../data/datasource/auth_remote_datasource.dart';
import '../../data/repository/auth_repository.dart';
import 'auth_state.dart';
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

  AuthNotifier(this._repo) : super(const AuthState()) {
    _loadSavedUser();
  }

  Future<void> _loadSavedUser() async {
    final user = await _repo.getCurrentUser();
    if (user != null) {
      state = state.copyWith(status: AuthStatus.success, user: user);
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
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  Future<void> refreshUser() async {
    final user = await _repo.refreshUser();
    if (user != null) state = state.copyWith(user: user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
