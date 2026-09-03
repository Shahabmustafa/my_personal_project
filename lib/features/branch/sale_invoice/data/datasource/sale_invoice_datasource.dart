import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/sale_invoice_model.dart';

class SaleInvoiceDatasource {
  final SupabaseClient _client;
  SaleInvoiceDatasource(this._client);

  // ── Invoice number ────────────────────────────────────────────────────────

  Future<String> generateInvoiceNumber() async {
    final res = await _client.rpc('generate_sale_invoice_number');
    return res as String;
  }

  // ── Lookups ───────────────────────────────────────────────────────────────

  Future<List<EmployeeLookupItem>> fetchEmployees(
      String branchId, String role) async {
    final res = await _client
        .from('employee_salary')
        .select('id, user_id, commission_percent, users!inner(username, role)')
        .eq('branch_id', branchId)
        .eq('users.role', role);
    return (res as List).map((e) {
      final user = e['users'] as Map<String, dynamic>?;
      return EmployeeLookupItem(
        id: e['id'].toString(),
        userId: e['user_id']?.toString() ?? '',
        name: user?['username']?.toString() ?? '',
        role: user?['role']?.toString() ?? role,
        commissionPercent:
            (e['commission_percent'] as num? ?? 0).toDouble(),
      );
    }).toList();
  }

  Future<List<BankEntryLookupItem>> fetchBankEntries(String branchId) async {
    final res = await _client
        .from('bank_entries')
        .select('id, account_number, bank_heads(bank_name)')
        .eq('branch_id', branchId);
    return (res as List).map((e) {
      final bank = e['bank_heads'] as Map<String, dynamic>?;
      final name = bank?['bank_name']?.toString() ?? 'Bank';
      final acc = e['account_number']?.toString() ?? '';
      return BankEntryLookupItem(
        id: e['id'].toString(),
        label: acc.isEmpty ? name : '$name — $acc',
      );
    }).toList();
  }

  Future<List<PrinterLookupItem>> fetchPrinters(String branchId) async {
    final res = await _client
        .from('assign_printer')
        .select('id, printer_heads(name, address, phone_number, image_url)')
        .eq('branch_id', branchId);
    return (res as List).map((e) {
      final printer = e['printer_heads'] as Map<String, dynamic>?;
      return PrinterLookupItem(
        id: e['id'].toString(),
        label: printer?['name']?.toString() ?? 'Printer',
        address: printer?['address']?.toString() ?? '',
        phoneNumber: printer?['phone_number']?.toString() ?? '',
        imageUrl: printer?['image_url']?.toString() ?? '',
      );
    }).toList();
  }

  /// Branch ka (ek hi) manager — role='manager', employee_salary se resolve.
  Future<EmployeeLookupItem?> fetchBranchManager(String branchId) async {
    final list = await fetchEmployees(branchId, 'manager');
    return list.isNotEmpty ? list.first : null;
  }

  // ── Save sale invoice + items + payment ─────────────────────────────────
  // Stock deduction, cash counter update aur commission sync sab
  // database triggers khud handle karte hain (sale_invoice supabase_migration.sql).

  Future<SaleInvoiceModel> saveSaleInvoice({
    required String invoiceNumber,
    required String branchId,
    String? printerId,
    String? cashierId,
    required String customerId,
    String? salesmanId,
    String? managerId,
    required double subtotal,
    required double totalDiscount,
    double invoiceDiscount = 0,
    required double totalAmount,
    required double salesmanCommissionPercent,
    required double salesmanCommissionAmount,
    required double managerCommissionPercent,
    required double managerCommissionAmount,
    String? note,
    required List<SaleCartItem> cartItems,
    required List<PaymentInput> payments,
  }) async {
    final invoiceRes = await _client
        .from('sale_invoices')
        .insert({
          'invoice_number': invoiceNumber,
          'branch_id': branchId,
          'printer_id': printerId,
          'cashier_id': cashierId,
          'customer_id': customerId,
          'salesman_id': salesmanId,
          'manager_id': managerId,
          'subtotal': subtotal,
          'total_discount': totalDiscount,
          'invoice_discount': invoiceDiscount,
          'total_amount': totalAmount,
          'salesman_commission_percent': salesmanCommissionPercent,
          'salesman_commission_amount': salesmanCommissionAmount,
          'manager_commission_percent': managerCommissionPercent,
          'manager_commission_amount': managerCommissionAmount,
          'note': note,
        })
        .select()
        .single();

    final invoice = SaleInvoiceModel.fromJson(invoiceRes as Map<String, dynamic>);

    final itemsPayload = cartItems
        .map((item) => {
              'sale_invoice_id': invoice.id,
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

    await _client.from('sale_invoice_items').insert(itemsPayload);

    await _client.from('sale_invoice_payments').insert(
          payments
              .map((p) => {
                    'sale_invoice_id': invoice.id,
                    'branch_id': branchId,
                    'bank_entry_id': p.bankEntryId,
                    'payment_type': p.type,
                    'amount': p.amount,
                  })
              .toList(),
        );

    return invoice;
  }

  // ── Fetch invoices ───────────────────────────────────────────────────────

  static const _invoiceSelect =
      '*, sale_invoice_payments(payment_type, amount), customers(name), '
      'sale_returns(id), sale_exchanges(id)';

  Future<List<SaleInvoiceModel>> fetchInvoices(String branchId) async {
    final res = await _client
        .from('sale_invoices')
        .select(_invoiceSelect)
        .eq('branch_id', branchId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => SaleInvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SaleInvoiceModel> fetchInvoiceDetail(String invoiceId) async {
    final invoiceRes = await _client
        .from('sale_invoices')
        .select(_invoiceSelect)
        .eq('id', invoiceId)
        .single();

    final itemsRes = await _client
        .from('sale_invoice_items')
        .select('''
          *,
          products(article_name),
          sizes(number),
          colors(name),
          brands(name),
          categories(name),
          types(name)
        ''')
        .eq('sale_invoice_id', invoiceId);

    final items = (itemsRes as List)
        .map((e) => SaleInvoiceItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return SaleInvoiceModel.fromJson(
      invoiceRes as Map<String, dynamic>,
      items: items,
    );
  }
}
