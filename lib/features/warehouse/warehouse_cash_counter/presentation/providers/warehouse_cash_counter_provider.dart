import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/datasource/warehouse_cash_counter_remote_datasource.dart';
import '../../data/model/warehouse_cash_counter_model.dart';
import '../../data/repository/warehouse_cash_counter_repository.dart';
import 'warehouse_cash_counter_state.dart';

final cashCounterRemoteDatasourceProvider =
    Provider<WarehouseCashCounterRemoteDatasource>(
        (_) => WarehouseCashCounterRemoteDatasource());

final cashCounterRepositoryProvider =
    Provider<WarehouseCashCounterRepository>((ref) {
  return WarehouseCashCounterRepository(
      remoteDatasource: ref.read(cashCounterRemoteDatasourceProvider));
});

class WarehouseCashCounterNotifier
    extends StateNotifier<WarehouseCashCounterState> {
  final WarehouseCashCounterRepository _repo;
  WarehouseCashCounterNotifier(this._repo)
      : super(const WarehouseCashCounterState());

  Future<void> loadByWarehouse(String warehouseId) async {
    state = state.copyWith(
        status: CashCounterStatus.loading, errorMessage: null);
    try {
      final records = await _repo.getByWarehouse(warehouseId);
      state = state.copyWith(
          status: CashCounterStatus.success, records: records);
    } catch (e) {
      state = state.copyWith(
          status: CashCounterStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> createRecord(WarehouseCashCounterModel record) async {
    state = state.copyWith(
        status: CashCounterStatus.loading, errorMessage: null);
    try {
      final created = await _repo.create(record);
      final list = [created, ...state.records];
      // Re-sort by date descending
      list.sort((a, b) => b.counterDate.compareTo(a.counterDate));
      state =
          state.copyWith(status: CashCounterStatus.success, records: list);
    } catch (e) {
      state = state.copyWith(
          status: CashCounterStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> updateRecord(WarehouseCashCounterModel record) async {
    state = state.copyWith(
        status: CashCounterStatus.loading, errorMessage: null);
    try {
      final updated = await _repo.update(record);
      final list = state.records
          .map((r) => r.id == updated.id ? updated : r)
          .toList();
      list.sort((a, b) => b.counterDate.compareTo(a.counterDate));
      state =
          state.copyWith(status: CashCounterStatus.success, records: list);
    } catch (e) {
      state = state.copyWith(
          status: CashCounterStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteRecord(String id) async {
    state = state.copyWith(
        status: CashCounterStatus.loading, errorMessage: null);
    try {
      await _repo.delete(id);
      final list = state.records.where((r) => r.id != id).toList();
      state =
          state.copyWith(status: CashCounterStatus.success, records: list);
    } catch (e) {
      state = state.copyWith(
          status: CashCounterStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final cashCounterProvider = StateNotifierProvider<
    WarehouseCashCounterNotifier, WarehouseCashCounterState>((ref) {
  return WarehouseCashCounterNotifier(ref.read(cashCounterRepositoryProvider));
});
