import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/attendance_model.dart';

/// Check in / check out server functions ke zariye hota hai (waqt server ka,
/// user auth.uid() se) — attendance_migration.sql dekhein.
class AttendanceDatasource {
  final SupabaseClient _client;
  AttendanceDatasource(this._client);

  Future<AttendanceRecord> checkIn(String branchId) async {
    final res = await _client
        .rpc('attendance_check_in', params: {'p_branch_id': branchId});
    return AttendanceRecord.fromMap((res as Map).cast<String, dynamic>());
  }

  Future<AttendanceRecord> checkOut() async {
    final res = await _client.rpc('attendance_check_out');
    return AttendanceRecord.fromMap((res as Map).cast<String, dynamic>());
  }

  /// Logged-in user ke aakhri [limit] din, naya pehle.
  Future<List<AttendanceRecord>> fetchMine(String userId,
      {int limit = 62}) async {
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
      String branchId, DateTime date) async {
    final res = await _client.rpc('branch_attendance_for_day', params: {
      'p_branch_id': branchId,
      'p_date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    });
    return (res as List)
        .map((e) => StaffAttendanceRow.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
