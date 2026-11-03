import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/service/fingerprint_helper_client.dart';
import '../providers/attendance_provider.dart';
import 'package:safishoe_app/core/utils/error_text.dart';

const _green = Color(0xFF22A06B);
const _red = Color(0xFFE5484D);
const _grey = Color(0xFF8A8FA3);

/// Staff ki fingerprint register — reader par finger rakhwa kar template
/// save. Kamyabi par `true`.
Future<bool> showRegisterFingerprintDialog(
  BuildContext context, {
  required String userId,
  required String username,
  required String branchId,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _RegisterDialog(userId: userId, username: username, branchId: branchId),
  );
  return ok ?? false;
}

class _RegisterDialog extends ConsumerStatefulWidget {
  final String userId;
  final String username;
  final String branchId;
  const _RegisterDialog({
    required this.userId,
    required this.username,
    required this.branchId,
  });

  @override
  ConsumerState<_RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends ConsumerState<_RegisterDialog> {
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final template = await ref.read(fingerprintHelperProvider).enroll();
      await ref
          .read(attendanceDatasourceProvider)
          .registerFingerprint(widget.userId, widget.branchId, template);
      ref.invalidate(registeredFingerprintsProvider(widget.branchId));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = friendlyError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Register fingerprint — ${widget.username}'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fingerprint,
              size: 72,
              color: _error != null ? _red : _green,
            ),
            const SizedBox(height: 12),
            if (_busy) ...[
              const Text(
                'Place the same finger on the reader and lift it, '
                'repeat until the reader finishes (about 4 times).',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ] else
              Text(
                _error ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _red),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        if (!_busy)
          FilledButton(onPressed: _run, child: const Text('Try again')),
      ],
    );
  }
}

/// Roz ka punch — staff baari baari finger lagata hai; pehla punch check in,
/// agla check out. Band karne tak chalta rehta hai.
Future<void> showFingerprintPunchDialog(
  BuildContext context, {
  required String branchId,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PunchDialog(branchId: branchId),
  );
}

class _PunchDialog extends ConsumerStatefulWidget {
  final String branchId;
  const _PunchDialog({required this.branchId});

  @override
  ConsumerState<_PunchDialog> createState() => _PunchDialogState();
}

class _PunchDialogState extends ConsumerState<_PunchDialog> {
  bool _stopped = false;
  String _message = 'Starting…';
  Color _color = _grey;
  bool _fatal = false;

  @override
  void initState() {
    super.initState();
    _loop();
  }

  @override
  void dispose() {
    _stopped = true;
    super.dispose();
  }

  void _show(String msg, Color c, {bool fatal = false}) {
    if (!mounted) return;
    setState(() {
      _message = msg;
      _color = c;
      _fatal = fatal;
    });
  }

  Future<void> _loop() async {
    final helper = ref.read(fingerprintHelperProvider);
    final ds = ref.read(attendanceDatasourceProvider);
    List<({String userId, String template})> templates;
    try {
      if (!await helper.isReady()) {
        _show(
          'Fingerprint reader not found. Start the helper and plug in '
          'the reader.',
          _red,
          fatal: true,
        );
        return;
      }
      templates = await ds.fetchFingerprintTemplates(widget.branchId);
    } catch (e) {
      _show(friendlyError(e), _red, fatal: true);
      return;
    }
    if (templates.isEmpty) {
      _show(
        'No fingerprints registered in this branch yet.',
        _red,
        fatal: true,
      );
      return;
    }

    while (!_stopped) {
      _show('Place your finger on the reader', _grey);
      try {
        final userId = await helper.identify(templates);
        if (_stopped) return;
        if (userId == null) {
          _show('Fingerprint not recognised — try again', _red);
          await Future<void>.delayed(const Duration(seconds: 2));
          continue;
        }
        final (action, name) = await ds.fingerprintPunch(
          userId,
          widget.branchId,
        );
        if (_stopped) return;
        ref.invalidate(staffAttendanceProvider);
        _show(
          action == 'check_in' ? '$name — Checked IN' : '$name — Checked OUT',
          action == 'check_in' ? _green : _red,
        );
        await Future<void>.delayed(const Duration(seconds: 3));
      } on FingerprintHelperException catch (e) {
        if (e.isTimeout) continue;
        _show(e.message, _red, fatal: true);
        return;
      } catch (e) {
        // Server ka jawab (e.g. "already checked in and out today").
        _show(friendlyError(e), _red);
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fingerprint Attendance'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fingerprint, size: 96, color: _color),
            const SizedBox(height: 12),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_fatal)
          TextButton(
            onPressed: () {
              setState(() => _fatal = false);
              _loop();
            },
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
