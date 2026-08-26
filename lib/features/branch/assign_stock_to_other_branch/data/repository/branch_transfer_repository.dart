import '../../../../warehouse/assign_stock_to_branch/data/models/assign_stock_model.dart';
import '../datasource/branch_transfer_cart_item.dart';
import '../datasource/branch_transfer_datasource.dart';

class BranchTransferRepository {
  final BranchTransferDatasource _datasource;
  BranchTransferRepository(this._datasource);

  Future<String> generateAssignmentNumber() =>
      _datasource.generateAssignmentNumber();

  Future<List<BranchModel>> getOtherBranches(String excludeBranchId) =>
      _datasource.fetchOtherBranches(excludeBranchId);

  Future<AssignStockModel> saveTransfer({
    required String assignmentNumber,
    required String fromBranchId,
    required String toBranchId,
    required List<BranchTransferCartItem> cartItems,
    String? notes,
  }) =>
      _datasource.saveTransfer(
        assignmentNumber: assignmentNumber,
        fromBranchId: fromBranchId,
        toBranchId: toBranchId,
        cartItems: cartItems,
        notes: notes,
      );

  Future<List<AssignStockModel>> getSentTransfers(String fromBranchId) =>
      _datasource.fetchSentTransfers(fromBranchId);
}
