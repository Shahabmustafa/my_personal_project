import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:safishoe_app/features/warehouse/stock_inventory/presentation/providers/stock_provider.dart'
    show stockCategoriesProvider;
import '../../data/datasource/category_remote_datasource.dart';
import '../../data/model/category_model.dart';
import '../../data/repository/category_repository.dart';
import 'category_state.dart';

final categoryRemoteDatasourceProvider =
    Provider<CategoryRemoteDatasource>((_) => CategoryRemoteDatasource());

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
      remoteDatasource: ref.read(categoryRemoteDatasourceProvider));
});

class CategoryNotifier extends StateNotifier<CategoryState> {
  final CategoryRepository _repo;
  final Ref _ref;
  CategoryNotifier(this._repo, this._ref) : super(const CategoryState());

  /// Stock dialogs cache the category lookup in a plain [FutureProvider]; bust
  /// it after any write so new categories show in their dropdowns without a
  /// page reload.
  void _invalidateLookups() => _ref.invalidate(stockCategoriesProvider);

  Future<void> loadAll() async {
    state = state.copyWith(status: CategoryStatus.loading, errorMessage: null);
    try {
      final items = await _repo.getAll();
      state = state.copyWith(status: CategoryStatus.success, items: items);
    } catch (e) {
      state = state.copyWith(
          status: CategoryStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> create(CategoryModel model) async {
    state = state.copyWith(status: CategoryStatus.loading, errorMessage: null);
    try {
      await _repo.create(model);
      final items = await _repo.getAll();
      state = state.copyWith(status: CategoryStatus.success, items: items);
      _invalidateLookups();
    } catch (e) {
      state = state.copyWith(
          status: CategoryStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> update(CategoryModel model) async {
    state = state.copyWith(status: CategoryStatus.loading, errorMessage: null);
    try {
      final updated = await _repo.update(model);
      final list =
          state.items.map((i) => i.id == updated.id ? updated : i).toList();
      state = state.copyWith(status: CategoryStatus.success, items: list);
      _invalidateLookups();
    } catch (e) {
      state = state.copyWith(
          status: CategoryStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> delete(String id) async {
    state = state.copyWith(status: CategoryStatus.loading, errorMessage: null);
    try {
      await _repo.delete(id);
      final list = state.items.where((i) => i.id != id).toList();
      state = state.copyWith(status: CategoryStatus.success, items: list);
      _invalidateLookups();
    } catch (e) {
      state = state.copyWith(
          status: CategoryStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final categoryProvider =
    StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier(ref.read(categoryRepositoryProvider), ref);
});
