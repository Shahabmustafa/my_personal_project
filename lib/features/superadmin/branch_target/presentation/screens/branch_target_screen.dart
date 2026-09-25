import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../branch/data/model/branch_model.dart';
import '../../../branch/presentation/providers/branch_provider.dart';
import '../../data/branch_target_datasource.dart';

/// Superadmin/admin yahan branch ka target set karta hai. Start date hamesha
/// aaj hoti hai (badal nahi sakti); admin end date aur ek total amount deta
/// hai jo saare dinon mein barabar divide hota hai. Uske baad kisi bhi din
/// (jaise Sat/Sun jab sale zyada hoti hai) ka target alag se badha sakta hai.
class BranchTargetScreen extends ConsumerStatefulWidget {
  const BranchTargetScreen({super.key});

  @override
  ConsumerState<BranchTargetScreen> createState() => _BranchTargetScreenState();
}

class _BranchTargetScreenState extends ConsumerState<BranchTargetScreen> {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final _totalCtrl = TextEditingController();
  final Map<DateTime, TextEditingController> _dayCtrls = {};
  final DateTime _start = BranchTargetDatasource.dateOnly(DateTime.now());

  String? _branchId;
  DateTime? _end;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(branchProvider.notifier).loadAllBranches();
    });
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    for (final c in _dayCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _fmtAmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  double get _daysSum => _dayCtrls.values
      .fold(0.0, (s, c) => s + (double.tryParse(c.text.trim()) ?? 0));

  List<DateTime> get _sortedDays => _dayCtrls.keys.toList()..sort();

  void _clearDays() {
    for (final c in _dayCtrls.values) {
      c.dispose();
    }
    _dayCtrls.clear();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.redAccent : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _selectBranch(String? id) async {
    if (id == null) return;
    setState(() {
      _branchId = id;
      _loading = true;
      _end = null;
      _totalCtrl.clear();
      _clearDays();
    });
    try {
      final existing =
          await ref.read(branchTargetDatasourceProvider).fetchFrom(id, _start);
      if (!mounted || _branchId != id) return;
      setState(() {
        for (final e in existing.entries) {
          _dayCtrls[e.key] = TextEditingController(text: _fmtAmt(e.value));
        }
        if (existing.isNotEmpty) {
          _end = _sortedDays.last;
          _totalCtrl.text = _fmtAmt(_daysSum);
        }
      });
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end ?? _start,
      firstDate: _start,
      lastDate: _start.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _end = BranchTargetDatasource.dateOnly(picked));
  }

  /// Total amount ko aaj se end date tak barabar divide karta hai (poore
  /// rupay; bacha hua remainder aakhri din mein jata hai).
  void _divide() {
    final end = _end;
    final total = double.tryParse(_totalCtrl.text.trim()) ?? 0;
    if (_branchId == null) return _snack('Pehle branch select karein', error: true);
    if (end == null) return _snack('End date select karein', error: true);
    if (total <= 0) return _snack('Target amount daalein', error: true);

    final days = end.difference(_start).inDays + 1;
    final base = (total / days).floorToDouble();
    setState(() {
      _clearDays();
      for (var i = 0; i < days; i++) {
        final d = DateTime(_start.year, _start.month, _start.day + i);
        final amt = i == days - 1 ? total - base * (days - 1) : base;
        _dayCtrls[d] = TextEditingController(text: _fmtAmt(amt));
      }
    });
  }

  Future<void> _save() async {
    final id = _branchId;
    if (id == null || _dayCtrls.isEmpty) return;
    final targets = {
      for (final e in _dayCtrls.entries)
        e.key: double.tryParse(e.value.text.trim()) ?? 0,
    };
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await ref
          .read(branchTargetDatasourceProvider)
          .save(id, _sortedDays.last, targets);
      if (mounted) _snack('Target save ho gaya');
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label, {String? prefix, Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        prefixText: prefix,
        suffixIcon: suffix,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );

  @override
  Widget build(BuildContext context) {
    final branches = ref
        .watch(branchProvider)
        .branches
        .where((BranchModel b) => b.isActive)
        .toList()
      ..sort((a, b) => a.branchName.compareTo(b.branchName));
    final isMobile = MediaQuery.of(context).size.width < 768;

    final branchField = DropdownButtonFormField<String>(
      initialValue: _branchId,
      isExpanded: true,
      decoration: _dec('Branch'),
      items: [
        for (final b in branches)
          DropdownMenuItem(value: b.id, child: Text(b.branchName)),
      ],
      onChanged: _selectBranch,
    );
    final startField = InputDecorator(
      decoration: _dec('Start Date (Today)'),
      child: Text(_fmtDate(_start)),
    );
    final endField = InkWell(
      onTap: _pickEnd,
      child: InputDecorator(
        decoration: _dec('End Date',
            suffix: const Icon(Icons.calendar_today_outlined, size: 18)),
        child: Text(_end == null ? 'Select date' : _fmtDate(_end!),
            style: TextStyle(color: _end == null ? const Color(0xFF8A8FA3) : null)),
      ),
    );
    final totalField = TextField(
      controller: _totalCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: _dec('Total Target Amount', prefix: 'Rs. '),
      onSubmitted: (_) => _divide(),
    );
    final divideBtn = FilledButton(
      onPressed: _divide,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Divide Daily'),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Branch Target',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Target aaj se shuru hota hai. End date aur total amount daalein — amount har din mein barabar divide hoga, phir Saturday/Sunday jaise kisi bhi din ka target alag se badha sakte hain.',
            style: TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
          ),
          const SizedBox(height: 20),
          if (isMobile) ...[
            branchField,
            const SizedBox(height: 12),
            startField,
            const SizedBox(height: 12),
            endField,
            const SizedBox(height: 12),
            totalField,
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: divideBtn),
          ] else ...[
            Row(children: [
              Expanded(flex: 2, child: branchField),
              const SizedBox(width: 12),
              Expanded(child: startField),
              const SizedBox(width: 12),
              Expanded(child: endField),
              const SizedBox(width: 12),
              Expanded(child: totalField),
              const SizedBox(width: 12),
              divideBtn,
            ]),
          ],
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_dayCtrls.isNotEmpty)
            _buildDays(),
        ],
      ),
    );
  }

  Widget _buildDays() {
    final days = _sortedDays;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('${days.length} din  •  Total Rs. ${_fmtAmt(_daysSum)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Target'),
            ),
          ]),
          const SizedBox(height: 12),
          for (final d in days) _dayRow(d),
        ],
      ),
    );
  }

  Widget _dayRow(DateTime d) {
    final weekend = d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 110,
          child: Text(_fmtDate(d), style: const TextStyle(fontSize: 13)),
        ),
        Container(
          width: 46,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: weekend ? const Color(0xFFFFF1E0) : const Color(0xFFEAEFFD),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(_weekdays[d.weekday - 1],
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: weekend ? const Color(0xFFE56A00) : const Color(0xFF3E63DD))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            width: 200,
            child: TextField(
              controller: _dayCtrls[d],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              textAlign: TextAlign.end,
              onChanged: (_) => setState(() {}),
              decoration: _dec('Target', prefix: 'Rs. '),
            ),
          ),
        ),
      ]),
    );
  }
}
