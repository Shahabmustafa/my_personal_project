import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../branch/sale_exchange/data/model/sale_exchange_model.dart';
import '../../../../branch/sale_invoice/data/model/sale_invoice_model.dart';
import '../../../../branch/sale_return/data/model/sale_return_model.dart';
import '../model/report_page_result.dart';

/// Admin-side reports — sab branches ka data (koi branch_id filter nahi),
/// optional start/end date range ke sath. Har method do queries chalata hai:
/// ek halki "totals" query (poori filtered list, sirf jitne columns totals
/// ke liye chahiye) aur ek "page" query (`.range()` se server-side
/// paginated, full embeds ke sath — table mein dikhane ke liye).
class SaleReportDatasource {
  final SupabaseClient _client;
  SaleReportDatasource(this._client);

  /// Local (Asia/Karachi) calendar date ko us din ki shuruat ka UTC instant
  /// deta hai (Karachi = UTC+5, is liye local midnight = UTC 19:00 pichla din).
  static DateTime _startOfDayUtc(DateTime local) =>
      DateTime.utc(local.year, local.month, local.day).subtract(const Duration(hours: 5));

  /// Agle din ki shuruat ka UTC instant — exclusive upper bound ke liye.
  static DateTime _startOfNextDayUtc(DateTime local) =>
      _startOfDayUtc(local.add(const Duration(days: 1)));

  PostgrestFilterBuilder<T> _applyDateRange<T>(
    PostgrestFilterBuilder<T> query,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    var q = query;
    if (startDate != null) {
      q = q.gte('created_at', _startOfDayUtc(startDate).toIso8601String());
    }
    if (endDate != null) {
      q = q.lt('created_at', _startOfNextDayUtc(endDate).toIso8601String());
    }
    return q;
  }

  // ── Printer lookup (logo/address/phone header when printing a report row) ──
  // Report print buttons don't have a printer picker like the branch POS
  // screens do, so this resolves whichever printer is assigned to the
  // invoice/return/exchange's own branch and uses that for the receipt header.

  Future<PrinterLookupItem?> fetchBranchPrinter(String branchId) async {
    final res = await _client
        .from('assign_printer')
        .select('id, printer_heads(name, address, phone_number, image_url)')
        .eq('branch_id', branchId)
        .limit(1);
    final rows = res as List;
    if (rows.isEmpty) return null;
    final row = rows.first as Map<String, dynamic>;
    final printer = row['printer_heads'] as Map<String, dynamic>?;
    return PrinterLookupItem(
      id: row['id'].toString(),
      label: printer?['name']?.toString() ?? 'Printer',
      address: printer?['address']?.toString() ?? '',
      phoneNumber: printer?['phone_number']?.toString() ?? '',
      imageUrl: printer?['image_url']?.toString() ?? '',
    );
  }

  // ── Sale Invoice report ──────────────────────────────────────────────────

  static const _itemProductJoin =
      'quantity, sale_price, discount, total_price, '
      'products(article_name), sizes(number), colors(name)';

  static const _invoiceSelect =
      '*, sale_invoice_payments(payment_type, amount), sale_invoice_items($_itemProductJoin), '
      'customers(name), branches(branch_name)';

