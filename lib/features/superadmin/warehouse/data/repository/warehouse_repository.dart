import '../datasource/warehouse_remote_datasource.dart';
import '../model/warehouse_model.dart';

class WarehouseRepository {
  final WarehouseRemoteDatasource remoteDatasource;
  WarehouseRepository({required this.remoteDatasource});

  Future<List<WarehouseModel>> getAllWarehouses() => remoteDatasource.getAllWarehouses();
  Future<List<WarehouseModel>> getWarehousesForUser(List<String> ids) => remoteDatasource.getWarehousesForUser(ids);
  Future<WarehouseModel> getWarehouseById(String id) => remoteDatasource.getWarehouseById(id);
  Future<WarehouseModel> createWarehouse(WarehouseModel w) => remoteDatasource.createWarehouse(w);
  Future<WarehouseModel> updateWarehouse(WarehouseModel w) => remoteDatasource.updateWarehouse(w);
  Future<void> deleteWarehouse(String id) => remoteDatasource.deleteWarehouse(id);
  Future<void> assignUserToWarehouse({required String userId, required String warehouseId}) =>
      remoteDatasource.assignUserToWarehouse(userId: userId, warehouseId: warehouseId);
  Future<void> removeUserFromWarehouse({required String userId, required String warehouseId}) =>
      remoteDatasource.removeUserFromWarehouse(userId: userId, warehouseId: warehouseId);
}
