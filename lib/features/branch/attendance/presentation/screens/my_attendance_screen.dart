import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/current_branch_provider.dart';
import '../../data/model/attendance_model.dart';
import '../providers/attendance_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/utils/responsive.dart';
import 'package:safishoe_app/features/superadmin/report/presentation/widgets/report_summary_card.dart';
import 'package:safishoe_app/features/superadmin/report/presentation/widgets/report_table_shell.dart';

/// Manager / cashier / salesman ki apni attendance — aaj check in / check
/// out, is mahine ka khulasa aur pichle din.
class MyAttendanceScreen extends ConsumerStatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  ConsumerState<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends ConsumerState<MyAttendanceScreen> {
  static const _green = Color(0xFF22A06B);
  static const _red = Color(0xFFE5484D);
  static const _accent = Color(0xFF3E63DD);
  static const _grey = Color(0xFF8A8FA3);

  bool _busy = false;

  /// Check in ke baad "kitni der se kaam" har minute update ho.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(myAttendanceProvider);
      _snack(done, _green);
    } catch (e) {
      _snack(_message(e), _red);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _checkIn() {
    final branchId = ref.read(currentBranchIdProvider);
    if (branchId.isEmpty) {
      _snack('No branch assigned to your account', _red);
      return;
    }
    _run(() => ref.read(attendanceDatasourceProvider).checkIn(branchId),
        'Checked in');
  }

  void _checkOut() => _run(
      () => ref.read(attendanceDatasourceProvider).checkOut(), 'Checked out');

  void _snack(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  static String _message(Object e) => e is PostgrestException
      ? e.message
      : e.toString().replaceFirst(RegExp(r'^Exception: '), '');

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myAttendanceProvider);
    final isMobile = Responsive(context).isMobile;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: async.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e', style: const TextStyle(color: _red))),
        data: (records) {
          final today = pakistanToday();
          // Khula record (check out baqi) — kal raat ka bhi ho sakta hai.
          final open = records.where((r) => r.isOpen).firstOrNull;
          final todayRec =
              records.where((r) => r.date == today).firstOrNull;
          final month = records
              .where((r) =>
                  r.date.year == today.year && r.date.month == today.month)
              .toList();
          final monthHours =
              month.fold(Duration.zero, (s, r) => s + r.worked);

          final cards = [
            ReportSummaryCard(
              label: 'Days Present (this month)',
              value: '${month.length}',
              icon: AppIcons.calendarTodayOutlined,
              color: _accent,
            ),
            ReportSummaryCard(
              label: 'Hours Worked (this month)',
              value: fmtDuration(monthHours),
              icon: AppIcons.accessTimeOutlined,
              color: _green,
            ),
          ];

          return ListView(
            children: [
              const Text('My Attendance',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text('Check In when you arrive for duty, Check Out when you leave',
                  style: TextStyle(fontSize: 13, color: _grey)),
              const SizedBox(height: 16),
              _TodayCard(
                today: today,
                open: open,
                done: open == null ? todayRec : null,
                busy: _busy,
                onCheckIn: _checkIn,
                onCheckOut: _checkOut,
              ),
              const SizedBox(height: 16),
              isMobile
                  ? Column(children: [
                      for (final c in cards)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: c),
                    ])
                  : Row(children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 14),
                      Expanded(child: cards[1]),
                    ]),
              const SizedBox(height: 20),
              const Text('History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                      child: Text('No attendance yet',
                          style: TextStyle(color: _grey))),
                )
              else
                ReportTableShell(
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Check In')),
                    DataColumn(label: Text('Check Out')),
                    DataColumn(label: Text('Hours'), numeric: true),
                  ],
                  rows: [
                    for (final r in records)
                      DataRow(cells: [
                        DataCell(Text(fmtDay(r.date),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(fmtTime(r.checkInAt),
                            style: const TextStyle(color: _green))),
                        DataCell(r.checkOutAt == null
                            ? const Text('Not checked out',
                                style: TextStyle(color: Color(0xFFE56A00)))
                            : Text(fmtTime(r.checkOutAt!),
                                style: const TextStyle(color: _red))),
                        DataCell(Text(fmtDuration(r.worked))),
                      ]),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Aaj ka status + bara Check In / Check Out button.
class _TodayCard extends StatelessWidget {
  final DateTime today;

  /// Check in ho chuka, check out baqi.
  final AttendanceRecord? open;

  /// Aaj ka poora (in + out) record.
  final AttendanceRecord? done;
  final bool busy;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  const _TodayCard({
    required this.today,
    required this.open,
    required this.done,
    required this.busy,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF22A06B);
    const red = Color(0xFFE5484D);
    const grey = Color(0xFF8A8FA3);

    final String title;
    final String subtitle;
    final Widget action;
    if (open != null) {
      title = 'Checked in at ${fmtTime(open!.checkInAt)}';
      subtitle = 'Working for ${fmtDuration(open!.worked)}';
      action = _bigButton('Check Out', red, AppIcons.logout, onCheckOut);
    } else if (done != null) {
      title = 'Done for today';
      subtitle =
          'In ${fmtTime(done!.checkInAt)}  •  Out ${fmtTime(done!.checkOutAt!)}  •  ${fmtDuration(done!.worked)}';
      action = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          AppIcon(AppIcons.checkCircleOutline, color: green, size: 18),
          SizedBox(width: 6),
          Text('Completed',
              style: TextStyle(color: green, fontWeight: FontWeight.w600)),
        ]),
      );
    } else {
      title = 'Not checked in yet';
      subtitle = 'Tap Check In when your duty starts';
      action = _bigButton('Check In', green, AppIcons.accessTimeOutlined,
          onCheckIn);
    }

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(fmtDay(today),
            style: const TextStyle(fontSize: 12, color: grey)),
        const SizedBox(height: 4),
        Text(title,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: grey)),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 14,
        children: [info, action],
      ),
    );
  }

  Widget _bigButton(
          String label, Color color, String icon, VoidCallback onTap) =>
      FilledButton.icon(
        onPressed: busy ? null : onTap,
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : AppIcon(icon, color: Colors.white, size: 20),
        label: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
}

// ── Formatting (attendance screens) ───────────────────────────────────────

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String fmtDay(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String fmtTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '${h.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

String fmtDuration(Duration d) {
  final m = d.inMinutes < 0 ? 0 : d.inMinutes;
  return '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';
}
