import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../warehouse/assign_stock_to_branch/data/models/assign_stock_model.dart';

class BranchAssignDatasource {
  final SupabaseClient _client;

  BranchAssignDatasource(this._client);

  // ── Fetch assignments for a specific branch ───────────────────────────────
  // Items ko bhi embed karte hain taake list screen par total quantity /
  // total sale price jaisi summary cards bina extra per-row calls ke ban sakein.
  Future<List<AssignStockModel>> fetchBranchAssignments(
      String branchId) async {
    final res = await _client
        .from('assign_stock_to_branch')
        .select('*, branches(branch_name), assign_stock_to_branch_items(*)')
        .eq('assigned_to', branchId)
        .order('created_at', ascending: false);

    final rows =
        (res as List).map((e) => e as Map<String, dynamic>).toList();
    final sources = await _resolveSources({
      for (final r in rows) r['assigned_by'] as String,
    });

    return rows.map((json) {
      final itemsJson =
          (json['assign_stock_to_branch_items'] as List?) ?? const [];
      final items = itemsJson
          .map((i) => AssignStockItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
      final source = sources[json['assigned_by']];

      return AssignStockModel.fromJson(
        json,
        items: items,
        sourceType: source?.type,
        sourceName: source?.name,
      );
    }).toList();
  }

  // ── "Kis ne assign kiya" resolve karna ────────────────────────────────────
  // assigned_by par FK nahi (id head office / warehouse / branch kisi ki bhi
  // ho sakti hai), is liye teeno tables mein dhoondte hain.
  Future<Map<String, ({String type, String name})>> _resolveSources(
      Set<String> ids) async {
    final out = <String, ({String type, String name})>{};
    if (ids.isEmpty) return out;

    Future<void> lookup(
        String table, String nameCol, String type, String fallback) async {
      final missing = ids.where((id) => !out.containsKey(id)).toList();
      if (missing.isEmpty) return;
      final res = await _client
          .from(table)
          .select('id, $nameCol')
          .inFilter('id', missing);
      for (final r in res as List) {
        final name = r[nameCol] as String?;
        out[r['id'] as String] = (
          type: type,
          name: (name == null || name.trim().isEmpty) ? fallback : name,
        );
      }
    }

    await lookup('head_offices', 'head_office_name', 'head_office',
        'Head Office');
    await lookup('warehouses', 'warehouse_name', 'warehouse', 'Warehouse');
    await lookup('branches', 'branch_name', 'branch', 'Branch');
    return out;
  }

  // ── Fetch assignment detail with items ────────────────────────────────────
  Future<AssignStockModel> fetchAssignmentDetail(String assignmentId) async {
    final headerRes = await _client
        .from('assign_stock_to_branch')
        .select('*, branches(branch_name)')
        .eq('id', assignmentId)
        .single();

    final sources =
        await _resolveSources({headerRes['assigned_by'] as String});
    final source = sources[headerRes['assigned_by']];
    final sourceName = source?.name;
    final sourceType = source?.type;

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
      headerRes,
      items: items,
      sourceName: sourceName,
      sourceType: sourceType,
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
