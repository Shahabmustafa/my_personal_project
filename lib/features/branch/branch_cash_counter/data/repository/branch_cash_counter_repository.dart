import '../datasource/branch_cash_counter_remote_datasource.dart';
import '../model/branch_cash_counter_model.dart';

class BranchCashCounterRepository {
  final BranchCashCounterRemoteDatasource remoteDatasource;
  BranchCashCounterRepository({required this.remoteDatasource});

  Future<List<BranchCashCounterModel>> getByBranch(String branchId) =>
      remoteDatasource.getByBranch(branchId);
}
