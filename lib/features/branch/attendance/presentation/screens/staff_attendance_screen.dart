import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/current_branch_provider.dart';
import '../../data/model/attendance_model.dart';
import '../providers/attendance_provider.dart';
import '../widgets/fingerprint_dialogs.dart';
import 'my_attendance_screen.dart' show fmtDay, fmtTime, fmtDuration;

import 'package:safishoe_app/core/widget/app_dropdown.dart';
import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/utils/responsive.dart';
import 'package:safishoe_app/features/superadmin/branch/presentation/providers/branch_provider.dart';
import 'package:safishoe_app/features/superadmin/report/presentation/widgets/report_summary_card.dart';
import 'package:safishoe_app/features/superadmin/report/presentation/widgets/report_table_shell.dart';

/// Branch ke saare manager / cashier / salesman ki ek din ki attendance —
/// kaun aaya, kab aaya, kab gaya. Branch manager ko apni branch, superadmin
/// ([allBranches]) ko branch chunne ka dropdown milta hai.
class StaffAttendanceScreen extends ConsumerStatefulWidget {
  final bool allBranches;
  const StaffAttendanceScreen({super.key, this.allBranches = false});

  @override
  ConsumerState<StaffAttendanceScreen> createState() =>
      _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends ConsumerState<StaffAttendanceScreen> {
  static const _green = Color(0xFF22A06B);
  static const _red = Color(0xFFE5484D);
  static const _orange = Color(0xFFE56A00);
  static const _accent = Color(0xFF3E63DD);
  static const _grey = Color(0xFF8A8FA3);

  static const _allKey = 'all';

  DateTime _date = pakistanToday();
  String? _branchId;

  /// "Abhi tak kaam" wale ghante har minute update hon.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    if (widget.allBranches) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(branchProvider).branches.isEmpty) {
          ref.read(branchProvider.notifier).loadAllBranches();
        }
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _shift(int days) =>
      setState(() => _date = _date.add(Duration(days: days)));

  static const _roleNames = {
    'manager': 'Manager',
    'cashier': 'Cashier',
    'salesman': 'Salesman',
  };

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive(context).isMobile;
    final branches = widget.allBranches
        ? ref.watch(branchProvider).branches
        : const [];
    // Admin: default "All Branches" — har branch apne employees ke saath.
    final allMode =
        widget.allBranches && (_branchId == null || _branchId == _allKey);
    final branchId = widget.allBranches
        ? (allMode ? '' : _branchId!)
        : ref.watch(currentBranchIdProvider);
    final branchIds = allMode
        ? [for (final b in branches) b.id as String]
        : [branchId];
    final asyncs = [
      for (final id in branchIds)
        ref.watch(staffAttendanceProvider((id, _date))),
    ];
    final async = asyncs.isEmpty
        ? const AsyncData(<StaffAttendanceRow>[])
        : asyncs.first;
    final rows = [
      for (final a in asyncs) ...(a.value ?? const <StaffAttendanceRow>[]),
    ];
    final present = rows.where((r) => r.isPresent).length;
    final stillIn = rows.where((r) => r.isStillIn).length;
    final isToday = _date == pakistanToday();
    final registered = widget.allBranches
        ? const <String>{}
        : ref.watch(registeredFingerprintsProvider(branchId)).value ??
              const <String>{};

