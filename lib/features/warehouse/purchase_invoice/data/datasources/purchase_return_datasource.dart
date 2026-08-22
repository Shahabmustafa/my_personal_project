import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/purchase_invoice_model.dart';
import '../models/purchase_return_model.dart';
import '../models/warehouse_stock_model.dart';

class PurchaseReturnDatasource {
  final SupabaseClient _client;

  PurchaseReturnDatasource(this._client);

  static const _stockJoin = '''
    *,
    products(article_name, sale_price, purchase_price),
    sizes(number),
    brands(name),
    companies(name),
    colors(name),
    categories(name),
    types(name),
    warehouses(warehouse_name)
  ''';

  // ── Get or create today's cash counter ───────────────────────────────────

  Future<WarehouseCashCounter> getOrCreateCounter(String warehouseId) async {
    final res = await _client.rpc(
      'get_or_create_counter',
      params: {'p_warehouse_id': warehouseId},
    );
    return WarehouseCashCounter.fromJson(res as Map<String, dynamic>);
  }

  Future<void> deductFromCounter(String warehouseId, double amount) async {
    final counter = await getOrCreateCounter(warehouseId);
    await _client.from('warehouse_cash_counter').update({
      'net_amount': counter.netAmount - amount,
      'total_purchase': counter.totalPurchase + amount,
    }).eq('id', counter.id);
  }

  /// Purchase return: cash wapas aaya → net_amount barhao
  Future<void> addBackToCounter(String warehouseId, double amount) async {
    final counter = await getOrCreateCounter(warehouseId);
    await _client.from('warehouse_cash_counter').update({
      'net_amount': counter.netAmount + amount,
      'total_return_purchase': counter.totalReturnPurchase + amount,
    }).eq('id', counter.id);
  }

  Future<void> setNetAmount(String warehouseId, double newAmount) async {
    final counter = await getOrCreateCounter(warehouseId);
    await _client.from('warehouse_cash_counter').update({
      'net_amount': newAmount,
    }).eq('id', counter.id);
  }

  // ── Generate return number ────────────────────────────────────────────────

  Future<String> generateReturnNumber() async {
    final res = await _client
        .from('purchase_returns')
        .select('return_number')
        .like('return_number', 'PR-%');

    int maxNumber = 0;
    for (final row in res as List) {
      final inv = row['return_number'] as String? ?? '';
      final dashIndex = inv.lastIndexOf('-');
      if (dashIndex != -1) {
        final n = int.tryParse(inv.substring(dashIndex + 1)) ?? 0;
        if (n > maxNumber) maxNumber = n;
      }
    }
    return 'PR-${(maxNumber + 1).toString().padLeft(6, '0')}';
  }

  // ── Fetch warehouse stock ─────────────────────────────────────────────────

