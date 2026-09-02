import '../../../head_office_purchase/data/models/warehouse_stock_model.dart';
import '../datasources/ho_assign_stock_datasource.dart';
import '../models/ho_assign_stock_model.dart';

class HoAssignStockRepository {
  final HoAssignStockDatasource _datasource;

  HoAssignStockRepository(this._datasource);

  Future<String> generateAssignmentNumber() =>
      _datasource.generateAssignmentNumber();

  Future<List<HoBranchModel>> getBranches() => _datasource.fetchBranches();

  Future<List<WarehouseStockModel>> getHeadOfficeStock() =>
      _datasource.fetchHeadOfficeStock();

  Future<HoAssignStockModel> saveAssignment({
    required String assignmentNumber,
    required String headOfficeId,
    required String branchId,
    required List<HoAssignCartItem> cartItems,
    String? notes,
  }) =>
      _datasource.saveAssignment(
        assignmentNumber: assignmentNumber,
        headOfficeId: headOfficeId,
        branchId: branchId,
        cartItems: cartItems,
        notes: notes,
      );

  Future<List<HoAssignStockModel>> getAssignments(String headOfficeId) =>
      _datasource.fetchAssignments(headOfficeId);

  Future<HoAssignStockModel> getAssignmentDetail(String assignmentId) =>
      _datasource.fetchAssignmentDetail(assignmentId);

  Future<void> acceptAssignment(String assignmentId) =>
      _datasource.acceptAssignment(assignmentId);

  Future<void> rejectAssignment(String assignmentId) =>
      _datasource.rejectAssignment(assignmentId);
}
