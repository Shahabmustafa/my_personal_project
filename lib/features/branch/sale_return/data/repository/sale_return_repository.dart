import '../datasource/sale_return_datasource.dart';
import '../model/sale_return_model.dart';

class SaleReturnRepository {
  final SaleReturnDatasource _datasource;
  SaleReturnRepository(this._datasource);

  Future<String> generateReturnNumber() => _datasource.generateReturnNumber();

  Future<SaleReturnModel> saveSaleReturn({
    required String returnNumber,
    required String branchId,
    String? printerId,
    String? cashierId,
    required String customerId,
    required double subtotal,
    required double totalDiscount,
    required double totalAmount,
    String? note,
    required List<SaleCartItem> cartItems,
    required List<PaymentInput> payments,
  }) =>
      _datasource.saveSaleReturn(
        returnNumber: returnNumber,
        branchId: branchId,
        printerId: printerId,
        cashierId: cashierId,
        customerId: customerId,
        subtotal: subtotal,
        totalDiscount: totalDiscount,
        totalAmount: totalAmount,
        note: note,
        cartItems: cartItems,
        payments: payments,
      );

  Future<List<SaleReturnModel>> getReturns(String branchId) =>
      _datasource.fetchReturns(branchId);
}
