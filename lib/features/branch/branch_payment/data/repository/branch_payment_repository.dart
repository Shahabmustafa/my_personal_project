import '../datasource/branch_payment_datasource.dart';
import '../model/branch_payment_model.dart';

class BranchPaymentRepository {
  final BranchPaymentDatasource _datasource;
  BranchPaymentRepository(this._datasource);

  Future<void> pay({
    required String branchId,
    required double amount,
    String? notes,
  }) => _datasource.createPayment(branchId: branchId, amount: amount, notes: notes);

  Future<List<BranchPaymentModel>> getIncomingPayments(String headOfficeId) =>
      _datasource.fetchIncomingPayments(headOfficeId);

  Future<List<BranchPaymentModel>> getBranchPayments(String branchId) =>
      _datasource.fetchBranchPayments(branchId);

  Future<void> acceptPayment(String paymentId) =>
      _datasource.acceptPayment(paymentId);

  Future<void> rejectPayment(String paymentId) =>
      _datasource.rejectPayment(paymentId);
}
