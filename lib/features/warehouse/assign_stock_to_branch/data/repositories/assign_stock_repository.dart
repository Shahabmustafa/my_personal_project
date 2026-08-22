import '../../../purchase_invoice/data/models/warehouse_stock_model.dart';
import '../datasources/assign_stock_datasource.dart';
import '../models/assign_stock_model.dart';

class AssignStockRepository {
  final AssignStockDatasource _datasource;

  AssignStockRepository(this._datasource);

  Future<String> generateAssignmentNumber() =>
      _datasource.generateAssignmentNumber();

  Future<List<BranchModel>> getBranches() => _datasource.fetchBranches();

  Future<List<WarehouseStockModel>> getWarehouseStock(String warehouseId) =>
      _datasource.fetchWarehouseStock(warehouseId);

  Future<AssignStockModel> saveAssignment({
    required String assignmentNumber,
    required String warehouseId,
    required String branchId,
    required List<AssignCartItem> cartItems,
    String? notes,
  }) =>
      _datasource.saveAssignment(
        assignmentNumber: assignmentNumber,
        warehouseId: warehouseId,
        branchId: branchId,
        cartItems: cartItems,
        notes: notes,
      );

  Future<List<AssignStockModel>> getAssignments(String warehouseId) =>
      _datasource.fetchAssignments(warehouseId);

  Future<AssignStockModel> getAssignmentDetail(String assignmentId) =>
      _datasource.fetchAssignmentDetail(assignmentId);

  Future<void> acceptAssignment(String assignmentId) =>
      _datasource.acceptAssignment(assignmentId);

  Future<void> rejectAssignment(String assignmentId) =>
      _datasource.rejectAssignment(assignmentId);
}
