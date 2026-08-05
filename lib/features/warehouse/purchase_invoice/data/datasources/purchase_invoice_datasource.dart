import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/purchase_invoice_model.dart';
import '../models/warehouse_stock_model.dart';

class PurchaseInvoiceDatasource {
  final SupabaseClient _client;

  PurchaseInvoiceDatasource(this._client);

  // Products join now includes sale_price and purchase_price
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

  // ── Generate next invoice number ──────────────────────────────────────────
  Future<String> generateInvoiceNumber() async {
    final res = await _client.rpc('generate_purchase_invoice_number');
    return res as String;
  }

  // ── Fetch all stock for a warehouse ───────────────────────────────────────
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

  // ── Fetch all companies ───────────────────────────────────────────────────
  Future<List<StockLookupItem>> fetchCompanies() async {
    final res =
        await _client.from('companies').select('id, name').order('name');
    return (res as List)
        .map((e) =>
            StockLookupItem(id: e['id'] as String, label: e['name'] as String))
        .toList();
  }

  // ── Save purchase invoice + items ─────────────────────────────────────────
  Future<PurchaseInvoiceModel> savePurchaseInvoice({
    required String invoiceNumber,
    required String warehouseId,
    String? companyId,
    required double totalAmount,
    required double totalDiscount,
    required double netAmount,
    required List<PurchaseCartItem> cartItems,
    String? notes,
  }) async {
    // 1. Insert invoice header
    final invoiceRes = await _client
        .from('purchase_invoices')
        .insert({
          'invoice_number': invoiceNumber,
          'company_id': companyId,
          'warehouse_id': warehouseId,
          'total_amount': totalAmount,
          'total_discount': totalDiscount,
          'net_amount': netAmount,
          'notes': notes,
        })
        .select('*, companies(name)')
        .single();

    final invoice = PurchaseInvoiceModel.fromJson(
        invoiceRes as Map<String, dynamic>);

    // 2. Insert line items
    final itemsPayload = cartItems
        .map((item) => {
              'purchase_invoice_id': invoice.id,
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
              'discount_amount': item.discountAmount,
              'net_price': item.netPrice,
              'line_total': item.lineTotal,
            })
        .toList();

    await _client.from('purchase_invoice_items').insert(itemsPayload);

    return invoice;
  }

  // ── Fetch all invoices ────────────────────────────────────────────────────
  Future<List<PurchaseInvoiceModel>> fetchInvoices(
      String warehouseId) async {
    final res = await _client
        .from('purchase_invoices')
        .select('*, companies(name)')
        .eq('warehouse_id', warehouseId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => PurchaseInvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Fetch single invoice with items ──────────────────────────────────────
  Future<PurchaseInvoiceModel> fetchInvoiceDetail(String invoiceId) async {
    final invoiceRes = await _client
        .from('purchase_invoices')
        .select('*, companies(name)')
        .eq('id', invoiceId)
        .single();

    final itemsRes = await _client
        .from('purchase_invoice_items')
        .select('''
          *,
          products(article_name),
          sizes(number),
          colors(name),
          brands(name),
          categories(name),
          types(name)
        ''')
        .eq('purchase_invoice_id', invoiceId);

    final items = (itemsRes as List)
        .map((e) =>
            PurchaseInvoiceItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return PurchaseInvoiceModel.fromJson(
      invoiceRes as Map<String, dynamic>,
      items: items,
    );
  }
}
