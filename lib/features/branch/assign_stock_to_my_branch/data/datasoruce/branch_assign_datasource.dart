import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../warehouse/assign_stock_to_branch/data/models/assign_stock_model.dart';

class BranchAssignDatasource {
  final SupabaseClient _client;

  BranchAssignDatasource(this._client);

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  // ── Fetch assignments for a specific branch ───────────────────────────────
  // Items ko bhi embed karte hain taake list screen par total quantity /
  // total sale price jaisi summary cards bina extra per-row calls ke ban sakein.
  Future<List<AssignStockModel>> fetchBranchAssignments(
      String branchId) async {
    final res = await _client
        .from('assign_stock_to_branch')
        .select('*, branches(branch_name), assign_stock_to_branch_items(*)')
        .eq('branch_id', branchId)
        .order('created_at', ascending: false);

    return (res as List).map((e) {
      final json = e as Map<String, dynamic>;
      final itemsJson =
          (json['assign_stock_to_branch_items'] as List?) ?? const [];
      final items = itemsJson
          .map((i) => AssignStockItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
      return AssignStockModel.fromJson(json, items: items);
    }).toList();
  }

  // ── Fetch assignment detail with items ────────────────────────────────────
  Future<AssignStockModel> fetchAssignmentDetail(String assignmentId) async {
    final headerRes = await _client
        .from('assign_stock_to_branch')
        .select('*, branches(branch_name)')
        .eq('id', assignmentId)
        .single();

    final itemsRes = await _client
        .from('assign_stock_to_branch_items')
        .select('''
          *,
          products   ( article_name ),
          sizes      ( number ),
          colors     ( name ),
          brands     ( name ),
          categories ( name ),
          types      ( name )
        ''')
        .eq('assignment_id', assignmentId);

    final items = (itemsRes as List)
        .map((e) => AssignStockItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return AssignStockModel.fromJson(
      headerRes as Map<String, dynamic>,
      items: items,
    );
  }

  // ── Accept — RPC call (branch inventory mein stock add) ───────────────────
  Future<void> acceptAssignment(String assignmentId) async {
    await _client.rpc(
      'accept_stock_assignment',
      params: {'p_assignment_id': assignmentId},
    );
  }

  // ── Reject — RPC call (warehouse mein stock wapas) ───────────────────────
  Future<void> rejectAssignment(String assignmentId) async {
    await _client.rpc(
      'reject_stock_assignment',
      params: {'p_assignment_id': assignmentId},
    );
  }
}
