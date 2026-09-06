import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:safishoe_app/features/warehouse/stock_inventory/presentation/providers/stock_provider.dart'
    show stockBrandsProvider;
import '../../data/datasource/brand_remote_datasource.dart';
import '../../data/model/brand_model.dart';
import '../../data/repository/brand_repository.dart';
import 'brand_state.dart';

final brandRemoteDatasourceProvider =
    Provider<BrandRemoteDatasource>((_) => BrandRemoteDatasource());

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  return BrandRepository(
      remoteDatasource: ref.read(brandRemoteDatasourceProvider));
});

class BrandNotifier extends StateNotifier<BrandState> {
  final BrandRepository _repo;
  final Ref _ref;
  BrandNotifier(this._repo, this._ref) : super(const BrandState());

  /// Stock dialogs cache the brand lookup in a plain [FutureProvider]; bust it
  /// after any write so new brands show in their dropdowns without a page reload.
  void _invalidateLookups() => _ref.invalidate(stockBrandsProvider);

  Future<void> loadAll() async {
    state = state.copyWith(status: BrandStatus.loading, errorMessage: null);
    try {
      final items = await _repo.getAll();
      state = state.copyWith(status: BrandStatus.success, items: items);
    } catch (e) {
      state = state.copyWith(
          status: BrandStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> create(BrandModel model) async {
    state = state.copyWith(status: BrandStatus.loading, errorMessage: null);
    try {
      await _repo.create(model);
      final items = await _repo.getAll();
      state = state.copyWith(status: BrandStatus.success, items: items);
      _invalidateLookups();
    } catch (e) {
      state = state.copyWith(
          status: BrandStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> update(BrandModel model) async {
    state = state.copyWith(status: BrandStatus.loading, errorMessage: null);
    try {
      final updated = await _repo.update(model);
      final list =
          state.items.map((i) => i.id == updated.id ? updated : i).toList();
      state = state.copyWith(status: BrandStatus.success, items: list);
      _invalidateLookups();
    } catch (e) {
      state = state.copyWith(
          status: BrandStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> delete(String id) async {
    state = state.copyWith(status: BrandStatus.loading, errorMessage: null);
    try {
      await _repo.delete(id);
      final list = state.items.where((i) => i.id != id).toList();
      state = state.copyWith(status: BrandStatus.success, items: list);
      _invalidateLookups();
    } catch (e) {
      state = state.copyWith(
          status: BrandStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final brandProvider =
    StateNotifierProvider<BrandNotifier, BrandState>((ref) {
  return BrandNotifier(ref.read(brandRepositoryProvider), ref);
});
