import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/sale_exchange_model.dart';

class SaleExchangeDatasource {
  final SupabaseClient _client;
  SaleExchangeDatasource(this._client);

  Future<String> generateExchangeNumber() async {
    final res = await _client.rpc('generate_sale_exchange_number');
    return res as String;
  }

  // ── Save exchange: header + return items + new items + payment(s) ───────
  // Stock sync (return items add stock back, new items subtract), cash
  // counter sync (received_amount_in_exchange / return_amount_in_exchange)
  // aur salesman commission sync sab database triggers khud handle karte
  // hain (sale_exchange supabase_migration.sql) — bilkul sale_invoice /
  // sale_return ke triggers jaisa.

  Future<SaleExchangeModel> saveExchange({
    required String exchangeNumber,
    required String branchId,
    String? originalInvoiceId,
    String? printerId,
    String? cashierId,
    String? customerId,
    String? salesmanId,
    required double returnSubtotal,
    required double returnDiscount,
    required double returnTotal,
    required double newSubtotal,
    required double newDiscount,
    required double newTotal,
    required double differenceAmount,
    required double salesmanCommissionPercent,
    required double salesmanCommissionAmount,
    String? note,
    required List<ReturnCartItem> returnItems,
    required List<SaleCartItem> newItems,
    required List<ExchangePaymentInput> payments,
  }) async {
    final exchangeRes = await _client
        .from('sale_exchanges')
        .insert({
          'exchange_number': exchangeNumber,
          'branch_id': branchId,
          'original_invoice_id': originalInvoiceId,
          'printer_id': printerId,
          'cashier_id': cashierId,
          'customer_id': customerId,
          'salesman_id': salesmanId,
          'return_subtotal': returnSubtotal,
          'return_discount': returnDiscount,
          'return_total': returnTotal,
          'new_subtotal': newSubtotal,
          'new_discount': newDiscount,
          'new_total': newTotal,
          'difference_amount': differenceAmount,
          'salesman_commission_percent': salesmanCommissionPercent,
          'salesman_commission_amount': salesmanCommissionAmount,
          'note': note,
        })
        .select()
        .single();

    final exchange = SaleExchangeModel.fromJson(exchangeRes);

    if (returnItems.isNotEmpty) {
      await _client.from('sale_exchange_return_items').insert(
            returnItems
                .map((item) => {
                      'sale_exchange_id': exchange.id,
                      'branch_id': branchId,
                      'branch_stock_id': item.branchStockId,
                      'original_sale_invoice_item_id': item.originalItemId,
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
                .toList(),
          );
    }

    if (newItems.isNotEmpty) {
      await _client.from('sale_exchange_new_items').insert(
            newItems
                .map((item) => {
                      'sale_exchange_id': exchange.id,
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
                .toList(),
          );
    }

    if (payments.isNotEmpty) {
      await _client.from('sale_exchange_payments').insert(
            payments
                .map((p) => {
                      'sale_exchange_id': exchange.id,
                      'branch_id': branchId,
                      'bank_entry_id': p.bankEntryId,
                      'direction': p.direction,
                      'payment_type': p.type,
                      'amount': p.amount,
                    })
                .toList(),
          );
    }

    return exchange;
  }

  // ── Fetch exchanges ──────────────────────────────────────────────────────

  static const _exchangeSelect =
      '*, sale_exchange_payments(direction, payment_type, amount), customers(name), sale_invoices(invoice_number)';

  Future<List<SaleExchangeModel>> fetchExchanges(String branchId) async {
    final res = await _client
        .from('sale_exchanges')
        .select(_exchangeSelect)
        .eq('branch_id', branchId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => SaleExchangeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
