import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widget/app_dropdown.dart';
import '../../../../branch/expense/presentation/provider/expense_provider.dart';
import '../../../../branch/expense/presentation/screen/expense_screen.dart';
import '../../../head_office_assign_stock/data/models/ho_assign_stock_model.dart';
import '../../../head_office_assign_stock/presentation/providers/ho_assign_stock_provider.dart';
import '../../../shared/current_head_office_provider.dart';

/// Head office (admin) ka apna kharcha — head office cash counter se minus.
class HeadOfficeExpenseScreen extends ConsumerWidget {
  const HeadOfficeExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headOfficeId = ref.watch(currentHeadOfficeIdProvider);
    return ExpenseScreen(
      key: ValueKey('ho-$headOfficeId'),
      title: 'Head Office Expense',
      scope: ExpenseScope.headOffice(headOfficeId),
    );
  }
}

/// Admin kisi bhi branch ka expense add/edit kar sakta hai — branch ke cash
/// counter se minus hota hai, bilkul branch screen jaisa.
class BranchExpenseScreen extends ConsumerStatefulWidget {
  const BranchExpenseScreen({super.key});

  @override
  ConsumerState<BranchExpenseScreen> createState() =>
      _BranchExpenseScreenState();
}

class _BranchExpenseScreenState extends ConsumerState<BranchExpenseScreen> {
  static const _allOption = ExpenseBranchOption('', 'All Branches');

  /// Null = All Branches (default).
  String? _branchId;

  @override
  Widget build(BuildContext context) {
    final branches =
        ref.watch(hoAssignBranchesProvider).value ?? const <HoBranchModel>[];
    final options = [
      _allOption,
      for (final b in branches) ExpenseBranchOption(b.id, b.branchName),
    ];
    var selected = _allOption;
    for (final o in options) {
      if (o.id == _branchId) selected = o;
    }
    final isAll = selected == _allOption;

    return ExpenseScreen(
      key: ValueKey('branch-${selected.id}'),
      title: 'Branch Expense',
      scope: isAll
          ? const ExpenseScope.allBranches()
          : ExpenseScope.branch(selected.id),
      branchOptions: options.sublist(1),
      // Specific branch dekh rahe ho to jis branch mein expense add hua wahi
      // dikhao; All Branches mein sab dikhta hi hai.
      onBranchSaved: (id) {
        if (!isAll) setState(() => _branchId = id);
      },
      scopePicker: SizedBox(
        width: 320,
        child: AppSearchDropdown<ExpenseBranchOption>(
          label: 'Branch',
          items: options,
          selectedItem: selected,
          itemLabel: (b) => b.name,
          onChanged: (b) {
            if (b != null) setState(() => _branchId = b.id.isEmpty ? null : b.id);
          },
        ),
      ),
    );
  }
}
