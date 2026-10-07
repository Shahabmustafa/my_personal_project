import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safishoe_app/core/service/realtime/table_changes_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasource/attendance_datasource.dart';
import '../../data/datasource/attendance_machine_datasource.dart';
import '../../data/model/attendance_machine_model.dart';
import '../../data/model/attendance_model.dart';

final attendanceDatasourceProvider = Provider<AttendanceDatasource>(
  (ref) => AttendanceDatasource(Supabase.instance.client),
);

/// Logged-in user ki apni attendance (aakhri ~2 mahine), naya pehle.
final myAttendanceProvider =
    FutureProvider.autoDispose<List<AttendanceRecord>>((ref) {
  ref.watch(tableChangesProvider('branch_attendance'));
  final userId = ref.watch(authProvider).user?.id ?? '';
  if (userId.isEmpty) return Future.value(const []);
  return ref.read(attendanceDatasourceProvider).fetchMine(userId);
});

/// Branch staff ki ek din ki attendance — (branchId, date).
final staffAttendanceProvider = FutureProvider.autoDispose
    .family<List<StaffAttendanceRow>, (String, DateTime)>((ref, key) {
  // Realtime — koi bhi check in / out kare to list foran update.
  ref.watch(tableChangesProvider('branch_attendance'));
  if (key.$1.isEmpty) return Future.value(const []);
  return ref.read(attendanceDatasourceProvider).fetchBranchDay(key.$1, key.$2);
});

// ── Attendance machines (superadmin) ──────────────────────────────────────
final attendanceMachineDatasourceProvider =
    Provider<AttendanceMachineDatasource>(
  (ref) => AttendanceMachineDatasource(Supabase.instance.client),
);

final attendanceDevicesProvider =
    FutureProvider.autoDispose<List<AttendanceDevice>>((ref) {
  // Nayi machine judte hi / last seen badalte hi list update.
  ref.watch(tableChangesProvider('attendance_devices'));
  return ref.read(attendanceMachineDatasourceProvider).fetchDevices();
});

final staffMachineIdsProvider =
    FutureProvider.autoDispose<List<StaffMachineId>>(
  (ref) => ref.read(attendanceMachineDatasourceProvider).fetchStaff(),
);
