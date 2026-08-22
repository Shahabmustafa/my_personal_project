import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../purchase_invoice/data/models/warehouse_stock_model.dart';
import '../models/assign_stock_model.dart';

class AssignStockDatasource {
  final SupabaseClient _client;

  AssignStockDatasource(this._client);

  // ── Helper ────────────────────────────────────────────────────────────────
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  // ── Generate assignment number ─────────────────────────────────────────────
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

  // ── Fetch all active branches ──────────────────────────────────────────────
  Future<List<BranchModel>> fetchBranches() async {
    final res = await _client
        .from('branches')
        .select('id, branch_name, city, phone_number, status')
        .eq('status', 'active')
        .order('branch_name');

    return (res as List)
        .map((e) => BranchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Fetch warehouse stock ──────────────────────────────────────────────────
  Future<List<WarehouseStockModel>> fetchWarehouseStock(
      String warehouseId) async {
    final res = await _client
        .from('warehouse_stock_inventory')
        .select('''
          id,
          barcode,
          quantity,
          discount,
          warehouse_id,
          product_id,
          size_id,
          color_id,
          brand_id,
          category_id,
          type_id,
          products ( article_name, sale_price, purchase_price ),
          sizes    ( number ),
          colors   ( name ),
          brands   ( name ),
          categories ( name ),
          types    ( name )
        ''')
        .eq('warehouse_id', warehouseId);

    final List<WarehouseStockModel> result = [];

    for (final row in res as List) {
      try {
        final map = row as Map<String, dynamic>;

        if (map['product_id'] == null ||
            map['size_id'] == null ||
            map['color_id'] == null ||
            map['brand_id'] == null ||
            map['category_id'] == null ||
            map['type_id'] == null) {
          continue;
        }

        final productMap = (map['products'] as Map<String, dynamic>?) ?? {};
        final sizeMap    = (map['sizes']    as Map<String, dynamic>?) ?? {};
        final colorMap   = (map['colors']   as Map<String, dynamic>?) ?? {};
        final brandMap   = (map['brands']   as Map<String, dynamic>?) ?? {};
        final catMap     = (map['categories'] as Map<String, dynamic>?) ?? {};
        final typeMap    = (map['types']    as Map<String, dynamic>?) ?? {};

        final safeMap = <String, dynamic>{
          'id':           map['id'] as String,
          'barcode':      map['barcode'] as String? ?? '',
          'quantity':     (map['quantity'] as num? ?? 0).toInt(),
          'discount':     _toDouble(map['discount']),
          'warehouse_id': map['warehouse_id'] as String? ?? '',
          'product_id':   map['product_id'] as String,
          'size_id':      map['size_id']    as String,
          'color_id':     map['color_id']   as String,
          'brand_id':     map['brand_id']   as String,
          'category_id':  map['category_id'] as String,
          'type_id':      map['type_id']    as String,
          'products': {
            'article_name':   productMap['article_name']  as String? ?? '',
            'sale_price':     _toDouble(productMap['sale_price']),
            'purchase_price': _toDouble(productMap['purchase_price']),
          },
          'sizes':      {'number': sizeMap['number']  as String? ?? ''},
          'colors':     {'name':   colorMap['name']   as String? ?? ''},
          'brands':     {'name':   brandMap['name']   as String? ?? ''},
          'categories': {'name':   catMap['name']     as String? ?? ''},
          'types':      {'name':   typeMap['name']    as String? ?? ''},
        };

        result.add(WarehouseStockModel.fromJson(safeMap));
      } catch (e) {
        continue;
      }
    }

    return result;
  }

  // ── Decrement warehouse stock quantity ────────────────────────────────────
  // Assignment save hone ke baad — pending status par bhi warehouse se ghata do
  Future<void> decrementStockQuantity(String stockId, int qty) async {
    final res = await _client
        .from('warehouse_stock_inventory')
        .select('quantity')
        .eq('id', stockId)
        .single();

    final currentQty = (res['quantity'] as num? ?? 0).toInt();
    final newQty = (currentQty - qty).clamp(0, currentQty);

    await _client
        .from('warehouse_stock_inventory')
        .update({'quantity': newQty}).eq('id', stockId);
  }

  // ── Save assignment ────────────────────────────────────────────────────────
  Future<AssignStockModel> saveAssignment({
    required String assignmentNumber,
    required String warehouseId,
    required String branchId,
    required List<AssignCartItem> cartItems,
    String? notes,
  }) async {
    // 1. Insert header
    final headerRes = await _client
        .from('assign_stock_to_branch')
        .insert({
          'assignment_number': assignmentNumber,
          'warehouse_id':      warehouseId,
          'branch_id':         branchId,
          'status':            'pending',
          'notes':             notes,
        })
        .select()
        .single();

    final assignmentId = headerRes['id'] as String;

    // 2. Insert items
    final itemRows = cartItems
        .map((item) => {
              'assignment_id':  assignmentId,
              'stock_id':       item.stockId,
              'barcode':        item.barcode,
              'product_id':     item.productId,
              'size_id':        item.sizeId,
              'color_id':       item.colorId,
              'brand_id':       item.brandId,
              'category_id':    item.categoryId,
              'type_id':        item.typeId,
              'quantity':       item.quantity,
              'sale_price':     item.salePrice,
              'purchase_price': item.purchasePrice,
              'discount':       item.discount,
            })
        .toList();

    await _client.from('assign_stock_to_branch_items').insert(itemRows);

    // 3. ✅ Warehouse stock ghata do — pending par bhi
    // (Accept hone par RPC accept_stock_assignment further logic handle karta hai)
    for (final item in cartItems) {
      await decrementStockQuantity(item.stockId, item.quantity);
    }

    return AssignStockModel.fromJson(headerRes as Map<String, dynamic>);
  }

  // ── Fetch all assignments for warehouse ────────────────────────────────────
  Future<List<AssignStockModel>> fetchAssignments(String warehouseId) async {
    final res = await _client
        .from('assign_stock_to_branch')
        .select('*, branches(branch_name)')
        .eq('warehouse_id', warehouseId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => AssignStockModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Fetch assignment detail with items ─────────────────────────────────────
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

  // ── Accept assignment (RPC) ────────────────────────────────────────────────
  Future<void> acceptAssignment(String assignmentId) async {
    await _client.rpc(
      'accept_stock_assignment',
      params: {'p_assignment_id': assignmentId},
    );
  }

  // ── Reject assignment — stock wapas karo ──────────────────────────────────
  // Reject hone par jo stock ghata tha woh wapas warehouse mein add karo
  Future<void> rejectAssignment(String assignmentId) async {
    // 1. Items fetch karo
    final itemsRes = await _client
        .from('assign_stock_to_branch_items')
        .select('stock_id, quantity')
        .eq('assignment_id', assignmentId);

    // 2. Status reject karo
    await _client
        .from('assign_stock_to_branch')
        .update({'status': 'rejected'}).eq('id', assignmentId);

    // 3. ✅ Stock wapas karo warehouse mein
    for (final row in itemsRes as List) {
      final stockId = row['stock_id'] as String;
      final qty     = (row['quantity'] as num? ?? 0).toInt();

      final res = await _client
          .from('warehouse_stock_inventory')
          .select('quantity')
          .eq('id', stockId)
          .single();

      final currentQty = (res['quantity'] as num? ?? 0).toInt();
      await _client
          .from('warehouse_stock_inventory')
          .update({'quantity': currentQty + qty}).eq('id', stockId);
    }
  }
}
