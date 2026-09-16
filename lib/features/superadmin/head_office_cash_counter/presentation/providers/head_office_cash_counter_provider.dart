import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/datasource/head_office_cash_counter_remote_datasource.dart';
import '../../data/repository/head_office_cash_counter_repository.dart';
import 'head_office_cash_counter_state.dart';

final headOfficeCashCounterRemoteDatasourceProvider =
    Provider<HeadOfficeCashCounterRemoteDatasource>(
        (_) => HeadOfficeCashCounterRemoteDatasource());

final headOfficeCashCounterRepositoryProvider =
    Provider<HeadOfficeCashCounterRepository>((ref) {
  return HeadOfficeCashCounterRepository(
      remoteDatasource: ref.read(headOfficeCashCounterRemoteDatasourceProvider));
});

class HeadOfficeCashCounterNotifier
    extends StateNotifier<HeadOfficeCashCounterState> {
  final HeadOfficeCashCounterRepository _repo;
  HeadOfficeCashCounterNotifier(this._repo)
      : super(const HeadOfficeCashCounterState());

  Future<void> load() async {
    state = state.copyWith(
        status: HeadOfficeCashCounterStatus.loading, errorMessage: null);
    try {
      final records = await _repo.getAll();
      state = state.copyWith(
          status: HeadOfficeCashCounterStatus.success, records: records);
    } catch (e) {
      state = state.copyWith(
          status: HeadOfficeCashCounterStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final headOfficeCashCounterProvider = StateNotifierProvider<
    HeadOfficeCashCounterNotifier, HeadOfficeCashCounterState>((ref) {
  return HeadOfficeCashCounterNotifier(
      ref.read(headOfficeCashCounterRepositoryProvider));
});
