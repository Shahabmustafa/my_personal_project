import '../../../sale_invoice/data/model/sale_invoice_model.dart';
import '../datasource/sale_claim_datasource.dart';
import '../model/sale_claim_model.dart';

class SaleClaimRepository {
  final SaleClaimDatasource _datasource;
  SaleClaimRepository(this._datasource);

  Future<void> createClaim({
    required String branchId,
    required String headOfficeId,
    required SaleInvoiceModel invoice,
    required SaleInvoiceItemModel item,
    required int quantity,
    required String reason,
    String? claimedBy,
  }) =>
      _datasource.createClaim(
        branchId: branchId,
        headOfficeId: headOfficeId,
        invoice: invoice,
        item: item,
        quantity: quantity,
        reason: reason,
        claimedBy: claimedBy,
      );

  Future<List<SaleClaimModel>> getBranchClaims(String branchId) =>
      _datasource.fetchBranchClaims(branchId);

  Future<List<SaleClaimModel>> getIncomingClaims(String headOfficeId) =>
      _datasource.fetchIncomingClaims(headOfficeId);

  Future<Map<String, int>> getClaimedQuantities(String invoiceId) =>
      _datasource.fetchClaimedQuantities(invoiceId);

  Future<void> approveClaim(String claimId,
          {String? reviewedBy, String? remarks}) =>
      _datasource.approveClaim(claimId,
          reviewedBy: reviewedBy, remarks: remarks);

  Future<void> rejectClaim(String claimId,
          {String? reviewedBy, String? remarks}) =>
      _datasource.rejectClaim(claimId,
          reviewedBy: reviewedBy, remarks: remarks);
}