  Future<List<WarehouseStockModel>> fetchWarehouseStock(
      String warehouseId) async {
    final response = await _client
        .from('warehouse_stock_inventory')
        .select(_stockJoin)
        .eq('warehouse_id', warehouseId);

    return (response as List)
        .map((e) => WarehouseStockModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Fetch stock by barcode ────────────────────────────────────────────────

  Future<WarehouseStockModel?> fetchStockByBarcode(String barcode) async {
    final res = await _client
        .from('warehouse_stock_inventory')
        .select(_stockJoin)
        .eq('barcode', barcode)
        .maybeSingle();

    if (res == null) return null;
    return WarehouseStockModel.fromJson(res as Map<String, dynamic>);
  }

  // ── Fetch companies ───────────────────────────────────────────────────────

  Future<List<StockLookupItem>> fetchCompanies() async {
    final res =
        await _client.from('companies').select('id, name').order('name');
    return (res as List)
        .map((e) =>
            StockLookupItem(id: e['id'] as String, label: e['name'] as String))
        .toList();
  }

  // ── Fetch company with balance ────────────────────────────────────────────

  Future<CompanyWithBalance?> fetchCompanyWithBalance(String companyId) async {
    final res = await _client
        .from('companies')
        .select('id, name, opening_balance')
        .eq('id', companyId)
        .maybeSingle();
    if (res == null) return null;
    return CompanyWithBalance.fromJson(res as Map<String, dynamic>);
  }

  // ── Update company opening_balance ────────────────────────────────────────

  Future<void> updateCompanyOpeningBalance(
      String companyId, double newBalance) async {
    await _client
        .from('companies')
        .update({'opening_balance': newBalance}).eq('id', companyId);
  }

  // ── Fetch purchase invoices (for linking) ────────────────────────────────

  Future<List<Map<String, String>>> fetchInvoiceNumbers(
      String warehouseId) async {
    final res = await _client
        .from('purchase_invoices')
        .select('id, invoice_number')
        .eq('warehouse_id', warehouseId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => {
              'id': e['id'] as String,
              'label': e['invoice_number'] as String,
            })
        .toList();
  }

  // ── Decrement stock quantity (return → stock kamao) ───────────────────────

  Future<void> decrementStockQuantity(String stockId, int qty) async {
    final res = await _client
        .from('warehouse_stock_inventory')
        .select('quantity')
        .eq('id', stockId)
        .single();
    final currentQty = (res['quantity'] as int? ?? 0);
    // Minimum 0 tak girao — negative stock nahi hona chahiye
    final newQty = (currentQty - qty).clamp(0, double.maxFinite.toInt());
    await _client
        .from('warehouse_stock_inventory')
        .update({'quantity': newQty}).eq('id', stockId);
  }

  // ── Save purchase return + items ──────────────────────────────────────────

  Future<PurchaseReturnModel> savePurchaseReturn({
    required String returnNumber,
    required String warehouseId,
    String? companyId,
    String? originalInvoiceId,
    required double totalAmount,
    required double totalDiscount,
    required double netAmount,
    required List<ReturnCartItem> cartItems,
    String? notes,
  }) async {
    // 1. Insert return header
    final returnRes = await _client
        .from('purchase_returns')
        .insert({
          'return_number': returnNumber,
          'original_invoice_id': originalInvoiceId,
          'company_id': companyId,
          'warehouse_id': warehouseId,
          'total_amount': totalAmount,
          'total_discount': totalDiscount,
          'net_amount': netAmount,
          'notes': notes,
        })
        .select('*, companies(name)')
        .single();

    final returnModel =
        PurchaseReturnModel.fromJson(returnRes as Map<String, dynamic>);

    // 2. Insert line items
    final itemsPayload = cartItems
        .map((item) => {
              'purchase_return_id': returnModel.id,
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
              'discount_pct': item.discountPct,
              'discount_amount': item.purchaseDiscountAmount,
              'net_price': item.purchaseNetPrice,
              'line_total': item.purchaseLineTotal,
            })
        .toList();

    await _client.from('purchase_return_items').insert(itemsPayload);

    // 3. ── STOCK DECREASE: return hua → quantity ghatao ───────────────────
    for (final item in cartItems) {
      await decrementStockQuantity(item.stockId, item.quantity);
    }

    // 4. Add back net_amount to cash counter (cash wapas warehouse mein aaya)
    await addBackToCounter(warehouseId, netAmount);

    // 5. ── COMPANY BALANCE DECREASE: return hua → company ka udhaar ghata ─
    //    Purchase invoice mein creditAmount → company ka balance badha tha
    //    Ab return ho raha hai → company ka balance ghata do
    if (companyId != null && netAmount > 0) {
      final current = await fetchCompanyWithBalance(companyId);
      final currentBal = current?.openingBalance ?? 0;
      // Balance 0 se neeche nahi jayega
      final newBal = (currentBal - netAmount).clamp(0.0, double.infinity);
      await updateCompanyOpeningBalance(companyId, newBal);
    }

    return returnModel;
  }

  // ── Fetch all returns ─────────────────────────────────────────────────────

  Future<List<PurchaseReturnModel>> fetchReturns(String warehouseId) async {
    final res = await _client
        .from('purchase_returns')
        .select('*, companies(name)')
        .eq('warehouse_id', warehouseId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => PurchaseReturnModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Fetch single return with items ────────────────────────────────────────

  Future<PurchaseReturnModel> fetchReturnDetail(String returnId) async {
    final returnRes = await _client
        .from('purchase_returns')
        .select('*, companies(name)')
        .eq('id', returnId)
        .single();

    final itemsRes = await _client
        .from('purchase_return_items')
        .select('''
          *,
          products(article_name),
          sizes(number),
          colors(name),
          brands(name),
          categories(name),
          types(name)
        ''')
        .eq('purchase_return_id', returnId);

    final items = (itemsRes as List)
        .map((e) =>
            PurchaseReturnItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return PurchaseReturnModel.fromJson(
      returnRes as Map<String, dynamic>,
      items: items,
    );
  }
}
