import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../sale_invoice/data/model/sale_invoice_model.dart';
import '../model/sale_claim_model.dart';

/// Sale claim — customer ki kharab nikli hui product ka Head Office ke naam
/// claim. Approve hone par branch stock se quantity minus hoti hai
/// (`approve_sale_claim` RPC, supabase_migration.sql).
class SaleClaimDatasource {
  final SupabaseClient _client;
  SaleClaimDatasource(this._client);

  static const _claimSelect = '''
    *,
    branches(branch_name),
    sale_invoices(invoice_number),
    customers(name),
    products(article_name),
    sizes(number),
    colors(name),
    brands(name),
    categories(name),
    types(name)
  ''';

  Future<String> generateClaimNumber() async {
    final res = await _client.rpc('generate_sale_claim_number');
    return res as String;
  }

  Future<void> createClaim({
    required String branchId,
    required String headOfficeId,
    required SaleInvoiceModel invoice,
    required SaleInvoiceItemModel item,
    required int quantity,
    required String reason,
    String? claimedBy,
  }) async {
    final claimNumber = await generateClaimNumber();
    // Line ki total_price discount ke baad hai — claim ke hisse ki value.
    final totalPrice =
        item.quantity == 0 ? 0.0 : item.totalPrice / item.quantity * quantity;

    await _client.from('sale_claims').insert({
      'claim_number': claimNumber,
      'branch_id': branchId,
      'head_office_id': headOfficeId,
      'sale_invoice_id': invoice.id,
      'sale_invoice_item_id': item.id,
      'customer_id': invoice.customerId,
      'branch_stock_id': item.branchStockId,
      'product_id': item.productId,
      'size_id': item.sizeId,
      'color_id': item.colorId,
      'brand_id': item.brandId,
      'category_id': item.categoryId,
      'type_id': item.typeId,
      'barcode': item.barcode,
      'quantity': quantity,
      'sale_price': item.salePrice,
      'purchase_price': item.purchasePrice,
      'total_price': totalPrice,
      'reason': reason,
      'sale_date': invoice.createdAt.toUtc().toIso8601String(),
      'claim_date': DateTime.now().toUtc().toIso8601String(),
      'claimed_by': claimedBy,
    });
  }

  Future<List<SaleClaimModel>> fetchBranchClaims(String branchId) async {
    final res = await _client
        .from('sale_claims')
        .select(_claimSelect)
        .eq('branch_id', branchId)
        .order('created_at', ascending: false);
    return _parse(res);
  }

  /// Head Office ko branches se aaye claims (approve/reject ke liye).
  Future<List<SaleClaimModel>> fetchIncomingClaims(String headOfficeId) async {
    final res = await _client
        .from('sale_claims')
        .select(_claimSelect)
        .eq('head_office_id', headOfficeId)
        .order('created_at', ascending: false);
    return _parse(res);
  }

  /// Ek invoice ki har line par ab tak claim hui quantity (pending + approved;
  /// rejected count nahi hote) — item id -> quantity.
  Future<Map<String, int>> fetchClaimedQuantities(String invoiceId) async {
    final res = await _client
        .from('sale_claims')
        .select('sale_invoice_item_id, quantity')
        .eq('sale_invoice_id', invoiceId)
        .inFilter('status', ['pending', 'approved']);

    final map = <String, int>{};
    for (final row in res as List) {
      final r = row as Map<String, dynamic>;
      final id = r['sale_invoice_item_id'].toString();
      map[id] = (map[id] ?? 0) + (r['quantity'] as num).toInt();
    }
    return map;
  }

  Future<void> approveClaim(
    String claimId, {
    String? reviewedBy,
    String? remarks,
  }) async {
    await _client.rpc('approve_sale_claim', params: {
      'p_claim_id': claimId,
      'p_reviewed_by': reviewedBy,
      'p_remarks': remarks,
    });
  }

  Future<void> rejectClaim(
    String claimId, {
    String? reviewedBy,
    String? remarks,
  }) async {
    await _client.rpc('reject_sale_claim', params: {
      'p_claim_id': claimId,
      'p_reviewed_by': reviewedBy,
      'p_remarks': remarks,
    });
  }

  List<SaleClaimModel> _parse(dynamic res) => (res as List)
      .map((e) => SaleClaimModel.fromJson(e as Map<String, dynamic>))
      .toList();
}
