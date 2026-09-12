import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widget/app_dropdown.dart';
import '../../../../auth/data/model/user_model.dart';
import '../../../branch/data/model/branch_model.dart';
import '../../../branch/presentation/providers/branch_provider.dart';
import '../../../../user/presentation/providers/user_provider.dart';
import '../providers/employee_salary_providers.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class EmployeeSalaryFormDialog extends ConsumerStatefulWidget {
  final void Function({
    required String userId,
    required String branchId,
    required double salary,
    required double commissionPercent,
    required double totalSales,
    required double totalSalesReturn,
  }) onSave;

  const EmployeeSalaryFormDialog({super.key, required this.onSave});

  @override
  ConsumerState<EmployeeSalaryFormDialog> createState() =>
      _EmployeeSalaryFormDialogState();
}

class _EmployeeSalaryFormDialogState
    extends ConsumerState<EmployeeSalaryFormDialog> {
  final _formKey        = GlobalKey<FormState>();
  final _salaryCtrl     = TextEditingController();
  final _commissionCtrl = TextEditingController(text: '0');

  String? _selectedUserId;
  String? _selectedBranchId;
  String? _userError;
  String? _branchError;

  static const _eligibleRoles = {'salesman', 'manager'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).loadAllUsers();
      ref.read(branchProvider.notifier).loadAllBranches();
    });
  }

  @override
  void dispose() {
    _salaryCtrl.dispose();
    _commissionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState   = ref.watch(userProvider);
    final branchState = ref.watch(branchProvider);
    final salariesAsync = ref.watch(employeeSalariesProvider);

    // Ek employee (cashier/salesman/manager) sirf ek hi branch me kaam kar
    // sakta hai — jis user ka pehle se kisi bhi branch me salary record ban
    // chuka hai, use dobara doosri branch ke liye is dropdown me nahi
    // dikhate (naya record banane ka matlab hoga wo do branches me ho gaya).
    final assignedBranchByUser = <String, String>{
      for (final s in salariesAsync.value ?? const [])
        s.userId: s.branchName,
    };
    final eligibleUsers = userState.users
        .where((u) =>
            _eligibleRoles.contains(u.role) &&
            !assignedBranchByUser.containsKey(u.id))
        .toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Employee Salary',
          style: TextStyle(fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 420,
        child: (userState.isLoading || branchState.isLoading)
            ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildUserDropdown(eligibleUsers),
                      const SizedBox(height: 12),
                      _buildBranchDropdown(branchState.branches),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _salaryCtrl,
                        label: 'Salary *',
                        icon: AppIcons.currencyRupeeOutlined,
                        required: true,
                        isNumeric: true,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _commissionCtrl,
                        label: 'Commission % *',
                        icon: AppIcons.percentOutlined,
                        required: true,
                        isNumeric: true,
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3E63DD),
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final existing = (ref.read(employeeSalariesProvider).value ?? const [])
        .where((s) => s.userId == _selectedUserId)
        .toList();

    setState(() {
      _userError = _selectedUserId == null
          ? 'Select an employee'
          : existing.isNotEmpty
              ? 'Already assigned to ${existing.first.branchName} — an employee can only work at one branch'
              : null;
      _branchError = _selectedBranchId == null ? 'Select a branch' : null;
    });
    if (_userError != null || _branchError != null) return;

    widget.onSave(
      userId:            _selectedUserId!,
      branchId:          _selectedBranchId!,
      salary:            double.parse(_salaryCtrl.text.trim()),
      commissionPercent: double.parse(_commissionCtrl.text.trim()),
      totalSales:        0,
      totalSalesReturn:  0,
    );
    Navigator.pop(context);
  }

  Widget _buildUserDropdown(List<UserModel> users) {
    final selected = users.where((u) => u.id == _selectedUserId).isNotEmpty
        ? users.firstWhere((u) => u.id == _selectedUserId)
        : null;

    return AppSearchDropdown<UserModel>(
      label: 'Employee (Salesman / Manager)',
      isRequired: true,
      items: users,
      selectedItem: selected,
      itemLabel: (u) => '${u.username} (${u.roleDisplayName})',
      prefixIcon: const Center(child: AppIcon(AppIcons.personOutline, size: 16)),
      errorText: _userError,
      onChanged: (u) => setState(() {
        _selectedUserId = u?.id;
        _userError = null;
      }),
    );
  }

  Widget _buildBranchDropdown(List<BranchModel> branches) {
    final selected =
        branches.where((b) => b.id == _selectedBranchId).isNotEmpty
            ? branches.firstWhere((b) => b.id == _selectedBranchId)
            : null;

    return AppSearchDropdown<BranchModel>(
      label: 'Branch',
      isRequired: true,
      items: branches,
      selectedItem: selected,
      itemLabel: (b) => b.branchName,
      prefixIcon: const Center(child: AppIcon(AppIcons.storeOutlined, size: 16)),
      errorText: _branchError,
      onChanged: (b) => setState(() {
        _selectedBranchId = b?.id;
        _branchError = null;
      }),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String icon,
    bool required = false,
    bool isNumeric = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))]
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Center(child: AppIcon(icon, size: 16, color: const Color(0xFF8A8FA3))),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color(0xFF3E63DD), width: 1.5)),
      ),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) {
          return '$label is required';
        }
        if (isNumeric && v != null && v.trim().isNotEmpty) {
          if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
        }
        return null;
      },
    );
  }
}
