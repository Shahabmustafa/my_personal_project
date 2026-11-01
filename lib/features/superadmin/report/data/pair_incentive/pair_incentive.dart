import 'package:supabase_flutter/supabase_flutter.dart';

double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

/// `pair_incentive_report` ki ek row — ek employee ka ek mahina.
class PairIncentiveRow {
  final DateTime month;
  final String branchId;
  final String branchName;
  final String employeeId;
  final String username;
  final String role;
  final int sold;
  final int returned;
  final double rate;
  final double amount;

  /// Is mahine ka admin accept ho chuka (paisa mil sakta hai).
  final bool approved;

  const PairIncentiveRow({
    required this.month,
    required this.branchId,
    required this.branchName,
    required this.employeeId,
    required this.username,
    required this.role,
    required this.sold,
    required this.returned,
    required this.rate,
    required this.amount,
    required this.approved,
  });

  int get net => sold - returned;

  factory PairIncentiveRow.fromMap(Map<String, dynamic> m) => PairIncentiveRow(
    month: DateTime.parse(m['month'] as String),
    branchId: m['branch_id'] as String,
    branchName: m['branch_name'] as String? ?? '',
    employeeId: m['employee_id'] as String,
    username: m['username'] as String? ?? '',
    role: m['role'] as String? ?? '',
    sold: (m['pairs_sold'] as num? ?? 0).toInt(),
    returned: (m['pairs_returned'] as num? ?? 0).toInt(),
    rate: _d(m['rate']),
    amount: _d(m['amount']),
    approved: m['approved'] == true,
  );
}

/// `pair_incentive_months` ki ek row — ek branch ka ek mahina.
class PairIncentiveMonth {
  final DateTime month;
  final String branchId;
  final String branchName;
  final double target;
  final double netSale;
  final bool achieved;
  final bool approved;

  const PairIncentiveMonth({
    required this.month,
    required this.branchId,
    required this.branchName,
    required this.target,
    required this.netSale,
    required this.achieved,
    required this.approved,
  });

  factory PairIncentiveMonth.fromMap(Map<String, dynamic> m) =>
      PairIncentiveMonth(
        month: DateTime.parse(m['month'] as String),
        branchId: m['branch_id'] as String,
        branchName: m['branch_name'] as String? ?? '',
        target: _d(m['target']),
        netSale: _d(m['net_sale']),
        achieved: m['achieved'] == true,
        approved: m['approved'] == true,
      );
}

/// Ek din ke pairs (ek employee).
class PairIncentiveDay {
  final DateTime day;
  final int sold;
  final int returned;
  const PairIncentiveDay(this.day, this.sold, this.returned);
  int get net => sold - returned;
}

class PairIncentiveData {
  final List<PairIncentiveRow> rows;
  final List<PairIncentiveMonth> months;
  const PairIncentiveData(this.rows, this.months);
}

String _date(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class PairIncentiveDatasource {
  final SupabaseClient _client;
  PairIncentiveDatasource(this._client);

  Future<PairIncentiveData> fetch(
    DateTime from,
    DateTime to, {
    String? branchId,
  }) async {
    final params = {
      'p_from': _date(from),
      'p_to': _date(to),
      'p_branch_id': (branchId == null || branchId.isEmpty) ? null : branchId,
    };
    final res = await Future.wait([
      _client.rpc('pair_incentive_report', params: params),
      _client.rpc('pair_incentive_months', params: params),
    ]);
    return PairIncentiveData(
      [
        for (final r in res[0] as List)
          PairIncentiveRow.fromMap((r as Map).cast<String, dynamic>()),
      ],
      [
        for (final r in res[1] as List)
          PairIncentiveMonth.fromMap((r as Map).cast<String, dynamic>()),
      ],
    );
  }

  Future<void> approve(String branchId, DateTime month) => _client.rpc(
    'pair_incentive_approve',
    params: {'p_branch_id': branchId, 'p_month': _date(month)},
  );

  Future<void> setRate(String employeeId, double rate) => _client
      .from('employee_salary')
      .update({'pair_rate': rate})
      .eq('id', employeeId);

  Future<List<PairIncentiveDay>> fetchDays(
    String employeeId,
    DateTime month,
  ) async {
    final res = await _client.rpc(
      'pair_incentive_days',
      params: {'p_employee_id': employeeId, 'p_month': _date(month)},
    );
    return [
      for (final r in res as List)
        PairIncentiveDay(
          DateTime.parse((r as Map)['day'] as String),
          (r['pairs_sold'] as num).toInt(),
          (r['pairs_returned'] as num).toInt(),
        ),
    ];
  }

  /// Employee ka record kis saal bana — yearly list wahan se shuru.
  Future<int> startYear(String employeeId) async {
    final r = await _client
        .from('employee_salary')
        .select('created_at')
        .eq('id', employeeId)
        .single();
    return DateTime.parse(r['created_at'] as String).toLocal().year;
  }
}
