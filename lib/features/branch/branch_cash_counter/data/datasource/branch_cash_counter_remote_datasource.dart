import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/pagination/pagination.dart';
import '../model/branch_cash_counter_model.dart';

/// Search box ka text server filter mein: `dd/mm/yyyy` (ek din), `mm/yyyy`
/// (poora mahina) ya total-sale amount. Din ki hadd Pakistan time (UTC+5)
/// ke hisaab se hai — wahi jis se screen par row ki date dikhti hai.
/// Kuch na samajh aaye to [matchesNothing] true hota hai.
class CashCounterSearch {
  final DateTime? from;
  final DateTime? to;
  final double? totalSale;
  final bool matchesNothing;

  const CashCounterSearch._({
    this.from,
    this.to,
    this.totalSale,
    this.matchesNothing = false,
  });

  static const none = CashCounterSearch._();

  static const _pkt = Duration(hours: 5);

  static DateTime _pktMidnight(int y, int m, int d) =>
      DateTime.utc(y, m, d).subtract(_pkt);

  factory CashCounterSearch.parse(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return none;

    final day = RegExp(r'^(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})$').firstMatch(q);
    if (day != null) {
      final d = int.parse(day.group(1)!);
      final m = int.parse(day.group(2)!);
      final y = int.parse(day.group(3)!);
      if (m < 1 || m > 12 || d < 1 || d > 31) {
        return const CashCounterSearch._(matchesNothing: true);
      }
      final start = _pktMidnight(y, m, d);
      return CashCounterSearch._(
          from: start, to: start.add(const Duration(days: 1)));
    }

    final month = RegExp(r'^(\d{1,2})[/\-.](\d{4})$').firstMatch(q);
    if (month != null) {
      final m = int.parse(month.group(1)!);
      final y = int.parse(month.group(2)!);
      if (m < 1 || m > 12) {
        return const CashCounterSearch._(matchesNothing: true);
      }
      return CashCounterSearch._(
        from: _pktMidnight(y, m, 1),
        to: _pktMidnight(m == 12 ? y + 1 : y, m == 12 ? 1 : m + 1, 1),
      );
    }

    final amount = double.tryParse(q.replaceAll(',', ''));
    if (amount != null) return CashCounterSearch._(totalSale: amount);

    return const CashCounterSearch._(matchesNothing: true);
  }
}

class BranchCashCounterRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  /// Read-only: ek page, newest first. Index (branch_id, created_at DESC) se.
  Future<PageResult<BranchCashCounterModel>> fetchPage(
    PageRequest request, {
    required String branchId,
  }) async {
    final search = CashCounterSearch.parse(request.search);
    if (branchId.isEmpty || search.matchesNothing) {
      return PageResult(rows: const [], totalCount: request.withCount ? 0 : -1);
    }

    var query = _client
        .from('branch_cash_counter')
        .select()
        .eq('branch_id', branchId);
    if (search.from != null) query = query.gte('created_at', search.from!.toIso8601String());
    if (search.to != null) query = query.lt('created_at', search.to!.toIso8601String());
    if (search.totalSale != null) query = query.eq('total_sale', search.totalSale!);

    final page = await runSupabasePage(
      query.order('created_at', ascending: false),
      request: request,
    );
    return page.map(BranchCashCounterModel.fromJson);
  }

  /// Summary cards ke totals — list query se alag, DB-side SUM (RPC).
  Future<BranchCashCounterStats> fetchStats(
    String branchId, {
    String search = '',
  }) async {
    final parsed = CashCounterSearch.parse(search);
    if (branchId.isEmpty || parsed.matchesNothing) {
      return const BranchCashCounterStats();
    }
    final res = await _client.rpc('branch_cash_counter_stats', params: {
      'p_branch_id': branchId,
      'p_from': parsed.from?.toIso8601String(),
      'p_to': parsed.to?.toIso8601String(),
      'p_total_sale': parsed.totalSale,
    });
    return BranchCashCounterStats.fromJson((res as Map).cast<String, dynamic>());
  }
}
