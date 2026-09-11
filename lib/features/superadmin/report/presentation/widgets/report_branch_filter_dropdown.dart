import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../branch/presentation/providers/branch_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
/// Report screens ke top bar mein "All Branches" + har branch ka dropdown —
/// select karne par sirf usi branch ka data reports mein dikhta hai.
class ReportBranchFilterDropdown extends ConsumerStatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const ReportBranchFilterDropdown({super.key, required this.value, required this.onChanged});

  @override
  ConsumerState<ReportBranchFilterDropdown> createState() => _ReportBranchFilterDropdownState();
}

class _ReportBranchFilterDropdownState extends ConsumerState<ReportBranchFilterDropdown> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(branchProvider).branches.isEmpty) {
        ref.read(branchProvider.notifier).loadAllBranches();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchProvider).branches;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDADDE5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: widget.value,
          hint: const Text('All Branches', style: TextStyle(fontSize: 13)),
          icon: const AppIcon(AppIcons.arrowDropDown, size: 18),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('All Branches')),
            for (final b in branches)
              DropdownMenuItem<String?>(value: b.id, child: Text(b.branchName)),
          ],
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
