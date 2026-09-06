import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:safishoe_app/features/warehouse/stock_inventory/presentation/providers/stock_provider.dart'
    show stockColorsProvider;
import '../../data/datasource/color_remote_datasource.dart';
import '../../data/model/color_model.dart';
import '../../data/repository/color_repository.dart';
import 'color_state.dart';

final colorRemoteDatasourceProvider =
    Provider<ColorRemoteDatasource>((_) => ColorRemoteDatasource());

final colorRepositoryProvider = Provider<ColorRepository>((ref) {
  return ColorRepository(
      remoteDatasource: ref.read(colorRemoteDatasourceProvider));
});

class ColorNotifier extends StateNotifier<ColorState> {
  final ColorRepository _repo;
  final Ref _ref;
  ColorNotifier(this._repo, this._ref) : super(const ColorState());

  /// Stock dialogs cache the color lookup in a plain [FutureProvider]; bust it
  /// after any write so new colors show in their dropdowns without a page reload.
  void _invalidateLookups() => _ref.invalidate(stockColorsProvider);

  Future<void> loadAll() async {
    state = state.copyWith(status: ColorStatus.loading, errorMessage: null);
    try {
      final items = await _repo.getAll();
      state = state.copyWith(status: ColorStatus.success, items: items);
    } catch (e) {
      state = state.copyWith(
          status: ColorStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> create(ColorModel model) async {
    state = state.copyWith(status: ColorStatus.loading, errorMessage: null);
    try {
      await _repo.create(model);
      final items = await _repo.getAll();
      state = state.copyWith(status: ColorStatus.success, items: items);
      _invalidateLookups();
    } catch (e) {
      state = state.copyWith(
          status: ColorStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> update(ColorModel model) async {
    state = state.copyWith(status: ColorStatus.loading, errorMessage: null);
    try {
      final updated = await _repo.update(model);
      final list =
          state.items.map((i) => i.id == updated.id ? updated : i).toList();
      state = state.copyWith(status: ColorStatus.success, items: list);
      _invalidateLookups();
    } catch (e) {
      state = state.copyWith(
          status: ColorStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> delete(String id) async {
    state = state.copyWith(status: ColorStatus.loading, errorMessage: null);
    try {
      await _repo.delete(id);
      final list = state.items.where((i) => i.id != id).toList();
      state = state.copyWith(status: ColorStatus.success, items: list);
      _invalidateLookups();
    } catch (e) {
      state = state.copyWith(
          status: ColorStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final colorProvider =
    StateNotifierProvider<ColorNotifier, ColorState>((ref) {
  return ColorNotifier(ref.read(colorRepositoryProvider), ref);
});
