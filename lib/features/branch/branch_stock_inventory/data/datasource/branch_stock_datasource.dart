import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/branch_stock_model.dart';

class BranchStockDatasource {
  final SupabaseClient _client;

  BranchStockDatasource(this._client);

  Future<List<BranchStockModel>> fetchBranchStock(String branchId) async {
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
}
