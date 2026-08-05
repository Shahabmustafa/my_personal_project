import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/warehouse_remote_datasource.dart';
import '../../data/model/warehouse_model.dart';
import '../../data/repository/warehouse_repository.dart';
import 'warehouse_state.dart';
import 'package:flutter_riverpod/legacy.dart';

final warehouseRemoteDatasourceProvider =
    Provider<WarehouseRemoteDatasource>((_) => WarehouseRemoteDatasource());

final warehouseRepositoryProvider = Provider<WarehouseRepository>((ref) {
  return WarehouseRepository(remoteDatasource: ref.read(warehouseRemoteDatasourceProvider));
});

class WarehouseNotifier extends StateNotifier<WarehouseState> {
  final WarehouseRepository _repo;
  WarehouseNotifier(this._repo) : super(const WarehouseState());

  Future<void> loadAllWarehouses() async {
    state = state.copyWith(status: WarehouseStatus.loading, errorMessage: null);
    try {
      final warehouses = await _repo.getAllWarehouses();
      state = state.copyWith(status: WarehouseStatus.success, warehouses: warehouses);
    } catch (e) {
      state = state.copyWith(status: WarehouseStatus.error, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadUserWarehouses(List<String> warehouseIds) async {
    state = state.copyWith(status: WarehouseStatus.loading, errorMessage: null);
    try {
      final warehouses = await _repo.getWarehousesForUser(warehouseIds);
      state = state.copyWith(status: WarehouseStatus.success, warehouses: warehouses);
    } catch (e) {
      state = state.copyWith(status: WarehouseStatus.error, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> createWarehouse(WarehouseModel warehouse) async {
    state = state.copyWith(status: WarehouseStatus.loading, errorMessage: null);
    try {
      final created = await _repo.createWarehouse(warehouse);
      state = state.copyWith(status: WarehouseStatus.success, warehouses: [...state.warehouses, created]);
    } catch (e) {
      state = state.copyWith(status: WarehouseStatus.error, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> updateWarehouse(WarehouseModel warehouse) async {
    state = state.copyWith(status: WarehouseStatus.loading, errorMessage: null);
    try {
      final updated = await _repo.updateWarehouse(warehouse);
      final list = state.warehouses.map((w) => w.id == updated.id ? updated : w).toList();
      state = state.copyWith(status: WarehouseStatus.success, warehouses: list);
    } catch (e) {
      state = state.copyWith(status: WarehouseStatus.error, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteWarehouse(String id) async {
    state = state.copyWith(status: WarehouseStatus.loading, errorMessage: null);
    try {
      await _repo.deleteWarehouse(id);
      state = state.copyWith(status: WarehouseStatus.success, warehouses: state.warehouses.where((w) => w.id != id).toList());
    } catch (e) {
      state = state.copyWith(status: WarehouseStatus.error, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final warehouseProvider = StateNotifierProvider<WarehouseNotifier, WarehouseState>((ref) {
  return WarehouseNotifier(ref.read(warehouseRepositoryProvider));
});
