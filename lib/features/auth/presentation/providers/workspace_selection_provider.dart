import 'package:flutter_riverpod/legacy.dart';
import 'auth_provider.dart';

/// Jo branch/warehouse user login ke baad select karta hai wo yahan
/// persist hota hai (SharedPreferences ke zariye), taake app restart ya
/// kisi bhi screen par wahi id dobara mil sake.
class SelectedLocationNotifier extends StateNotifier<String> {
  final Future<String> Function() _read;
  final Future<void> Function(String) _write;

  SelectedLocationNotifier(this._read, this._write) : super('') {
    _restore();
  }

  Future<void> _restore() async {
    final saved = await _read();
    if (saved.isNotEmpty) state = saved;
  }

  Future<void> select(String id) async {
    state = id;
    await _write(id);
  }

  void clear() => state = '';
}

final selectedBranchIdProvider =
    StateNotifierProvider<SelectedLocationNotifier, String>((ref) {
  final local = ref.read(authLocalDatasourceProvider);
  return SelectedLocationNotifier(
    local.getSelectedBranchId,
    local.saveSelectedBranchId,
  );
});

final selectedWarehouseIdProvider =
    StateNotifierProvider<SelectedLocationNotifier, String>((ref) {
  final local = ref.read(authLocalDatasourceProvider);
  return SelectedLocationNotifier(
    local.getSelectedWarehouseId,
    local.saveSelectedWarehouseId,
  );
});
