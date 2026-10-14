import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widget/app_dropdown.dart';
import '../../../../branch/expense/presentation/provider/expense_provider.dart';
import '../../../../branch/expense/presentation/screen/expense_screen.dart';
import '../../../head_office_assign_stock/presentation/providers/ho_assign_stock_provider.dart';
import '../../../shared/current_head_office_provider.dart';

/// Superadmin ka expense — head office ka apna kharcha, ya kisi bhi branch
/// ka expense (branch ke cash counter se minus hota hai, branch screen jaisa).
class SuperadminExpenseScreen extends ConsumerStatefulWidget {
  const SuperadminExpenseScreen({super.key});

  @override
  ConsumerState<SuperadminExpenseScreen> createState() =>
      _SuperadminExpenseScreenState();
}

class _ScopeOption {
  final String label;
  final ExpenseScope scope;
  const _ScopeOption(this.label, this.scope);
}

class _SuperadminExpenseScreenState
    extends ConsumerState<SuperadminExpenseScreen> {
  /// Null = Head Office.
  String? _branchId;

  @override
  Widget build(BuildContext context) {
    final headOfficeId = ref.watch(currentHeadOfficeIdProvider);
    final branches = ref.watch(hoAssignBranchesProvider).value ?? const [];

    final options = [
      _ScopeOption('Head Office', ExpenseScope.headOffice(headOfficeId)),
      for (final b in branches)
        _ScopeOption(b.branchName, ExpenseScope.branch(b.id)),
    ];
    final selected = options.firstWhere(
      (o) => _branchId == null
          ? o.scope.isHeadOffice
          : !o.scope.isHeadOffice && o.scope.id == _branchId,
      orElse: () => options.first,
    );

    return ExpenseScreen(
      key: ValueKey(selected.scope.hashCode),
      scope: selected.scope,
      scopePicker: SizedBox(
        width: 320,
        child: AppSearchDropdown<_ScopeOption>(
          label: 'Expense For',
          items: options,
          selectedItem: selected,
          itemLabel: (o) => o.label,
          onChanged: (o) {
            if (o == null) return;
            setState(
                () => _branchId = o.scope.isHeadOffice ? null : o.scope.id);
          },
        ),
      ),
    );
  }
}
