import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/pagination/pagination.dart';
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

  static BranchStockModel _fromViewRow(Map<String, dynamic> r) =>
      BranchStockModel.fromJson({
        ...r,
        'products': {'article_name': r['product_name']},
        'sizes': {'number': r['size_name']},
        'colors': {'name': r['color_name']},
        'brands': {'name': r['brand_name']},
        'categories': {'name': r['category_name']},
        'types': {'name': r['type_name']},
      });

  /// Server-paginated + searched page of this branch's stock (via
  /// `v_branch_stock`). `filters['low_stock'] == true` -> `quantity <= 5`.
  Future<PageResult<BranchStockModel>> fetchPage(
    PageRequest request, {
    required String branchId,
  }) async {
    if (branchId.isEmpty) {
      return const PageResult(rows: [], totalCount: 0);
    }
    var query =
        _client.from('v_branch_stock').select().eq('branch_id', branchId);
    if (request.search.isNotEmpty) {
      query = query.ilike('search_text', '%${request.search.toLowerCase()}%');
    }
    if (request.filters['low_stock'] == true) {
      query = query.lte('quantity', 5);
    }
    final result = await runSupabasePage(
      query.order('created_at', ascending: false),
      request: request,
    );
    return result.map(_fromViewRow);
  }
}
