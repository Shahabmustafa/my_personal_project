import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/attendance_machine_model.dart';

/// Attendance machines + staff ke Machine ID (superadmin).
class AttendanceMachineDatasource {
  final SupabaseClient _client;
  AttendanceMachineDatasource(this._client);

  Future<List<AttendanceDevice>> fetchDevices() async {
    final res = await _client
        .from('attendance_devices')
        .select('*, branches(branch_name)')
        .order('created_at');
    return (res as List)
        .map((e) => AttendanceDevice.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateDevice(
    String serialNumber, {
    required String name,
    required String? branchId,
    required bool isActive,
  }) async {
    await _client.from('attendance_devices').update({
      'name': name,
      'branch_id': branchId,
      'is_active': isActive,
    }).eq('serial_number', serialNumber);
    await reapplyPending();
  }

  /// Machine aur us ke saved punches hata deta hai (attendance waisi rehti).
  Future<void> deleteDevice(String serialNumber) async {
    await _client
        .from('attendance_devices')
        .delete()
        .eq('serial_number', serialNumber);
  }

  Future<List<StaffMachineId>> fetchStaff() async {
    final res = await _client
        .from('users')
        .select(
            'id, username, role, machine_user_id, user_branches(branches(branch_name))')
        .inFilter('role', ['manager', 'cashier', 'salesman'])
        .order('username');
    return (res as List)
        .map((e) => StaffMachineId.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Khali = Machine ID hata do.
  Future<void> setMachineUserId(String userId, String machineUserId) async {
    final v = machineUserId.trim();
    try {
      await _client
          .from('users')
          .update({'machine_user_id': v.isEmpty ? null : v}).eq('id', userId);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Machine ID $v is already assigned to someone else');
      }
      rethrow;
    }
    await reapplyPending();
  }

  /// Approve / Machine ID ke baad pehle ke ruke hue punches attendance mein.
  Future<int> reapplyPending() async {
    final res = await _client.rpc('attendance_reapply_pending');
    return (res as num?)?.toInt() ?? 0;
  }
}
