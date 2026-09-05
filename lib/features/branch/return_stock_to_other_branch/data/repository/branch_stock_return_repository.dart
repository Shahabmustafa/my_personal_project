import '../datasource/branch_return_cart_item.dart';
import '../datasource/branch_stock_return_datasource.dart';
import '../model/branch_stock_return_model.dart';

class BranchStockReturnRepository {
  final BranchStockReturnDatasource _datasource;
  BranchStockReturnRepository(this._datasource);

  Future<String> generateReturnNumber() => _datasource.generateReturnNumber();

  Future<List<BranchModel>> getOtherBranches(String excludeBranchId) =>
      _datasource.fetchOtherBranches(excludeBranchId);

  Future<void> saveReturn({
    required String fromBranchId,
    required String toBranchId,
    String? returnedBy,
    String? notes,
    required List<BranchReturnCartItem> cartItems,
  }) =>
      _datasource.saveReturn(
        fromBranchId: fromBranchId,
        toBranchId: toBranchId,
        returnedBy: returnedBy,
        notes: notes,
        cartItems: cartItems,
      );

  Future<List<BranchStockReturnModel>> getSentReturns(String fromBranchId) =>
      _datasource.fetchSentReturns(fromBranchId);

  Future<BranchStockReturnModel> getReturnDetail(String returnId) =>
      _datasource.fetchReturnDetail(returnId);

  Future<List<BranchStockReturnModel>> getIncomingReturns(String toBranchId) =>
      _datasource.fetchIncomingReturns(toBranchId);

  Future<void> acceptReturn(String returnId) => _datasource.acceptReturn(returnId);

  Future<void> rejectReturn(String returnId) => _datasource.rejectReturn(returnId);
}
