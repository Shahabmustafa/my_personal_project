import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/datasource/type_remote_datasource.dart';
import '../../data/model/type_model.dart';
import '../../data/repository/type_repository.dart';
import 'type_state.dart';

final typeRemoteDatasourceProvider =
    Provider<TypeRemoteDatasource>((_) => TypeRemoteDatasource());

final typeRepositoryProvider = Provider<TypeRepository>((ref) {
  return TypeRepository(
      remoteDatasource: ref.read(typeRemoteDatasourceProvider));
});

class TypeNotifier extends StateNotifier<TypeState> {
  final TypeRepository _repo;
  TypeNotifier(this._repo) : super(const TypeState());

  Future<void> loadAll() async {
    state = state.copyWith(status: TypeStatus.loading, errorMessage: null);
    try {
      final items = await _repo.getAll();
      state = state.copyWith(status: TypeStatus.success, items: items);
    } catch (e) {
      state = state.copyWith(
          status: TypeStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> create(TypeModel model) async {
    state = state.copyWith(status: TypeStatus.loading, errorMessage: null);
    try {
      await _repo.create(model);
      final items = await _repo.getAll();
      state = state.copyWith(status: TypeStatus.success, items: items);
    } catch (e) {
      state = state.copyWith(
          status: TypeStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> update(TypeModel model) async {
    state = state.copyWith(status: TypeStatus.loading, errorMessage: null);
    try {
      final updated = await _repo.update(model);
      final list =
          state.items.map((i) => i.id == updated.id ? updated : i).toList();
      state = state.copyWith(status: TypeStatus.success, items: list);
    } catch (e) {
      state = state.copyWith(
          status: TypeStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> delete(String id) async {
    state = state.copyWith(status: TypeStatus.loading, errorMessage: null);
    try {
      await _repo.delete(id);
      final list = state.items.where((i) => i.id != id).toList();
      state = state.copyWith(status: TypeStatus.success, items: list);
    } catch (e) {
      state = state.copyWith(
          status: TypeStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final typeProvider =
    StateNotifierProvider<TypeNotifier, TypeState>((ref) {
  return TypeNotifier(ref.read(typeRepositoryProvider));
});
