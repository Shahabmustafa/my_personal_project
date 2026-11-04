import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ek employee ka is mahine (1 tareekh se ab tak) ka sale summary + contact.
class EmployeeDetail {
  final String email;
  final String phone;
  final bool isActive;
  final int invoices;
  final int pairs;
  final double saleAmount;
  final double commissionEarned;

  const EmployeeDetail({
    this.email = '',
    this.phone = '',
    this.isActive = true,
    this.invoices = 0,
    this.pairs = 0,
    this.saleAmount = 0,
    this.commissionEarned = 0,
  });
}

typedef EmployeeDetailKey = ({String userId, String branchId});

double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

final employeeDetailProvider =
    FutureProvider.autoDispose.family<EmployeeDetail, EmployeeDetailKey>((ref, key) async {
  final client = Supabase.instance.client;
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1).toUtc().toIso8601String();
  final uid = key.userId;

  final user = await client
      .from('users')
      .select('email, phone_number, is_active')
      .eq('id', uid)
      .maybeSingle();

  final rows = await client
      .from('sale_invoices')
      .select('total_amount, salesman_id, manager_id, cashier_id, '
          'salesman_commission_amount, manager_commission_amount, '
          'sale_invoice_items(quantity)')
      .eq('branch_id', key.branchId)
      .gte('created_at', monthStart)
      .or('salesman_id.eq.$uid,manager_id.eq.$uid,cashier_id.eq.$uid');

  var pairs = 0;
  var amount = 0.0;
  var commission = 0.0;
  for (final r in rows as List) {
    amount += _d(r['total_amount']);
    if (r['salesman_id'] == uid) commission += _d(r['salesman_commission_amount']);
    if (r['manager_id'] == uid) commission += _d(r['manager_commission_amount']);
    for (final i in (r['sale_invoice_items'] as List? ?? const [])) {
      pairs += (i['quantity'] as num?)?.toInt() ?? 0;
    }
  }

  return EmployeeDetail(
    email: user?['email']?.toString() ?? '',
    phone: user?['phone_number']?.toString() ?? '',
    isActive: user?['is_active'] as bool? ?? true,
    invoices: rows.length,
    pairs: pairs,
    saleAmount: amount,
    commissionEarned: commission,
  );
});
