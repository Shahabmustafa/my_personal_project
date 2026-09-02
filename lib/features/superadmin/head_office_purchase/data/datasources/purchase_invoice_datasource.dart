import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/purchase_invoice_model.dart';
import '../models/purchase_return_model.dart';
import '../models/warehouse_stock_model.dart';
// ignore_for_file: unused_import

/// Head office purchase invoice datasource — warehouse ke baghair.
/// Stock: public.stock_inventory  |  Invoices: public.ho_purchase_invoices
class PurchaseInvoiceDatasource {
  final SupabaseClient _client;

  PurchaseInvoiceDatasource(this._client);

  static const _stockJoin = '''
    *,
    products(article_name, sale_price, purchase_price),
    sizes(number),
    brands(name),
    companies(name),
    colors(name),
    categories(name),
    types(name)
  ''';

  // ── Cash Counter ──────────────────────────────────────────────────────────

  Future<WarehouseCashCounter> getOrCreateCounter() async {
    final res = await _client.rpc('get_or_create_ho_counter');
    return WarehouseCashCounter.fromJson(res as Map<String, dynamic>);
  }

  Future<void> deductFromCounter(double paidAmount) async {
    final counter = await getOrCreateCounter();
    await _client.from('head_office_cash_counter').update({
      'net_amount': counter.netAmount - paidAmount,
      'total_purchase': counter.totalPurchase + paidAmount,
    }).eq('id', counter.id);
  }

  // ── Generate invoice number ───────────────────────────────────────────────

  Future<String> generateInvoiceNumber() async {
    final res = await _client
        .from('ho_purchase_invoices')
        .select('invoice_number')
        .like('invoice_number', 'Pur-%');

    int maxNumber = 0;
    for (final row in res as List) {
      final inv = row['invoice_number'] as String? ?? '';
      final dashIndex = inv.lastIndexOf('-');
      if (dashIndex != -1) {
        final n = int.tryParse(inv.substring(dashIndex + 1)) ?? 0;
        if (n > maxNumber) maxNumber = n;
      }
    }
    return 'Pur-${(maxNumber + 1).toString().padLeft(6, '0')}';
  }

  // ── Fetch all head office stock ───────────────────────────────────────────

  Future<List<WarehouseStockModel>> fetchWarehouseStock() async {
    final response =
        await _client.from('stock_inventory').select(_stockJoin);

    return (response as List)
        .map((e) => WarehouseStockModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Fetch stock by barcode ────────────────────────────────────────────────

  Future<WarehouseStockModel?> fetchStockByBarcode(String barcode) async {
    final res = await _client
        .from('stock_inventory')
        .select(_stockJoin)
        .eq('barcode', barcode)
        .maybeSingle();

    if (res == null) return null;
    return WarehouseStockModel.fromJson(res);
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

  // ── Fetch company with balance ────────────────────────────────────────────

  Future<CompanyWithBalance?> fetchCompanyWithBalance(String companyId) async {
    final res = await _client
        .from('companies')
        .select('id, name, opening_balance')
        .eq('id', companyId)
        .maybeSingle();
    if (res == null) return null;
    return CompanyWithBalance.fromJson(res);
  }

  // ── Update company opening_balance ────────────────────────────────────────

  Future<void> updateCompanyOpeningBalance(
      String companyId, double newBalance) async {
    await _client
        .from('companies')
        .update({'opening_balance': newBalance}).eq('id', companyId);
  }

  // ── Increment stock quantity (purchase → stock masuk) ─────────────────────

  Future<void> incrementStockQuantity(String stockId, int qty) async {
    final res = await _client
        .from('stock_inventory')
        .select('quantity')
        .eq('id', stockId)
        .single();
    final currentQty = (res['quantity'] as int? ?? 0);
    await _client
        .from('stock_inventory')
        .update({'quantity': currentQty + qty}).eq('id', stockId);
  }

  // ── Save purchase invoice + items ─────────────────────────────────────────

  Future<PurchaseInvoiceModel> savePurchaseInvoice({
    required String invoiceNumber,
    String? companyId,
    required double totalAmount,
    required double totalDiscount,
    required double netAmount,
    required double paidAmount,
    required double creditAmount,
    required String paymentMode,
    required List<PurchaseCartItem> cartItems,
    String? notes,
  }) async {
    final invoiceRes = await _client
        .from('ho_purchase_invoices')
        .insert({
          'invoice_number': invoiceNumber,
          'company_id': companyId,
          'total_amount': totalAmount,
          'total_discount': totalDiscount,
          'net_amount': netAmount,
          'paid_amount': paidAmount,
          'credit_amount': creditAmount,
          'payment_mode': paymentMode,
          'notes': notes,
        })
        .select('*, companies(name)')
        .single();

    final invoice = PurchaseInvoiceModel.fromJson(invoiceRes);

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
              'discount_amount': item.purchaseDiscountAmount,
              'net_price': item.purchaseNetPrice,
              'line_total': item.purchaseLineTotal,
            })
        .toList();

    await _client.from('ho_purchase_invoice_items').insert(itemsPayload);

    // STOCK INCREASE
    for (final item in cartItems) {
      await incrementStockQuantity(item.stockId, item.quantity);
    }

    // Deduct paid amount from cash counter
    if (paidAmount > 0) {
      await deductFromCounter(paidAmount);
    }

    // Add credit amount to company opening_balance
    if (creditAmount > 0 && companyId != null) {
      final current = await fetchCompanyWithBalance(companyId);
      final newBal = (current?.openingBalance ?? 0) + creditAmount;
      await updateCompanyOpeningBalance(companyId, newBal);
    }

    return invoice;
  }

  // ── Fetch all invoices ────────────────────────────────────────────────────

  Future<List<PurchaseInvoiceModel>> fetchInvoices() async {
    final res = await _client
        .from('ho_purchase_invoices')
        .select('*, companies(name)')
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => PurchaseInvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Fetch single invoice with items ──────────────────────────────────────

  Future<PurchaseInvoiceModel> fetchInvoiceDetail(String invoiceId) async {
    final invoiceRes = await _client
        .from('ho_purchase_invoices')
        .select('*, companies(name)')
        .eq('id', invoiceId)
        .single();

    final itemsRes = await _client
        .from('ho_purchase_invoice_items')
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

    return PurchaseInvoiceModel.fromJson(invoiceRes, items: items);
  }
}
