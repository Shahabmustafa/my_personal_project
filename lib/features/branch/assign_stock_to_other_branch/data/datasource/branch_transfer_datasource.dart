import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../warehouse/assign_stock_to_branch/data/models/assign_stock_model.dart';
import 'branch_transfer_cart_item.dart';

/// Branch-to-branch stock transfer — reuses the same `assign_stock_to_branch`
/// / `assign_stock_to_branch_items` tables the warehouse->branch feature
/// uses. The sending branch's id goes into the `warehouse_id` column (no FK
/// constraint on it, so this is safe) and the receiving branch's id goes
/// into `branch_id` — exactly like a warehouse assignment. The destination
/// branch accepts/rejects it from its existing "Assign Stock My Branch"
/// screen without any changes there.
class BranchTransferDatasource {
  final SupabaseClient _client;
  BranchTransferDatasource(this._client);

  Future<String> generateAssignmentNumber() async {
    final res = await _client
        .from('assign_stock_to_branch')
        .select('assignment_number')
        .like('assignment_number', 'ASB-%');

    int maxNumber = 0;
    for (final row in res as List) {
      final num = row['assignment_number'] as String? ?? '';
      final dashIndex = num.lastIndexOf('-');
      if (dashIndex != -1) {
        final n = int.tryParse(num.substring(dashIndex + 1)) ?? 0;
        if (n > maxNumber) maxNumber = n;
      }
    }
    return 'ASB-${(maxNumber + 1).toString().padLeft(6, '0')}';
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

  /// Assignment save hone ke baad — pending par bhi sending branch se
  /// stock ghata do (accept hone par doosri branch mein add hoga).
  Future<void> decrementStockQuantity(String stockId, int qty) async {
    final res = await _client
        .from('branch_stock_inventory')
        .select('quantity')
        .eq('id', stockId)
        .single();

    final currentQty = (res['quantity'] as num? ?? 0).toInt();
    final newQty = (currentQty - qty).clamp(0, currentQty);

    await _client
        .from('branch_stock_inventory')
        .update({'quantity': newQty}).eq('id', stockId);
  }

  Future<AssignStockModel> saveTransfer({
    required String assignmentNumber,
    required String fromBranchId,
    required String toBranchId,
    required List<BranchTransferCartItem> cartItems,
    String? notes,
  }) async {
    final headerRes = await _client
        .from('assign_stock_to_branch')
        .insert({
          'assignment_number': assignmentNumber,
          'warehouse_id': fromBranchId,
          'branch_id': toBranchId,
          'status': 'pending',
          'notes': notes,
        })
        .select()
        .single();

    final assignmentId = headerRes['id'] as String;

    final itemRows = cartItems
        .map((item) => {
              'assignment_id': assignmentId,
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

    await _client.from('assign_stock_to_branch_items').insert(itemRows);

    for (final item in cartItems) {
      await decrementStockQuantity(item.stockId, item.quantity);
    }

    return AssignStockModel.fromJson(headerRes as Map<String, dynamic>);
  }

  /// Is branch ne doosri branches ko jo transfer bheje hain, unki history.
  Future<List<AssignStockModel>> fetchSentTransfers(String fromBranchId) async {
    final res = await _client
        .from('assign_stock_to_branch')
        .select('*, branches(branch_name)')
        .eq('warehouse_id', fromBranchId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => AssignStockModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