    final cards = [
      ReportSummaryCard(
        label: 'Staff',
        value: '${rows.length}',
        icon: AppIcons.peopleOutline,
        color: _accent,
      ),
      ReportSummaryCard(
        label: 'Present',
        value: '$present',
        icon: AppIcons.checkCircleOutline,
        color: _green,
      ),
      ReportSummaryCard(
        label: 'Absent',
        value: '${rows.length - present}',
        icon: AppIcons.errorOutline,
        color: _red,
      ),
      ReportSummaryCard(
        label: isToday ? 'Still In' : 'No Check Out',
        value: '$stillIn',
        icon: AppIcons.accessTimeOutlined,
        color: _orange,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Staff Attendance',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              if (!widget.allBranches) ...[
                FilledButton.icon(
                  onPressed: branchId.isEmpty
                      ? null
                      : () => showFingerprintPunchDialog(
                          context,
                          branchId: branchId,
                        ),
                  icon: const Icon(Icons.fingerprint, size: 20),
                  label: const Text('Fingerprint Punch'),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                icon: const AppIcon(AppIcons.refresh, size: 18),
                onPressed: () {
                  for (final id in branchIds) {
                    ref.invalidate(staffAttendanceProvider((id, _date)));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const AppIcon(AppIcons.chevronLeft, size: 20),
                    tooltip: 'Previous day',
                    onPressed: () => _shift(-1),
                  ),
                  SizedBox(
                    width: 150,
                    child: Text(
                      isToday ? 'Today' : fmtDay(_date),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const AppIcon(AppIcons.chevronRight, size: 20),
                    tooltip: 'Next day',
                    onPressed: isToday ? null : () => _shift(1),
                  ),
                ],
              ),
              if (widget.allBranches)
                SizedBox(
                  width: 220,
                  child: AppSearchDropdown<String>(
                    label: 'Branch',
                    items: [_allKey, for (final b in branches) b.id as String],
                    selectedItem: allMode ? _allKey : branchId,
                    itemLabel: (id) => id == _allKey
                        ? 'All Branches'
                        : branches
                                  .where((b) => b.id == id)
                                  .map((b) => b.branchName as String)
                                  .firstOrNull ??
                              '',
                    onChanged: (v) => setState(() => _branchId = v),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          isMobile
              ? Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final c in cards)
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 50) / 2,
                        child: c,
                      ),
                  ],
                )
              : Row(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 14),
                      Expanded(child: cards[i]),
                    ],
                  ],
                ),
          const SizedBox(height: 16),
          Expanded(
            child: allMode
                ? _allBranchesList(branches, isToday)
                : async.when(
                    skipLoadingOnReload: true,
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        'Error: $e',
                        style: const TextStyle(color: _red),
                      ),
                    ),
                    data: (rows) => rows.isEmpty
                        ? const Center(
                            child: Text(
                              'No staff in this branch',
                              style: TextStyle(color: _grey),
                            ),
                          )
                        : SingleChildScrollView(
                            child: ReportTableShell(
                              columns: [
                                DataColumn(label: Text('#')),
                                DataColumn(label: Text('Name')),
                                DataColumn(label: Text('Role')),
                                DataColumn(label: Text('Check In')),
                                DataColumn(label: Text('Check Out')),
                                DataColumn(label: Text('Hours'), numeric: true),
                                DataColumn(label: Text('Status')),
                                if (!widget.allBranches)
                                  const DataColumn(label: Text('Fingerprint')),
                              ],
                              rows: [
                                for (var i = 0; i < rows.length; i++)
                                  _row(
                                    i + 1,
                                    rows[i],
                                    isToday,
                                    branchId,
                                    registered.contains(rows[i].userId),
                                  ),
                              ],
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Admin: har branch ka naam + usi branch ke employees ki table.
  Widget _allBranchesList(List branches, bool isToday) {
    if (branches.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      children: [
        for (final b in branches) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              b.branchName as String,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ref
              .watch(staffAttendanceProvider((b.id as String, _date)))
              .when(
                skipLoadingOnReload: true,
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    Text('Error: $e', style: const TextStyle(color: _red)),
                data: (rows) => rows.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'No staff in this branch',
                          style: TextStyle(color: _grey),
                        ),
                      )
                    : ReportTableShell(
                        columns: [
                          for (final c in const [
                            '#',
                            'Name',
                            'Role',
                            'Check In',
                            'Check Out',
                          ])
                            DataColumn(label: Text(c)),
                          const DataColumn(label: Text('Hours'), numeric: true),
                          const DataColumn(label: Text('Status')),
                        ],
                        rows: [
                          for (var i = 0; i < rows.length; i++)
                            _row(i + 1, rows[i], isToday, '', false),
                        ],
                      ),
              ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  DataRow _row(
    int serial,
    StaffAttendanceRow r,
    bool isToday,
    String branchId,
    bool hasFingerprint,
  ) {
    final (String status, Color color) = !r.isPresent
        ? ('Absent', _red)
        : r.isStillIn
        ? (isToday ? 'Working' : 'No check out', _orange)
        : ('Present', _green);
    return DataRow(
      cells: [
        DataCell(Text('$serial', style: const TextStyle(color: _grey))),
        DataCell(
          Text(r.username, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        DataCell(
          Text(
            _roleNames[r.role] ?? r.role,
            style: const TextStyle(color: _grey),
          ),
        ),
        DataCell(
          Text(
            r.checkInAt == null ? '—' : fmtTime(r.checkInAt!),
            style: const TextStyle(color: _green),
          ),
        ),
        DataCell(
          Text(
            r.checkOutAt == null ? '—' : fmtTime(r.checkOutAt!),
            style: const TextStyle(color: _red),
          ),
        ),
        DataCell(Text(r.worked == null ? '—' : fmtDuration(r.worked!))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (!widget.allBranches)
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasFingerprint ? Icons.check_circle : Icons.cancel_outlined,
                  size: 16,
                  color: hasFingerprint ? _green : _grey,
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: branchId.isEmpty
                      ? null
                      : () => _register(r, branchId, hasFingerprint),
                  child: Text(
                    hasFingerprint ? 'Re-register' : 'Register Fingerprint',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _register(
    StaffAttendanceRow r,
    String branchId,
    bool hasFingerprint,
  ) async {
    final ok = await showRegisterFingerprintDialog(
      context,
      userId: r.userId,
      username: r.username,
      branchId: branchId,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fingerprint registered for ${r.username}')),
      );
    }
  }
}
