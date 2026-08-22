import '../datasource/branch_overview_datasource.dart';
import '../model/branch_overview_model.dart';

class BranchOverviewRepository {
  final BranchOverviewDatasource _datasource;
  BranchOverviewRepository(this._datasource);

  Future<BranchOverviewData> getOverview(String branchId) async {
    final results = await Future.wait([
      _datasource.fetchArticleCount(branchId),
      _datasource.fetchInvoiceCount(branchId),
      _datasource.fetchSalesmanCount(branchId),
    ]);
    final counter = await _datasource.fetchTodayCounter(branchId);

    return BranchOverviewData(
      totalArticles: results[0],
      totalInvoices: results[1],
      totalSalesman: results[2],
      todaySale: counter.todaySale,
      todayExpense: counter.todayExpense,
    );
  }
}
