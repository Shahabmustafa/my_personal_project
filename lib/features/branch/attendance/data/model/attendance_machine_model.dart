/// Attendance machine (ZKTeco ADMS) — pehli baar server se rabta karte hi
/// khud ban jati hai; superadmin branch de kar approve karta hai.
class AttendanceDevice {
  final String serialNumber;
  final String name;
  final String? branchId;
  final String branchName;
  final bool isActive;
  final DateTime? lastSeenAt;
  final String lastIp;

  const AttendanceDevice({
    required this.serialNumber,
    required this.name,
    required this.branchId,
    required this.branchName,
    required this.isActive,
    required this.lastSeenAt,
    required this.lastIp,
  });

  /// Machine har ~10 second baad server se poochti hai — 5 minute se zyada
  /// chup ho to offline (internet/bijli).
  bool get isOnline =>
      lastSeenAt != null &&
      DateTime.now().difference(lastSeenAt!) < const Duration(minutes: 5);

  factory AttendanceDevice.fromMap(Map<String, dynamic> map) {
    final branch = map['branches'] as Map<String, dynamic>?;
    return AttendanceDevice(
      serialNumber: map['serial_number'] as String,
      name: map['name'] as String? ?? '',
      branchId: map['branch_id'] as String?,
      branchName: branch?['branch_name'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? false,
      lastSeenAt: map['last_seen_at'] == null
          ? null
          : DateTime.parse(map['last_seen_at'] as String).toLocal(),
      lastIp: map['last_ip'] as String? ?? '',
    );
  }
}

/// Branch staff + machine wala User ID (PIN).
class StaffMachineId {
  final String userId;
  final String username;
  final String role;
  final List<String> branchNames;
  final String machineUserId;

  const StaffMachineId({
    required this.userId,
    required this.username,
    required this.role,
    required this.branchNames,
    required this.machineUserId,
  });

  factory StaffMachineId.fromMap(Map<String, dynamic> map) => StaffMachineId(
        userId: map['id'] as String,
        username: map['username'] as String? ?? '',
        role: map['role'] as String? ?? '',
        branchNames: [
          for (final ub in (map['user_branches'] as List? ?? const []))
            ((ub as Map)['branches'] as Map?)?['branch_name'] as String? ?? '',
        ]..removeWhere((n) => n.isEmpty),
        machineUserId: map['machine_user_id'] as String? ?? '',
      );
}
