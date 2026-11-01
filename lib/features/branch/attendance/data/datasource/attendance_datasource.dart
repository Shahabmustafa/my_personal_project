import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/attendance_model.dart';

/// Check in / check out server functions ke zariye hota hai (waqt server ka,
/// user auth.uid() se) — attendance_migration.sql dekhein.
class AttendanceDatasource {
  final SupabaseClient _client;
  AttendanceDatasource(this._client);

  Future<AttendanceRecord> checkIn(String branchId) async {
    final res = await _client.rpc(
      'attendance_check_in',
      params: {'p_branch_id': branchId},
    );
    return AttendanceRecord.fromMap((res as Map).cast<String, dynamic>());
  }

  Future<AttendanceRecord> checkOut() async {
    final res = await _client.rpc('attendance_check_out');
    return AttendanceRecord.fromMap((res as Map).cast<String, dynamic>());
  }

  /// Logged-in user ke aakhri [limit] din, naya pehle.
  Future<List<AttendanceRecord>> fetchMine(
    String userId, {
    int limit = 62,
  }) async {
    final res = await _client
        .from('branch_attendance')
        .select()
        .eq('user_id', userId)
        .order('check_in_at', ascending: false)
        .limit(limit);
    return (res as List)
        .map((e) => AttendanceRecord.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Branch ke saare manager/cashier/salesman + [date] ki attendance.
  Future<List<StaffAttendanceRow>> fetchBranchDay(
    String branchId,
    DateTime date,
  ) async {
    final res = await _client.rpc(
      'branch_attendance_for_day',
      params: {
        'p_branch_id': branchId,
        'p_date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      },
    );
    return (res as List)
        .map((e) => StaffAttendanceRow.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ── Fingerprint (fingerprint_attendance_migration.sql) ─────────────────

  /// Branch ke un staff ki ids jinhon ne fingerprint register ki.
  Future<Set<String>> fetchRegisteredFingerprints(String branchId) async {
    final res = await _client.rpc(
      'fingerprint_registered_users',
      params: {'p_branch_id': branchId},
    );
    return {for (final r in res as List) (r as Map)['user_id'] as String};
  }

  Future<void> registerFingerprint(
    String userId,
    String branchId,
    String template,
  ) async {
    await _client.rpc(
      'fingerprint_register',
      params: {
        'p_user_id': userId,
        'p_branch_id': branchId,
        'p_template': template,
      },
    );
  }

  Future<void> removeFingerprint(String userId, String branchId) async {
    await _client.rpc(
      'fingerprint_remove',
      params: {'p_user_id': userId, 'p_branch_id': branchId},
    );
  }

  Future<List<({String userId, String template})>> fetchFingerprintTemplates(
    String branchId,
  ) async {
    final res = await _client.rpc(
      'fingerprint_templates_for_branch',
      params: {'p_branch_id': branchId},
    );
    return [
      for (final r in res as List)
        (
          userId: (r as Map)['user_id'] as String,
          template: r['template'] as String,
        ),
    ];
  }

  /// Check in ya check out — server khud tay karta hai.
  /// Return: ('check_in' | 'check_out', username).
  Future<(String, String)> fingerprintPunch(
    String userId,
    String branchId,
  ) async {
    final res = await _client.rpc(
      'fingerprint_punch',
      params: {'p_user_id': userId, 'p_branch_id': branchId},
    );
    final m = (res as Map).cast<String, dynamic>();
    return (m['action'] as String, m['username'] as String? ?? '');
  }
}