  Future<ReportPageResult<SaleInvoiceModel>> fetchInvoiceReport({
    DateTime? startDate,
    DateTime? endDate,
    required int page,
    required int pageSize,
  }) async {
    final totalsRes = await _applyDateRange(
      _client.from('sale_invoices').select('total_amount, sale_invoice_items(quantity)'),
      startDate,
      endDate,
    );
    final totalsList = totalsRes as List;
    var totalQuantity = 0;
    var totalAmount = 0.0;
    for (final row in totalsList) {
      final r = row as Map<String, dynamic>;
      totalAmount += (r['total_amount'] as num? ?? 0).toDouble();
      final items = (r['sale_invoice_items'] as List?) ?? const [];
      for (final it in items) {
        totalQuantity += ((it as Map<String, dynamic>)['quantity'] as num? ?? 0).toInt();
      }
    }

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final pageRes = await _applyDateRange(
      _client.from('sale_invoices').select(_invoiceSelect),
      startDate,
      endDate,
    ).order('created_at', ascending: false).range(from, to);

    final rows = (pageRes as List)
        .map((e) => SaleInvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReportPageResult(
      rows: rows,
      totalCount: totalsList.length,
      totalQuantity: totalQuantity,
      totalAmount: totalAmount,
    );
  }

  // ── Sale Return report ───────────────────────────────────────────────────

  static const _returnSelect =
      '*, sale_return_payments(payment_type, amount), sale_return_items($_itemProductJoin), '
      'customers(name), branches(branch_name), sale_invoices(invoice_number)';

  Future<ReportPageResult<SaleReturnModel>> fetchReturnReport({
    DateTime? startDate,
    DateTime? endDate,
    required int page,
    required int pageSize,
  }) async {
    final totalsRes = await _applyDateRange(
      _client.from('sale_returns').select('total_amount, sale_return_items(quantity)'),
      startDate,
      endDate,
    );
    final totalsList = totalsRes as List;
    var totalQuantity = 0;
    var totalAmount = 0.0;
    for (final row in totalsList) {
      final r = row as Map<String, dynamic>;
      totalAmount += (r['total_amount'] as num? ?? 0).toDouble();
      final items = (r['sale_return_items'] as List?) ?? const [];
      for (final it in items) {
        totalQuantity += ((it as Map<String, dynamic>)['quantity'] as num? ?? 0).toInt();
      }
    }

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final pageRes = await _applyDateRange(
      _client.from('sale_returns').select(_returnSelect),
      startDate,
      endDate,
    ).order('created_at', ascending: false).range(from, to);

    final rows = (pageRes as List)
        .map((e) => SaleReturnModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReportPageResult(
      rows: rows,
      totalCount: totalsList.length,
      totalQuantity: totalQuantity,
      totalAmount: totalAmount,
    );
  }

  // ── Sale Exchange report ─────────────────────────────────────────────────
  // "Quantity"/"Sale" yahan naye (exchange mein diye gaye) items se liya
  // jata hai — wahi customer asal mein le kar ja raha hai.

  static const _exchangeSelect =
      '*, sale_exchange_payments(direction, payment_type, amount), '
      'sale_exchange_return_items($_itemProductJoin), sale_exchange_new_items($_itemProductJoin), '
      'customers(name), branches(branch_name), sale_invoices(invoice_number)';

  Future<ReportPageResult<SaleExchangeModel>> fetchExchangeReport({
    DateTime? startDate,
    DateTime? endDate,
    required int page,
    required int pageSize,
  }) async {
    final totalsRes = await _applyDateRange(
      _client.from('sale_exchanges').select('new_total, sale_exchange_new_items(quantity)'),
      startDate,
      endDate,
    );
    final totalsList = totalsRes as List;
    var totalQuantity = 0;
    var totalAmount = 0.0;
    for (final row in totalsList) {
      final r = row as Map<String, dynamic>;
      totalAmount += (r['new_total'] as num? ?? 0).toDouble();
      final items = (r['sale_exchange_new_items'] as List?) ?? const [];
      for (final it in items) {
        totalQuantity += ((it as Map<String, dynamic>)['quantity'] as num? ?? 0).toInt();
      }
    }

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final pageRes = await _applyDateRange(
      _client.from('sale_exchanges').select(_exchangeSelect),
      startDate,
      endDate,
    ).order('created_at', ascending: false).range(from, to);

    final rows = (pageRes as List)
        .map((e) => SaleExchangeModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReportPageResult(
      rows: rows,
      totalCount: totalsList.length,
      totalQuantity: totalQuantity,
      totalAmount: totalAmount,
    );
  }
}
