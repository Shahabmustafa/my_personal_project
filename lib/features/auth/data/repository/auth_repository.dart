import '../datasource/auth_local_datasource.dart';
import '../datasource/auth_remote_datasource.dart';
import '../model/user_model.dart';

class AuthRepository {
  final AuthRemoteDatasource remoteDatasource;
  final AuthLocalDatasource localDatasource;

  AuthRepository({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  Future<UserModel> login({required String email, required String password}) async {
    final user = await remoteDatasource.login(email: email, password: password);
    await localDatasource.saveUser(user);
    return user;
  }

  Future<UserModel?> getCurrentUser() => localDatasource.getUser();

  Future<bool> isLoggedIn() => localDatasource.isLoggedIn();

  Future<void> logout() async {
    await remoteDatasource.logout();
    await localDatasource.clearUser();
  }

  Future<UserModel?> refreshUser() async {
    final user = await remoteDatasource.fetchCurrentUser();
    if (user != null) await localDatasource.saveUser(user);
    return user;
  }
}
