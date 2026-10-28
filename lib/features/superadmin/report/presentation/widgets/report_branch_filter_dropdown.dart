import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../branch/presentation/providers/branch_provider.dart';

import 'package:safishoe_app/core/widget/branch_filter_dropdown.dart';
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

    return BranchFilterDropdown(
      label: 'Branch',
      allLabel: 'All Branches',
      options: {for (final b in branches) b.id: b.branchName},
      value: widget.value,
      onChanged: widget.onChanged,
    );
  }
}
