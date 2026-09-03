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
        .select(
            '*, branches(branch_name), head_offices(head_office_name), assign_stock_to_branch_items(*)')
        .eq('branch_id', branchId)
        .order('created_at', ascending: false);

    final rows =
        (res as List).map((e) => e as Map<String, dynamic>).toList();

    // "Kis ne assign kiya" resolve karna:
    //  - head_office_id set  → head office (embed se naam mil jata hai)
    //  - warehouse_id kisi warehouse se match  → warehouse
    //  - warehouse_id kisi branch se match (branch → branch transfer)  → branch
    final warehouseIds = <String>{
      for (final r in rows)
        if (r['head_office_id'] == null && r['warehouse_id'] != null)
          r['warehouse_id'] as String
    };
    final assignedByIds = <String>{
      for (final r in rows)
        if (r['assigned_by'] != null) r['assigned_by'] as String
    };

    final warehouseNames = <String, String>{};
    final branchNames = <String, String>{};
    final userNames = <String, String>{};

    if (warehouseIds.isNotEmpty) {
      final ids = warehouseIds.toList();
      final wRes = await _client
          .from('warehouses')
          .select('id, warehouse_name')
          .inFilter('id', ids);
      for (final w in (wRes as List)) {
        warehouseNames[w['id'] as String] = w['warehouse_name'] as String? ?? '';
      }
      final missing =
          ids.where((id) => !warehouseNames.containsKey(id)).toList();
      if (missing.isNotEmpty) {
        final bRes = await _client
            .from('branches')
            .select('id, branch_name')
            .inFilter('id', missing);
        for (final b in (bRes as List)) {
          branchNames[b['id'] as String] = b['branch_name'] as String? ?? '';
        }
      }
    }

    if (assignedByIds.isNotEmpty) {
      final uRes = await _client
          .from('users')
          .select('id, username')
          .inFilter('id', assignedByIds.toList());
      for (final u in (uRes as List)) {
        userNames[u['id'] as String] = u['username'] as String? ?? '';
      }
    }

    return rows.map((json) {
      final itemsJson =
          (json['assign_stock_to_branch_items'] as List?) ?? const [];
      final items = itemsJson
          .map((i) => AssignStockItemModel.fromJson(i as Map<String, dynamic>))
          .toList();

      String? sourceName;
      String? sourceType;
      if (json['head_office_id'] != null) {
        sourceType = 'head_office';
        sourceName = (json['head_offices'] as Map<String, dynamic>?)?[
            'head_office_name'] as String? ?? 'Head Office';
      } else if (json['warehouse_id'] != null) {
        final wid = json['warehouse_id'] as String;
        if (warehouseNames.containsKey(wid)) {
          sourceType = 'warehouse';
          sourceName = warehouseNames[wid];
        } else if (branchNames.containsKey(wid)) {
          sourceType = 'branch';
          sourceName = branchNames[wid];
        }
      }

      return AssignStockModel.fromJson(
        json,
        items: items,
        sourceName: sourceName,
        sourceType: sourceType,
        assignedByName: json['assigned_by'] != null
            ? userNames[json['assigned_by'] as String]
            : null,
      );
    }).toList();
  }

  // ── Fetch assignment detail with items ────────────────────────────────────
  Future<AssignStockModel> fetchAssignmentDetail(String assignmentId) async {
    final headerRes = await _client
        .from('assign_stock_to_branch')
        .select('*, branches(branch_name), head_offices(head_office_name)')
        .eq('id', assignmentId)
        .single();

    // Source resolve (same logic as list)
    String? sourceName;
    String? sourceType;
    if (headerRes['head_office_id'] != null) {
      sourceType = 'head_office';
      sourceName = (headerRes['head_offices'] as Map<String, dynamic>?)?[
          'head_office_name'] as String? ?? 'Head Office';
    } else if (headerRes['warehouse_id'] != null) {
      final wid = headerRes['warehouse_id'] as String;
      final w = await _client
          .from('warehouses')
          .select('warehouse_name')
          .eq('id', wid)
          .maybeSingle();
      if (w != null) {
        sourceType = 'warehouse';
        sourceName = w['warehouse_name'] as String?;
      } else {
        final b = await _client
            .from('branches')
            .select('branch_name')
            .eq('id', wid)
            .maybeSingle();
        if (b != null) {
          sourceType = 'branch';
          sourceName = b['branch_name'] as String?;
        }
      }
    }

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
