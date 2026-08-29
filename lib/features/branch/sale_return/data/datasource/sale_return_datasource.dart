import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/sale_return_model.dart';

class SaleReturnDatasource {
  final SupabaseClient _client;
  SaleReturnDatasource(this._client);

  Future<String> generateReturnNumber() async {
    final res = await _client.rpc('generate_sale_return_number');
    return res as String;
  }

  // ── Save sale return + items + refund payments ────────────────────────
  // Stock addition aur cash counter update sab database triggers khud
  // handle karte hain (sale_return supabase_migration.sql) — bilkul sale
  // invoice ke trigger jaisa, sirf vice versa.

  Future<SaleReturnModel> saveSaleReturn({
    required String returnNumber,
    required String branchId,
    String? originalInvoiceId,
    String? printerId,
    String? cashierId,
    required String customerId,
    String? salesmanId,
    required double subtotal,
    required double totalDiscount,
    required double totalAmount,
    String? note,
    required List<SaleCartItem> cartItems,
    required List<PaymentInput> payments,
  }) async {
    final returnRes = await _client
        .from('sale_returns')
        .insert({
          'return_number': returnNumber,
          'branch_id': branchId,
          'original_invoice_id': originalInvoiceId,
          'printer_id': printerId,
          'cashier_id': cashierId,
          'customer_id': customerId,
          'salesman_id': salesmanId,
          'subtotal': subtotal,
          'total_discount': totalDiscount,
          'total_amount': totalAmount,
          'note': note,
        })
        .select()
        .single();

    final saleReturn = SaleReturnModel.fromJson(returnRes as Map<String, dynamic>);

    final itemsPayload = cartItems
        .map((item) => {
              'sale_return_id': saleReturn.id,
              'branch_id': branchId,
              'branch_stock_id': item.branchStockId,
              'product_id': item.productId,
              'size_id': item.sizeId,
              'color_id': item.colorId,
              'brand_id': item.brandId,
              'category_id': item.categoryId,
              'type_id': item.typeId,
              'barcode': item.barcode,
              'quantity': item.quantity,
              'sale_price': item.salePrice,
              'purchase_price': item.purchasePrice,
              'discount_pct': item.discountPct,
              'discount': item.discountAmount * item.quantity,
              'total_price': item.lineTotal,
            })
        .toList();

    await _client.from('sale_return_items').insert(itemsPayload);

    await _client.from('sale_return_payments').insert(
          payments
              .map((p) => {
                    'sale_return_id': saleReturn.id,
                    'branch_id': branchId,
                    'bank_entry_id': p.bankEntryId,
                    'payment_type': p.type,
                    'amount': p.amount,
                  })
              .toList(),
        );

    return saleReturn;
  }

  // ── Fetch returns ────────────────────────────────────────────────────

  static const _returnSelect =
      '*, sale_return_payments(payment_type, amount), customers(name), '
      'sale_invoices(invoice_number)';

  Future<List<SaleReturnModel>> fetchReturns(String branchId) async {
    final res = await _client
        .from('sale_returns')
        .select(_returnSelect)
        .eq('branch_id', branchId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => SaleReturnModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
