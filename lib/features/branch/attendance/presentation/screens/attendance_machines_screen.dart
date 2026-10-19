import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/attendance_machine_model.dart';
import '../providers/attendance_provider.dart';
import 'my_attendance_screen.dart' show fmtDay, fmtTime;

import 'package:safishoe_app/core/widget/app_dropdown.dart';
import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/features/superadmin/branch/presentation/providers/branch_provider.dart';
import 'package:safishoe_app/features/superadmin/report/presentation/widgets/report_table_shell.dart';

/// Superadmin: fingerprint attendance machines (ZKTeco ADMS) — nayi machine
/// khud yahan "Pending" aati hai, branch de kar Approve karein; aur har
/// staff member ka Machine ID (machine mein diya gaya User ID).
class AttendanceMachinesScreen extends ConsumerStatefulWidget {
  const AttendanceMachinesScreen({super.key});

  @override
  ConsumerState<AttendanceMachinesScreen> createState() =>
      _AttendanceMachinesScreenState();
}

class _AttendanceMachinesScreenState
    extends ConsumerState<AttendanceMachinesScreen> {
  static const _green = Color(0xFF22A06B);
  static const _red = Color(0xFFE5484D);
  static const _orange = Color(0xFFE56A00);
  static const _grey = Color(0xFF8A8FA3);
  static const _border = Color(0xFFE7E9F0);

  static const _roleNames = {
    'manager': 'Manager',
    'cashier': 'Cashier',
    'salesman': 'Salesman',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(branchProvider).branches.isEmpty) {
        ref.read(branchProvider.notifier).loadAllBranches();
      }
    });
  }

  void _snack(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  static String _err(Object e) => e.toString().replaceFirst(RegExp(r'^Exception: '), '');

  /// The web app's own domain — this is what goes into the machine.
  String get _serverAddress =>
      kIsWeb ? Uri.base.host : 'your web app domain (e.g. safishoe.vercel.app)';

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(attendanceDevicesProvider);
    final staff = ref.watch(staffMachineIdsProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(children: [
          const Expanded(
            child: Text('Attendance Machines',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const AppIcon(AppIcons.refresh, size: 18),
            onPressed: () {
              ref.invalidate(attendanceDevicesProvider);
              ref.invalidate(staffMachineIdsProvider);
            },
          ),
        ]),
        const SizedBox(height: 2),
        const Text('Attendance from fingerprint machine (ZKTeco ADMS)',
            style: TextStyle(fontSize: 13, color: _grey)),
        const SizedBox(height: 16),
        _setupCard(),
        const SizedBox(height: 22),
        const Text('Machines',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text(
            'As soon as a machine connects to the server it appears here as "Pending" — Edit it, choose a branch and Approve',
            style: TextStyle(fontSize: 12, color: _grey)),
        const SizedBox(height: 10),
        devices.when(
          skipLoadingOnReload: true,
          loading: () => const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator())),
          error: (e, _) =>
              Text('Error: $e', style: const TextStyle(color: _red)),
          data: (list) => list.isEmpty
              ? _emptyBox(
                  'No machine connected yet. Apply the setting above on the machine — '
                  'it will appear here once it connects.')
              : ReportTableShell(
                  columns: const [
                    DataColumn(label: Text('Machine')),
                    DataColumn(label: Text('Serial No.')),
                    DataColumn(label: Text('Branch')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Last Seen')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: [for (final d in list) _deviceRow(d)],
                ),
        ),
        const SizedBox(height: 26),
        const Text('Staff Machine ID',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text(
            'Enter the User ID (number) given to each employee on the machine — every person needs a different number',
            style: TextStyle(fontSize: 12, color: _grey)),
        const SizedBox(height: 10),
        staff.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator())),
          error: (e, _) =>
              Text('Error: $e', style: const TextStyle(color: _red)),
          data: (list) => list.isEmpty
              ? _emptyBox('No manager / cashier / salesman')
              : ReportTableShell(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Branch')),
                    DataColumn(label: Text('Machine ID')),
                  ],
                  rows: [
                    for (final s in list)
                      DataRow(cells: [
                        DataCell(Text(s.username,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(_roleNames[s.role] ?? s.role,
                            style: const TextStyle(color: _grey))),
                        DataCell(Text(
                            s.branchNames.isEmpty
                                ? '—'
                                : s.branchNames.join(', '),
                            style: const TextStyle(color: _grey))),
                        DataCell(_MachineIdField(
                          key: ValueKey('${s.userId}-${s.machineUserId}'),
                          initial: s.machineUserId,
                          onSave: (v) async {
                            try {
                              await ref
                                  .read(attendanceMachineDatasourceProvider)
                                  .setMachineUserId(s.userId, v);
                              ref.invalidate(staffMachineIdsProvider);
                              _snack(
                                  v.trim().isEmpty
                                      ? 'Machine ID removed'
                                      : 'Machine ID saved',
                                  _green);
                              return true;
                            } catch (e) {
                              _snack(_err(e), _red);
                              return false;
                            }
                          },
                        )),
                      ]),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _emptyBox(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _grey)),
      );

  /// Machine mein kya setting karni hai.
  Widget _setupCard() {
    Widget line(String label, String value, {bool copy = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            SizedBox(
                width: 150,
                child: Text(label,
                    style: const TextStyle(fontSize: 13, color: _grey))),
            Flexible(
              child: SelectableText(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            if (copy)
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                tooltip: 'Copy',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  _snack('Copied', _green);
                },
              ),
          ]),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6DEFA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Machine setting (Menu → Comm. → Cloud Server Setting)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          line('Server Address', _serverAddress, copy: kIsWeb),
          line('Server Port', '443'),
          line('Enable Domain Name', 'ON'),
          line('HTTPS', 'ON (if the option exists)'),
          const SizedBox(height: 6),
          const Text(
            '1) Connect the machine to the router (Comm. → Ethernet → DHCP ON)\n'
            '2) Save the setting above — the machine will appear below under "Machines" as Pending\n'
            '3) Edit → choose a branch → Approve\n'
            '4) Register each employee\'s thumb on the machine (User Mgt → New User) and enter the same User ID below under "Staff Machine ID"\n'
            'First thumb of the day = Check In, last thumb = Check Out',
            style: TextStyle(fontSize: 12.5, height: 1.6, color: Color(0xFF3A3F55)),
          ),
        ],
      ),
    );
  }

  DataRow _deviceRow(AttendanceDevice d) {
    final (String status, Color color) = !d.isActive
        ? ('Pending', _orange)
        : d.isOnline
            ? ('Online', _green)
            : ('Offline', _red);
    final seen = d.lastSeenAt;
    final today = DateTime.now();
    return DataRow(cells: [
      DataCell(Text(d.name.isEmpty ? 'New machine' : d.name,
          style: const TextStyle(fontWeight: FontWeight.w600))),
      DataCell(Text(d.serialNumber, style: const TextStyle(color: _grey))),
      DataCell(Text(d.branchName.isEmpty ? '—' : d.branchName)),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(status,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      )),
      DataCell(Text(
          seen == null
              ? '—'
              : (seen.year == today.year &&
                      seen.month == today.month &&
                      seen.day == today.day)
                  ? fmtTime(seen)
                  : '${fmtDay(seen)} ${fmtTime(seen)}',
          style: const TextStyle(fontSize: 12, color: _grey))),
      DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
        TextButton.icon(
          icon: const AppIcon(AppIcons.editOutlined, size: 16),
          label: Text(d.isActive ? 'Edit' : 'Edit / Approve'),
          onPressed: () => _editDevice(d),
        ),
        IconButton(
          icon: const AppIcon(AppIcons.deleteOutline,
              size: 18, color: Colors.redAccent),
          tooltip: 'Remove',
          onPressed: () => _deleteDevice(d),
        ),
      ])),
    ]);
  }

  Future<void> _editDevice(AttendanceDevice d) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _DeviceDialog(device: d),
    );
    if (saved == true) {
      ref.invalidate(attendanceDevicesProvider);
      _snack('Machine saved', _green);
    }
  }

  Future<void> _deleteDevice(AttendanceDevice d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove machine?'),
        content: Text(
            'Remove ${d.serialNumber}? Its saved punches will also be deleted '
            '(attendance already marked stays as is). If the machine connects again it will show as Pending.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(attendanceMachineDatasourceProvider)
          .deleteDevice(d.serialNumber);
      ref.invalidate(attendanceDevicesProvider);
      _snack('Machine removed', _green);
    } catch (e) {
      _snack(_err(e), _red);
    }
  }
}

