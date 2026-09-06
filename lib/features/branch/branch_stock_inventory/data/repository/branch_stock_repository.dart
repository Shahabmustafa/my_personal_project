import '../../../../../core/pagination/pagination.dart';
import '../datasource/branch_stock_datasource.dart';
import '../model/branch_stock_model.dart';

class BranchStockRepository {
  final BranchStockDatasource _datasource;

  BranchStockRepository(this._datasource);

  Future<List<BranchStockModel>> getBranchStock(String branchId) =>
      _datasource.fetchBranchStock(branchId);

  Future<PageResult<BranchStockModel>> fetchStockPage(
    PageRequest request, {
    required String branchId,
  }) =>
      _datasource.fetchPage(request, branchId: branchId);
}
