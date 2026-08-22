import '../../../../warehouse/assign_stock_to_branch/data/models/assign_stock_model.dart';
import '../datasoruce/branch_assign_datasource.dart';

class BranchAssignRepository {
  final BranchAssignDatasource _datasource;

  BranchAssignRepository(this._datasource);

  Future<List<AssignStockModel>> getBranchAssignments(String branchId) =>
      _datasource.fetchBranchAssignments(branchId);

  Future<AssignStockModel> getAssignmentDetail(String assignmentId) =>
      _datasource.fetchAssignmentDetail(assignmentId);

  Future<void> acceptAssignment(String assignmentId) =>
      _datasource.acceptAssignment(assignmentId);

  Future<void> rejectAssignment(String assignmentId) =>
      _datasource.rejectAssignment(assignmentId);
}
