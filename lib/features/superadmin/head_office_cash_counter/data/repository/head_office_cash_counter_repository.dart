import '../datasource/head_office_cash_counter_remote_datasource.dart';
import '../model/head_office_cash_counter_model.dart';

class HeadOfficeCashCounterRepository {
  final HeadOfficeCashCounterRemoteDatasource remoteDatasource;
  HeadOfficeCashCounterRepository({required this.remoteDatasource});

  Future<List<HeadOfficeCashCounterModel>> getAll() =>
      remoteDatasource.getAll();
}
