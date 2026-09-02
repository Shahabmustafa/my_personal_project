import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/datasource/head_office_remote_datasource.dart';
import '../../data/model/head_office_model.dart';
import '../../data/repository/head_office_repository.dart';
import 'head_office_state.dart';

final headOfficeRemoteDatasourceProvider =
    Provider<HeadOfficeRemoteDatasource>((_) => HeadOfficeRemoteDatasource());

final headOfficeRepositoryProvider = Provider<HeadOfficeRepository>((ref) {
  return HeadOfficeRepository(
      remoteDatasource: ref.read(headOfficeRemoteDatasourceProvider));
});

class HeadOfficeNotifier extends StateNotifier<HeadOfficeState> {
  final HeadOfficeRepository _repo;
  HeadOfficeNotifier(this._repo) : super(const HeadOfficeState());

  Future<void> loadAllHeadOffices() async {
    state = state.copyWith(status: HeadOfficeStatus.loading, errorMessage: null);
    try {
      final headOffices = await _repo.getAllHeadOffices();
      state = state.copyWith(
          status: HeadOfficeStatus.success, headOffices: headOffices);
    } catch (e) {
      state = state.copyWith(
          status: HeadOfficeStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> createHeadOffice(HeadOfficeModel headOffice) async {
    // Sirf ek hi head office allowed hai.
    if (state.headOffices.isNotEmpty) {
      state = state.copyWith(
          status: HeadOfficeStatus.error,
          errorMessage: 'Sirf ek head office allowed hai. '
              'Pehle wala edit karein ya delete karein.');
      return;
    }
    state = state.copyWith(status: HeadOfficeStatus.loading, errorMessage: null);
    try {
      final created = await _repo.createHeadOffice(headOffice);
      state = state.copyWith(
          status: HeadOfficeStatus.success,
          headOffices: [...state.headOffices, created]);
    } catch (e) {
      state = state.copyWith(
          status: HeadOfficeStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> updateHeadOffice(HeadOfficeModel headOffice) async {
    state = state.copyWith(status: HeadOfficeStatus.loading, errorMessage: null);
    try {
      final updated = await _repo.updateHeadOffice(headOffice);
      final list = state.headOffices
          .map((h) => h.id == updated.id ? updated : h)
          .toList();
      state = state.copyWith(
          status: HeadOfficeStatus.success, headOffices: list);
    } catch (e) {
      state = state.copyWith(
          status: HeadOfficeStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteHeadOffice(String id) async {
    state = state.copyWith(status: HeadOfficeStatus.loading, errorMessage: null);
    try {
      await _repo.deleteHeadOffice(id);
      state = state.copyWith(
          status: HeadOfficeStatus.success,
          headOffices: state.headOffices.where((h) => h.id != id).toList());
    } catch (e) {
      state = state.copyWith(
          status: HeadOfficeStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final headOfficeProvider =
    StateNotifierProvider<HeadOfficeNotifier, HeadOfficeState>((ref) {
  return HeadOfficeNotifier(ref.read(headOfficeRepositoryProvider));
});
