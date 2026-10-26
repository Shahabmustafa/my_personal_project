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
  }) => _datasource.fetchPage(request, branchId: branchId);

  Future<List<BranchStockModel>> fetchVariants(
    BranchStockModel s, {
    required String branchId,
  }) => _datasource.fetchVariants(
    branchId: branchId,
    productId: s.productId,
    colorId: s.colorId,
    brandId: s.brandId,
    categoryId: s.categoryId,
    typeId: s.typeId,
  );

  /// Har page ko loop kar ke filter/search ke saare rows (print ke liye).
  Future<List<BranchStockModel>> fetchAllStock({
    required String branchId,
    String search = '',
    Map<String, Object?> filters = const {},
  }) async {
    const size = 1000;
    final all = <BranchStockModel>[];
    for (var page = 1; ; page++) {
      final res = await _datasource.fetchPage(
        PageRequest(
          page: page,
          pageSize: size,
          search: sanitizeSearch(search),
          filters: filters,
          withCount: false,
        ),
        branchId: branchId,
      );
      all.addAll(res.rows);
      if (res.rows.length < size) return all;
    }
  }
}
