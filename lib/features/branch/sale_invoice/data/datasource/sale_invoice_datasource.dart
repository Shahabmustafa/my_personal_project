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
        .select('id, printer_heads(*)')
        .eq('branch_id', branchId);
    return (res as List).map((e) {
      return PrinterLookupItem.fromHead(
        e['id'].toString(),
        e['printer_heads'] as Map<String, dynamic>?,
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
    final hasB1g1 = cartItems.any((i) => i.isB1g1);
    final itemsPayload = cartItems
        .map((item) => {
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
              'discount': item.discountAmount * item.quantity + item.b1g1Discount,
              'total_price': item.lineTotal,
              if (hasB1g1) ...{
                'is_b1g1': item.isB1g1,
                'b1g1_free_qty': item.b1g1FreeQty,
                'b1g1_offer_id': item.b1g1OfferId,
              },
            })
        .toList();

    // Invoice + items + payments ek hi DB transaction mein (RPC) — kuch bhi
    // fail ho to poora rollback, bina items wala invoice nahi bachta.
    final invoiceRes = await _client.rpc('save_sale_invoice', params: {
      'p_invoice': {
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
      },
      'p_items': itemsPayload,
      'p_payments': payments
          .map((p) => {
                'branch_id': branchId,
                'bank_entry_id': p.bankEntryId,
                'payment_type': p.type,
                'amount': p.amount,
              })
          .toList(),
    });

    final invoice =
        SaleInvoiceModel.fromJson(Map<String, dynamic>.from(invoiceRes as Map));

    return invoice;
  }

  // ── Fetch invoices ───────────────────────────────────────────────────────

  static const _invoiceSelect =
      '*, sale_invoice_payments(payment_type, amount), customers(name), '
      'sale_returns(id, total_amount), sale_exchanges(id, difference_amount)';

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

  /// Sab branches ki ek din ki invoices (poore detail ke sath: payments,
  /// returns, exchanges, branch ka naam) — Sale Exchange ki list ke liye.
  /// [from] .. [to) device ke local din ki hadd hai, jo list mein date ke
  /// roop mein dikhti hai. [search] ho to invoice number se (ilike) kisi bhi
  /// din ki invoices — date ignore, naye pehle, 50 tak.
  Future<List<SaleInvoiceModel>> fetchAllBranchInvoicesByDate(
      DateTime from, DateTime to,
      {String search = ''}) async {
    var query = _client
        .from('sale_invoices')
        .select('$_invoiceSelect, branches(branch_name)');
    final q = search.replaceAll(RegExp(r'[,()%*"\\]'), ' ').trim();
    final res = q.isEmpty
        ? await query
            .gte('created_at', from.toUtc().toIso8601String())
            .lt('created_at', to.toUtc().toIso8601String())
            .order('created_at', ascending: false)
        : await query
            .ilike('invoice_number', '%$q%')
            .order('created_at', ascending: false)
            .limit(50);

    return (res as List)
        .map((e) => SaleInvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Sab branches ki invoices — Sale Return ke invoice dropdown ke liye
  /// (customer kisi bhi branch ka maal kisi bhi branch mein wapas kar sakta
  /// hai). Sirf dropdown ke liye zaroori columns + branch ka naam.
  Future<List<SaleInvoiceModel>> fetchAllBranchInvoices() async {
    final res = await _client
        .from('sale_invoices')
        .select('id, invoice_number, branch_id, created_at, branches(branch_name)')
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => SaleInvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Sirf logged-in salesman ke apne invoices — salesman dashboard ki
  /// "My Sales" screen ke liye.
  Future<List<SaleInvoiceModel>> fetchInvoicesBySalesman(
      String branchId, String salesmanId) async {
    final res = await _client
        .from('sale_invoices')
        .select(_invoiceSelect)
        .eq('branch_id', branchId)
        .eq('salesman_id', salesmanId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => SaleInvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Sirf jin invoices par logged-in manager assign hai — manager ki
  /// "My Sales" screen ke liye (manager commission ke sath).
  Future<List<SaleInvoiceModel>> fetchInvoicesByManager(
      String branchId, String managerId) async {
    final res = await _client
        .from('sale_invoices')
        .select(_invoiceSelect)
        .eq('branch_id', branchId)
        .eq('manager_id', managerId)
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
      invoiceRes,
      items: items,
    );
  }

  /// Invoice ki har line (sale_invoice_items.id) ka kitna stock pehle hi
  /// return ya exchange ho chuka hai. Return items mein original line ka
  /// link nahi hota, is liye wo branch_stock_id se match hote hain; exchange
  /// ke return items seedha original_sale_invoice_item_id rakhte hain.
  Future<Map<String, int>> fetchReturnedQuantities(
      SaleInvoiceModel invoice) async {
    final results = await Future.wait([
      _client
          .from('sale_returns')
          .select('sale_return_items(branch_stock_id, quantity)')
          .eq('original_invoice_id', invoice.id),
      _client
          .from('sale_exchanges')
          .select('sale_exchange_return_items(original_sale_invoice_item_id, quantity)')
          .eq('original_invoice_id', invoice.id),
    ]);

    final returned = <String, int>{};

    // Exchange — seedha line id se.
    for (final ex in results[1] as List) {
      for (final r in ((ex as Map)['sale_exchange_return_items'] as List? ?? const [])) {
        final id = (r as Map)['original_sale_invoice_item_id']?.toString();
        if (id == null) continue;
        returned[id] = (returned[id] ?? 0) + ((r['quantity'] as num?)?.toInt() ?? 0);
      }
    }

    // Return — branch_stock_id se, us stock wali lines par baari baari
    // (jitni jagah bachi ho) baant do.
    final byStock = <String, int>{};
    for (final ret in results[0] as List) {
      for (final r in ((ret as Map)['sale_return_items'] as List? ?? const [])) {
        final sid = (r as Map)['branch_stock_id']?.toString();
        if (sid == null) continue;
        byStock[sid] = (byStock[sid] ?? 0) + ((r['quantity'] as num?)?.toInt() ?? 0);
      }
    }
    for (final item in invoice.items) {
      final left = byStock[item.branchStockId] ?? 0;
      if (left <= 0) continue;
      final room = item.quantity - (returned[item.id] ?? 0);
      final take = left < room ? left : room;
      if (take <= 0) continue;
      returned[item.id] = (returned[item.id] ?? 0) + take;
      byStock[item.branchStockId] = left - take;
    }
    return returned;
  }
}
