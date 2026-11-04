import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MonthlySale {
  final DateTime month;
  final double amount;
  final int invoices;
  const MonthlySale(this.month, this.amount, this.invoices);
}

typedef CustomerSalesKey = ({String customerId, String branchId});

/// Pichle 12 mahine (current month samet) ki month-wise sale — purane se naye.
final customerMonthlySalesProvider = FutureProvider.autoDispose
    .family<List<MonthlySale>, CustomerSalesKey>((ref, key) async {
  final now = DateTime.now();
  final first = DateTime(now.year, now.month - 11, 1);

  final rows = await Supabase.instance.client
      .from('sale_invoices')
      .select('total_amount, created_at')
      .eq('customer_id', key.customerId)
      .eq('branch_id', key.branchId)
      .gte('created_at', first.toUtc().toIso8601String());

  final amounts = <int, double>{};
  final counts = <int, int>{};
  for (final r in rows as List) {
    final d = DateTime.parse(r['created_at'] as String).toLocal();
    final k = d.year * 12 + d.month;
    amounts[k] = (amounts[k] ?? 0) + ((r['total_amount'] as num?)?.toDouble() ?? 0);
    counts[k] = (counts[k] ?? 0) + 1;
  }

  return List.generate(12, (i) {
    final m = DateTime(first.year, first.month + i, 1);
    final k = m.year * 12 + m.month;
    return MonthlySale(m, amounts[k] ?? 0, counts[k] ?? 0);
  });
});
