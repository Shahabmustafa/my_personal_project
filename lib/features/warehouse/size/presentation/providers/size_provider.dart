import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/datasource/size_remote_datasource.dart';
import '../../data/model/size_model.dart';
import '../../data/repository/size_repository.dart';
import 'size_state.dart';

final sizeRemoteDatasourceProvider =
    Provider<SizeRemoteDatasource>((_) => SizeRemoteDatasource());

final sizeRepositoryProvider = Provider<SizeRepository>((ref) {
  return SizeRepository(
      remoteDatasource: ref.read(sizeRemoteDatasourceProvider));
});

class SizeNotifier extends StateNotifier<SizeState> {
  final SizeRepository _repo;
  SizeNotifier(this._repo) : super(const SizeState());

  Future<void> loadAll() async {
    state = state.copyWith(status: SizeStatus.loading, errorMessage: null);
    try {
      final items = await _repo.getAll();
      state = state.copyWith(status: SizeStatus.success, items: items);
    } catch (e) {
      state = state.copyWith(
          status: SizeStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> create(SizeModel model) async {
    state = state.copyWith(status: SizeStatus.loading, errorMessage: null);
    try {
      await _repo.create(model);
      final items = await _repo.getAll();
      state = state.copyWith(status: SizeStatus.success, items: items);
    } catch (e) {
      state = state.copyWith(
          status: SizeStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> update(SizeModel model) async {
    state = state.copyWith(status: SizeStatus.loading, errorMessage: null);
    try {
      final updated = await _repo.update(model);
      final list =
          state.items.map((i) => i.id == updated.id ? updated : i).toList();
      state = state.copyWith(status: SizeStatus.success, items: list);
    } catch (e) {
      state = state.copyWith(
          status: SizeStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> delete(String id) async {
    state = state.copyWith(status: SizeStatus.loading, errorMessage: null);
    try {
      await _repo.delete(id);
      final list = state.items.where((i) => i.id != id).toList();
      state = state.copyWith(status: SizeStatus.success, items: list);
    } catch (e) {
      state = state.copyWith(
          status: SizeStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final sizeProvider =
    StateNotifierProvider<SizeNotifier, SizeState>((ref) {
  return SizeNotifier(ref.read(sizeRepositoryProvider));
});
