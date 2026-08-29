import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/branch_warehouse_return_model.dart';
import 'branch_warehouse_return_cart_item.dart';

/// Branch -> Warehouse stock return — own tables
/// (`branch_return_to_warehouse` / `branch_return_to_warehouse_items`).
/// Saving goes through `create_branch_return_to_warehouse`, a server-side
/// function that validates every line's quantity against the branch's
/// actual stock (locks the row, rejects the whole return atomically if any
/// line asks for more than is available) before decrementing anything.
class BranchWarehouseReturnDatasource {
  final SupabaseClient _client;
  BranchWarehouseReturnDatasource(this._client);

  Future<String> generateReturnNumber() async {
    final res = await _client.rpc('generate_branch_warehouse_return_number');
    return res as String;
  }

  Future<List<WarehouseModel>> fetchActiveWarehouses() async {
    final res = await _client
        .from('warehouses')
        .select('id, warehouse_name, address, phone_number, city, status')
        .eq('status', 'active')
        .order('warehouse_name');

    return (res as List)
        .map((e) => WarehouseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveReturn({
    required String branchId,
    required String warehouseId,
    String? returnedBy,
    String? notes,
    required List<BranchWarehouseReturnCartItem> cartItems,
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

    await _client.rpc('create_branch_return_to_warehouse', params: {
      'p_return_number': returnNumber,
      'p_branch_id': branchId,
      'p_warehouse_id': warehouseId,
      'p_returned_by': returnedBy,
      'p_notes': notes,
      'p_items': items,
    });
  }

  static const _returnSelect = '*, branches(branch_name), warehouses(warehouse_name)';

  /// Is branch ne warehouse(s) ko jo returns bheje hain.
  Future<List<BranchWarehouseReturnModel>> fetchSentReturns(String branchId) async {
    final res = await _client
        .from('branch_return_to_warehouse')
        .select(_returnSelect)
        .eq('branch_id', branchId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => BranchWarehouseReturnModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Is warehouse ko branches se jo returns aaye hain (accept/reject ke liye).
  Future<List<BranchWarehouseReturnModel>> fetchIncomingReturns(String warehouseId) async {
    final res = await _client
        .from('branch_return_to_warehouse')
        .select('$_returnSelect, branch_return_to_warehouse_items(*)')
        .eq('warehouse_id', warehouseId)
        .order('created_at', ascending: false);

    return (res as List).map((e) {
      final json = e as Map<String, dynamic>;
      final itemsJson = (json['branch_return_to_warehouse_items'] as List?) ?? const [];
      final items = itemsJson
          .map((i) => BranchWarehouseReturnItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
      return BranchWarehouseReturnModel.fromJson(json, items: items);
    }).toList();
  }

  Future<void> acceptReturn(String returnId) async {
    await _client.rpc('accept_branch_return_to_warehouse', params: {'p_return_id': returnId});
  }

  Future<void> rejectReturn(String returnId) async {
    await _client.rpc('reject_branch_return_to_warehouse', params: {'p_return_id': returnId});
  }
}
