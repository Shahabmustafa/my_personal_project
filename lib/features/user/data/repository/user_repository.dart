import '../../../auth/data/model/user_model.dart';
import '../datasource/user_remote_datasource.dart';

class UserRepository {
  final UserRemoteDatasource remoteDatasource;
  UserRepository({required this.remoteDatasource});

  Future<List<UserModel>> getAllUsers() => remoteDatasource.getAllUsers();

  Future<List<UserModel>> getUsersByBranch(String branchId) =>
      remoteDatasource.getUsersByBranch(branchId);

  Future<List<UserModel>> getUsersByWarehouse(String warehouseId) =>
      remoteDatasource.getUsersByWarehouse(warehouseId);

  Future<UserModel> getUserById(String id) =>
      remoteDatasource.getUserById(id);

  Future<UserModel> createUser({
    required String email,
    required String password,
    required String username,
    required String role,
    String phoneNumber = '',
    List<String> branchIds = const [],
  }) =>
      remoteDatasource.createUser(
        email: email,
        password: password,
        username: username,
        role: role,
        phoneNumber: phoneNumber,
        branchIds: branchIds,
      );

  Future<UserModel> updateUser({
    required String userId,
    String? role,
    bool? isActive,
    String? phoneNumber,
    String? username,
  }) =>
      remoteDatasource.updateUser(
        userId: userId,
        role: role,
        isActive: isActive,
        phoneNumber: phoneNumber,
        username: username,
      );

  Future<void> assignBranchesToUser({
    required String userId,
    required List<String> branchIds,
  }) =>
      remoteDatasource.assignBranchesToUser(
          userId: userId, branchIds: branchIds);

  Future<void> assignWarehousesToUser({
    required String userId,
    required List<String> warehouseIds,
  }) =>
      remoteDatasource.assignWarehousesToUser(
          userId: userId, warehouseIds: warehouseIds);

  Future<void> assignHeadOfficesToUser({
    required String userId,
    required List<String> headOfficeIds,
  }) =>
      remoteDatasource.assignHeadOfficesToUser(
          userId: userId, headOfficeIds: headOfficeIds);
}
