import '../../../../../core/pagination/pagination.dart';
import '../datasource/branch_cash_counter_remote_datasource.dart';
import '../model/branch_cash_counter_model.dart';

class BranchCashCounterRepository {
  final BranchCashCounterRemoteDatasource remoteDatasource;
  BranchCashCounterRepository({required this.remoteDatasource});

  Future<PageResult<BranchCashCounterModel>> fetchPage(
    PageRequest request, {
    required String branchId,
  }) =>
      remoteDatasource.fetchPage(request, branchId: branchId);

  Future<BranchCashCounterStats> getStats(String branchId, {String search = ''}) =>
      remoteDatasource.fetchStats(branchId, search: search);
}
