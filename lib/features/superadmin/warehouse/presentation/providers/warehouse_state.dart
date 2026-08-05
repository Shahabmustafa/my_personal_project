import '../../data/model/warehouse_model.dart';

enum WarehouseStatus { initial, loading, success, error }

class WarehouseState {
  final WarehouseStatus status;
  final List<WarehouseModel> warehouses;
  final String? errorMessage;

  const WarehouseState({
    this.status = WarehouseStatus.initial,
    this.warehouses = const [],
    this.errorMessage,
  });

  WarehouseState copyWith({
    WarehouseStatus? status,
    List<WarehouseModel>? warehouses,
    String? errorMessage,
  }) {
    return WarehouseState(
      status: status ?? this.status,
      warehouses: warehouses ?? this.warehouses,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == WarehouseStatus.loading;
}
