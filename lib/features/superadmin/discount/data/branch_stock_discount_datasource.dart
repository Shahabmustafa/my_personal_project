import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../branch/branch_stock_inventory/data/model/branch_stock_model.dart';

/// Superadmin ke liye — kisi bhi branch ka stock padhna aur us par
/// per-article discount % (branch_stock_inventory.discount) set karna.
class BranchStockDiscountDatasource {
  final SupabaseClient _client;

  BranchStockDiscountDatasource(this._client);

  Future<List<BranchStockModel>> fetchStock(String branchId) async {
    if (branchId.isEmpty) return [];
    final res = await _client
        .from('branch_stock_inventory')
        .select('''
          *,
          products   ( article_name ),
          sizes      ( number ),
          colors     ( name ),
          brands     ( name ),
          categories ( name ),
          types      ( name )
        ''')
        .eq('branch_id', branchId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => BranchStockModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateDiscount(String branchStockId, double discount) async {
    await _client.from('branch_stock_inventory').update({
      'discount': discount,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', branchStockId);
  }
}
