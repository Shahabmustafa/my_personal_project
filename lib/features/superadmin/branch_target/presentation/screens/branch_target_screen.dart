import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../branch/data/model/branch_model.dart';
import '../../../branch/presentation/providers/branch_provider.dart';
import '../../../branch/presentation/providers/branch_state.dart';
import '../../../report/data/model/branch_target_row.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';

/// Superadmin/admin yahan har branch ka monthly sale target (Rs.) set karta
/// hai. "Branch Target" report isko current date se mahine ke aakhir (30)
/// tak bache dinon mein divide karke daily target nikalta hai aur us din ki
/// net sale se compare karta hai. 0 = target set nahi.
class BranchTargetScreen extends ConsumerStatefulWidget {
  const BranchTargetScreen({super.key});

  @override
  ConsumerState<BranchTargetScreen> createState() => _BranchTargetScreenState();
}

class _BranchTargetScreenState extends ConsumerState<BranchTargetScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(branchProvider.notifier).loadAllBranches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchState = ref.watch(branchProvider);

    ref.listen<BranchState>(branchProvider, (_, next) {
      if (next.status == BranchStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final filtered = branchState.branches
        .where((b) => b.branchName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Branch Target',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  'Har branch ka monthly sale target set karein — current date se mahine ke aakhir (30) tak bache dinon mein taqseem karke daily target Branch Target report mein dikhega.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search branches...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
                prefixIcon: const TextFieldIcon(AppIcons.search, size: 24, color: Color(0xFF8A8FA3)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
              ),
            ),
          ),
          Expanded(
            child: branchState.isLoading && branchState.branches.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(
                        child: Text('No branches found',
                            style: TextStyle(color: Color(0xFF8A8FA3))))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _BranchTargetRow(
                          key: ValueKey(filtered[i].id),
                          branch: filtered[i],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _BranchTargetRow extends ConsumerStatefulWidget {
  final BranchModel branch;
  const _BranchTargetRow({super.key, required this.branch});

  @override
  ConsumerState<_BranchTargetRow> createState() => _BranchTargetRowState();
}

class _BranchTargetRowState extends ConsumerState<_BranchTargetRow> {
  late final TextEditingController _ctrl;

  String get _savedText => _fmt(widget.branch.monthlyTarget);
  bool get _dirty => _ctrl.text.trim() != _savedText;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _savedText);
  }

  @override
  void didUpdateWidget(covariant _BranchTargetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Save ke baad model refresh hone par field ko synced rakho (jab tak
    // user usi field mein aur type na kar raha ho).
    if (!_dirty && oldWidget.branch.monthlyTarget != widget.branch.monthlyTarget) {
      _ctrl.text = _savedText;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  void _save() {
    final raw = double.tryParse(_ctrl.text.trim()) ?? 0;
    final target = raw < 0 ? 0.0 : raw;
    _ctrl.text = _fmt(target);
    FocusScope.of(context).unfocus();
    ref.read(branchProvider.notifier).updateBranch(
          widget.branch.copyWith(monthlyTarget: target),
        );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.branch;
    final daily = BranchTargetRow.dailyTargetFor(b.monthlyTarget);
    final isMobile = MediaQuery.of(context).size.width < 768;

    final icon = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFFD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const AppIcon(AppIcons.flagOutlined, color: Color(0xFF3E63DD), size: 20),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(b.branchName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Text(
          b.monthlyTarget > 0
              ? 'Daily target: Rs. ${daily.toStringAsFixed(0)}'
              : 'No target set',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: b.monthlyTarget > 0
                ? const Color(0xFF2E7D32)
                : const Color(0xFF8A8FA3),
          ),
        ),
      ],
    );

    final field = TextField(
      controller: _ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      textAlign: TextAlign.end,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _save(),
      decoration: InputDecoration(
        labelText: 'Monthly Target',
        prefixText: 'Rs. ',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    final saveBtn = FilledButton(
      onPressed: _dirty ? _save : null,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Save'),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [icon, const SizedBox(width: 14), Expanded(child: info)]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: field),
                  const SizedBox(width: 8),
                  saveBtn,
                ]),
              ],
            )
          : Row(
              children: [
                icon,
                const SizedBox(width: 14),
                Expanded(child: info),
                SizedBox(width: 150, child: field),
                const SizedBox(width: 8),
                saveBtn,
              ],
            ),
    );
  }
}
