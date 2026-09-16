import '../datasource/sale_exchange_datasource.dart';
import '../model/sale_exchange_model.dart';

class SaleExchangeRepository {
  final SaleExchangeDatasource _datasource;
  SaleExchangeRepository(this._datasource);

  Future<String> generateExchangeNumber() => _datasource.generateExchangeNumber();

  Future<SaleExchangeModel> saveExchange({
    required String exchangeNumber,
    required String branchId,
    String? originalInvoiceId,
    String? printerId,
    String? cashierId,
    String? customerId,
    String? salesmanId,
    required double returnSubtotal,
    required double returnDiscount,
    required double returnTotal,
    required double newSubtotal,
    required double newDiscount,
    required double newTotal,
    required double differenceAmount,
    required double salesmanCommissionPercent,
    required double salesmanCommissionAmount,
    String? note,
    required List<ReturnCartItem> returnItems,
    required List<SaleCartItem> newItems,
    required List<ExchangePaymentInput> payments,
  }) =>
      _datasource.saveExchange(
        exchangeNumber: exchangeNumber,
        branchId: branchId,
        originalInvoiceId: originalInvoiceId,
        printerId: printerId,
        cashierId: cashierId,
        customerId: customerId,
        salesmanId: salesmanId,
        returnSubtotal: returnSubtotal,
        returnDiscount: returnDiscount,
        returnTotal: returnTotal,
        newSubtotal: newSubtotal,
        newDiscount: newDiscount,
        newTotal: newTotal,
        differenceAmount: differenceAmount,
        salesmanCommissionPercent: salesmanCommissionPercent,
        salesmanCommissionAmount: salesmanCommissionAmount,
        note: note,
        returnItems: returnItems,
        newItems: newItems,
        payments: payments,
      );

  Future<List<SaleExchangeModel>> getExchanges(String branchId) =>
      _datasource.fetchExchanges(branchId);

  Future<List<SaleExchangeModel>> getExchangesBySalesman(
          String branchId, String salesmanId) =>
      _datasource.fetchExchangesBySalesman(branchId, salesmanId);
}
