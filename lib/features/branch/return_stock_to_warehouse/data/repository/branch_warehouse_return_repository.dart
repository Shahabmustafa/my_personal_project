import '../datasource/branch_warehouse_return_cart_item.dart';
import '../datasource/branch_warehouse_return_datasource.dart';
import '../model/branch_warehouse_return_model.dart';

class BranchWarehouseReturnRepository {
  final BranchWarehouseReturnDatasource _datasource;
  BranchWarehouseReturnRepository(this._datasource);

  Future<String> generateReturnNumber() => _datasource.generateReturnNumber();

  Future<List<WarehouseModel>> getActiveWarehouses() =>
      _datasource.fetchActiveWarehouses();

  Future<void> saveReturn({
    required String branchId,
    required String warehouseId,
    String? returnedBy,
    String? notes,
    required List<BranchWarehouseReturnCartItem> cartItems,
  }) =>
      _datasource.saveReturn(
        branchId: branchId,
        warehouseId: warehouseId,
        returnedBy: returnedBy,
        notes: notes,
        cartItems: cartItems,
      );

  Future<List<BranchWarehouseReturnModel>> getSentReturns(String branchId) =>
      _datasource.fetchSentReturns(branchId);

  Future<List<BranchWarehouseReturnModel>> getIncomingReturns(String warehouseId) =>
      _datasource.fetchIncomingReturns(warehouseId);

  Future<void> acceptReturn(String returnId) => _datasource.acceptReturn(returnId);

  Future<void> rejectReturn(String returnId) => _datasource.rejectReturn(returnId);
}
