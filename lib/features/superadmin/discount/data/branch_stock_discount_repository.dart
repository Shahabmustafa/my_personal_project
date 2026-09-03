import '../../../branch/branch_stock_inventory/data/model/branch_stock_model.dart';
import 'branch_stock_discount_datasource.dart';

class BranchStockDiscountRepository {
  final BranchStockDiscountDatasource _datasource;

  BranchStockDiscountRepository(this._datasource);

  Future<List<BranchStockModel>> getStock(String branchId) =>
      _datasource.fetchStock(branchId);

  Future<void> updateDiscount(String branchStockId, double discount) =>
      _datasource.updateDiscount(branchStockId, discount);
}
