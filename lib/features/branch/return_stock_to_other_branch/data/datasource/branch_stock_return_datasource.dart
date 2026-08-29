import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/branch_stock_return_model.dart';
import 'branch_return_cart_item.dart';

/// Branch-to-branch stock return — own tables (`branch_stock_returns` /
/// `branch_stock_return_items`), separate from the assign-stock-to-branch
/// tables so returns are tracked as their own transaction type. Saving goes
/// through `create_branch_stock_return`, a server-side function that
/// validates every line's quantity against the sending branch's actual
/// stock (locks the row, rejects the whole return atomically if any line
/// asks for more than is available) before decrementing anything — this is
/// the "server side validation" the feature was asked for, not just a
/// client-side check.
class BranchStockReturnDatasource {
  final SupabaseClient _client;
  BranchStockReturnDatasource(this._client);

  Future<String> generateReturnNumber() async {
    final res = await _client.rpc('generate_branch_return_number');
    return res as String;
  }

  /// Sab active branches, current (sending) branch ko chhod kar.
  Future<List<BranchModel>> fetchOtherBranches(String excludeBranchId) async {
    final res = await _client
        .from('branches')
        .select('id, branch_name, city, phone_number, status')
        .eq('status', 'active')
        .neq('id', excludeBranchId)
        .order('branch_name');

    return (res as List)
        .map((e) => BranchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveReturn({
    required String fromBranchId,
    required String toBranchId,
    String? returnedBy,
    String? notes,
    required List<BranchReturnCartItem> cartItems,
  }) async {
    final returnNumber = await generateReturnNumber();

    final items = cartItems
        .map((item) => {
              'stock_id': item.stockId,
              'barcode': item.barcode,
              'product_id': item.productId,
              'size_id': item.sizeId,
              'color_id': item.colorId,
              'brand_id': item.brandId,
              'category_id': item.categoryId,
              'type_id': item.typeId,
              'quantity': item.quantity,
              'sale_price': item.salePrice,
              'purchase_price': item.purchasePrice,
              'discount': item.discount,
            })
        .toList();

    // Server-side function raises an exception (surfaced here as a
    // PostgrestException) if any line's quantity exceeds what's actually
    // in branch_stock_inventory for fromBranchId — nothing gets written.
    await _client.rpc('create_branch_stock_return', params: {
      'p_return_number': returnNumber,
      'p_from_branch_id': fromBranchId,
      'p_to_branch_id': toBranchId,
      'p_returned_by': returnedBy,
      'p_notes': notes,
      'p_items': items,
    });
  }

  static const _returnSelect =
      '*, from_branch:branches!branch_stock_returns_from_branch_id_fkey(branch_name), '
      'to_branch:branches!branch_stock_returns_to_branch_id_fkey(branch_name)';

  /// Is branch ne doosri branches ko jo returns bheje hain.
  Future<List<BranchStockReturnModel>> fetchSentReturns(String fromBranchId) async {
    final res = await _client
        .from('branch_stock_returns')
        .select(_returnSelect)
        .eq('from_branch_id', fromBranchId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => BranchStockReturnModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Is branch ko doosri branches se jo returns aaye hain (accept/reject ke liye).
  Future<List<BranchStockReturnModel>> fetchIncomingReturns(String toBranchId) async {
    final res = await _client
        .from('branch_stock_returns')
        .select('$_returnSelect, branch_stock_return_items(*)')
        .eq('to_branch_id', toBranchId)
        .order('created_at', ascending: false);

    return (res as List).map((e) {
      final json = e as Map<String, dynamic>;
      final itemsJson = (json['branch_stock_return_items'] as List?) ?? const [];
      final items = itemsJson
          .map((i) => BranchStockReturnItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
      return BranchStockReturnModel.fromJson(json, items: items);
    }).toList();
  }

  Future<void> acceptReturn(String returnId) async {
    await _client.rpc('accept_branch_stock_return', params: {'p_return_id': returnId});
  }

  Future<void> rejectReturn(String returnId) async {
    await _client.rpc('reject_branch_stock_return', params: {'p_return_id': returnId});
  }
}