/// Machine ka naam, branch aur Approve.
class _DeviceDialog extends ConsumerStatefulWidget {
  final AttendanceDevice device;
  const _DeviceDialog({required this.device});

  @override
  ConsumerState<_DeviceDialog> createState() => _DeviceDialogState();
}

class _DeviceDialogState extends ConsumerState<_DeviceDialog> {
  late final _nameCtrl = TextEditingController(text: widget.device.name);
  late String? _branchId = widget.device.branchId;
  late bool _active = widget.device.isActive || widget.device.branchId == null;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_active && _branchId == null) {
      setState(() => _error = 'Choose a branch to approve');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(attendanceMachineDatasourceProvider).updateDevice(
            widget.device.serialNumber,
            name: _nameCtrl.text.trim(),
            branchId: _branchId,
            isActive: _active,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchProvider).branches;
    final names = {for (final b in branches) b.id: b.branchName};
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Machine ${widget.device.serialNumber}'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name (optional)',
                hintText: 'e.g. Bank Road Gate',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),
            AppSearchDropdown<String>(
              label: 'Branch',
              isRequired: true,
              items: names.keys.toList(),
              selectedItem: _branchId,
              itemLabel: (id) => names[id] ?? '',
              onChanged: (v) => setState(() => _branchId = v),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: const Text('Approved'),
              subtitle: const Text(
                  'Once approved, this machine\'s thumbs are recorded in attendance',
                  style: TextStyle(fontSize: 12)),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}

/// Table ke andar Machine ID likhne ka chhota field + save.
class _MachineIdField extends StatefulWidget {
  final String initial;
  final Future<bool> Function(String) onSave;
  const _MachineIdField(
      {super.key, required this.initial, required this.onSave});

  @override
  State<_MachineIdField> createState() => _MachineIdFieldState();
}

class _MachineIdFieldState extends State<_MachineIdField> {
  late final _ctrl = TextEditingController(text: widget.initial);
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _changed => _ctrl.text.trim() != widget.initial;

  Future<void> _save() async {
    if (!_changed) return;
    setState(() => _saving = true);
    await widget.onSave(_ctrl.text);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 110,
        child: TextField(
          controller: _ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'e.g. 1',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      const SizedBox(width: 6),
      _saving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : IconButton(
              tooltip: 'Save',
              visualDensity: VisualDensity.compact,
              onPressed: _changed ? _save : null,
              icon: AppIcon(AppIcons.check,
                  size: 18,
                  color: _changed
                      ? const Color(0xFF22A06B)
                      : const Color(0xFFBFC3D1)),
            ),
    ]);
  }
}
