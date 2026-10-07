/// `branch_attendance` ka ek record — ek user ka ek din.
class AttendanceRecord {
  final String id;
  final String branchId;

  /// Pakistan time ke hisaab se din.
  final DateTime date;
  final DateTime checkInAt;
  final DateTime? checkOutAt;

  const AttendanceRecord({
    required this.id,
    required this.branchId,
    required this.date,
    required this.checkInAt,
    this.checkOutAt,
  });

  bool get isOpen => checkOutAt == null;

  /// Kaam ka waqt — check out na hua ho to abhi tak.
  Duration get worked =>
      (checkOutAt ?? DateTime.now()).difference(checkInAt);

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) =>
      AttendanceRecord(
        id: map['id'] as String,
        branchId: map['branch_id'] as String,
        date: DateTime.parse(map['attendance_date'] as String),
        checkInAt: DateTime.parse(map['check_in_at'] as String).toLocal(),
        checkOutAt: map['check_out_at'] == null
            ? null
            : DateTime.parse(map['check_out_at'] as String).toLocal(),
      );
}

/// Branch staff attendance screen ki ek row — employee + us din ka in/out
/// (na aaya ho to dono null).
class StaffAttendanceRow {
  final String userId;
  final String username;
  final String role;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;

  const StaffAttendanceRow({
    required this.userId,
    required this.username,
    required this.role,
    this.checkInAt,
    this.checkOutAt,
  });

  bool get isPresent => checkInAt != null;
  bool get isStillIn => checkInAt != null && checkOutAt == null;

  Duration? get worked => checkInAt == null
      ? null
      : (checkOutAt ?? DateTime.now()).difference(checkInAt!);

  factory StaffAttendanceRow.fromMap(Map<String, dynamic> map) =>
      StaffAttendanceRow(
        userId: map['user_id'] as String,
        username: map['username'] as String? ?? '',
        role: map['role'] as String? ?? '',
        checkInAt: map['check_in_at'] == null
            ? null
            : DateTime.parse(map['check_in_at'] as String).toLocal(),
        checkOutAt: map['check_out_at'] == null
            ? null
            : DateTime.parse(map['check_out_at'] as String).toLocal(),
      );
}

/// Aaj ki tareekh Pakistan time (UTC+5) mein — server bhi isi se din banata
/// hai, device ka timezone kuch bhi ho.
DateTime pakistanToday() {
  final t = DateTime.now().toUtc().add(const Duration(hours: 5));
  return DateTime(t.year, t.month, t.day);
}
