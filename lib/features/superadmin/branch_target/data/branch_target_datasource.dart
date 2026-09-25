import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Din-wise branch targets (`branch_daily_targets`). Dates hamesha calendar
/// date hain (time nahi) aur 'yyyy-MM-dd' ke taur par store hoti hain.
class BranchTargetDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Branch ke [from] ke baad (us din samet) ke saare din-wise targets.
  Future<Map<DateTime, double>> fetchFrom(String branchId, DateTime from) async {
    final res = await _client
        .from('branch_daily_targets')
        .select('target_date, amount')
        .eq('branch_id', branchId)
        .gte('target_date', dateKey(from))
        .order('target_date') as List;
    return {
      for (final r in res.cast<Map<String, dynamic>>())
        DateTime.parse(r['target_date'] as String): (r['amount'] as num).toDouble(),
    };
  }

  /// [targets] upsert karta hai aur [end] ke baad ke purane din hata deta hai
  /// — is tarah end date chhoti karne par extra din bhi saaf ho jate hain.
  Future<void> save(
      String branchId, DateTime end, Map<DateTime, double> targets) async {
    await _client.from('branch_daily_targets').upsert([
      for (final e in targets.entries)
        {
          'branch_id': branchId,
          'target_date': dateKey(e.key),
          'amount': e.value,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
    ], onConflict: 'branch_id,target_date');
    await _client
        .from('branch_daily_targets')
        .delete()
        .eq('branch_id', branchId)
        .gt('target_date', dateKey(end));
  }

  /// Ek din ka har branch ka target — {branchId: amount}. Jis branch ka us
  /// din target set nahi, wo map mein nahi hoga.
  Future<Map<String, double>> fetchForDate(DateTime day) async {
    final res = await _client
        .from('branch_daily_targets')
        .select('branch_id, amount')
        .eq('target_date', dateKey(day)) as List;
    return {
      for (final r in res.cast<Map<String, dynamic>>())
        r['branch_id'].toString(): (r['amount'] as num).toDouble(),
    };
  }
}

final branchTargetDatasourceProvider =
    Provider<BranchTargetDatasource>((_) => BranchTargetDatasource());
