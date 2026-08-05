import '../datasource/branch_remote_datasource.dart';
import '../model/branch_model.dart';

class BranchRepository {
  final BranchRemoteDatasource remoteDatasource;
  BranchRepository({required this.remoteDatasource});

  Future<List<BranchModel>> getAllBranches() => remoteDatasource.getAllBranches();
  Future<List<BranchModel>> getBranchesForUser(List<String> ids) => remoteDatasource.getBranchesForUser(ids);
  Future<BranchModel> getBranchById(String id) => remoteDatasource.getBranchById(id);
  Future<BranchModel> createBranch(BranchModel b) => remoteDatasource.createBranch(b);
  Future<BranchModel> updateBranch(BranchModel b) => remoteDatasource.updateBranch(b);
  Future<void> deleteBranch(String id) => remoteDatasource.deleteBranch(id);
  Future<void> assignUserToBranch({required String userId, required String branchId}) =>
      remoteDatasource.assignUserToBranch(userId: userId, branchId: branchId);
  Future<void> removeUserFromBranch({required String userId, required String branchId}) =>
      remoteDatasource.removeUserFromBranch(userId: userId, branchId: branchId);
}
