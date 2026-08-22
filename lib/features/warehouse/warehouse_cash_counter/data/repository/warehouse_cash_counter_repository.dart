import '../datasource/warehouse_cash_counter_remote_datasource.dart';
import '../model/warehouse_cash_counter_model.dart';

class WarehouseCashCounterRepository {
  final WarehouseCashCounterRemoteDatasource remoteDatasource;
  WarehouseCashCounterRepository({required this.remoteDatasource});

  Future<List<WarehouseCashCounterModel>> getByWarehouse(
          String warehouseId) =>
      remoteDatasource.getByWarehouse(warehouseId);

  Future<WarehouseCashCounterModel?> getByDate(
          String warehouseId, DateTime date) =>
      remoteDatasource.getByDate(warehouseId, date);

  Future<WarehouseCashCounterModel> create(
          WarehouseCashCounterModel record) =>
      remoteDatasource.create(record);

  Future<WarehouseCashCounterModel> update(
          WarehouseCashCounterModel record) =>
      remoteDatasource.update(record);

  Future<void> delete(String id) => remoteDatasource.delete(id);
}
