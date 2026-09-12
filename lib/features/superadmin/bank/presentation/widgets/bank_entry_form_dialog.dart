import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bank_head_model.dart';
import '../providers/bank_providers.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class BankEntryFormDialog extends ConsumerStatefulWidget {
  final void Function({
    required String bankId,
    required String branchId,
    required String accountNumber,
    required double openingBalance,
  }) onSave;

  const BankEntryFormDialog({super.key, required this.onSave});

  @override
  ConsumerState<BankEntryFormDialog> createState() =>
      _BankEntryFormDialogState();
}

class _BankEntryFormDialogState extends ConsumerState<BankEntryFormDialog> {
  final _formKey     = GlobalKey<FormState>();
  final _accountCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();

  String? _selectedBankId;
  String? _selectedBranchId;

  // Tumhari DB branches — dynamic chahiye to branchProvider use karo
  static const List<Map<String, String>> _branches = [
    {
      'id':   '53743001-b131-4de8-8d1f-8613a88b1729',
      'name': 'Safi Shoes Branch 2',
    },
    {
      'id':   '6d597ef9-91ec-4003-a87b-7a0f63fb174d',
      'name': 'Safi Shoe',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedBranchId = _branches.first['id'];
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banksAsync = ref.watch(bankHeadsProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Bank Entry',
          style: TextStyle(fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 420,
        child: banksAsync.when(
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Failed to load banks: $e',
              style: const TextStyle(color: Colors.red)),
          data: (banks) {
            if (_selectedBankId == null && banks.isNotEmpty) {
              _selectedBankId = banks.first.id;
            }
            return Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bank
                  _buildBankDropdown(banks),
                  const SizedBox(height: 12),

                  // Branch
                  _buildBranchDropdown(),
                  const SizedBox(height: 12),

                  // Account Number
                  _buildField(
                    controller: _accountCtrl,
                    label: 'Account Number *',
                    icon: AppIcons.numbersOutlined,
                    required: true,
                  ),
                  const SizedBox(height: 12),

                  // Opening Balance
                  _buildField(
                    controller: _balanceCtrl,
                    label: 'Opening Balance *',
                    icon: AppIcons.currencyRupeeOutlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    required: true,
                    isNumeric: true,
                  ),
                ],
              ),
            );
          },
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
    if (_selectedBankId == null || _selectedBranchId == null) return;
    widget.onSave(
      bankId:         _selectedBankId!,
      branchId:       _selectedBranchId!,
      accountNumber:  _accountCtrl.text.trim(),
      openingBalance: double.parse(_balanceCtrl.text.trim()),
    );
    Navigator.pop(context);
  }

  Widget _buildBankDropdown(List<BankHeadModel> banks) {
    final selected =
        banks.where((b) => b.id == _selectedBankId).isNotEmpty
            ? banks.firstWhere((b) => b.id == _selectedBankId)
            : null;

    return DropdownButtonFormField<BankHeadModel>(
      value: selected,
      isExpanded: true,
      decoration: _decor('Bank *', AppIcons.accountBalanceOutlined),
      items: banks
          .map((b) =>
              DropdownMenuItem(value: b, child: Text(b.bankName)))
          .toList(),
      onChanged: (b) => setState(() => _selectedBankId = b?.id),
      validator: (_) =>
          _selectedBankId == null ? 'Select a bank' : null,
    );
  }

  Widget _buildBranchDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBranchId,
      isExpanded: true,
      decoration: _decor('Branch *', AppIcons.storeOutlined),
      items: _branches
          .map((b) =>
              DropdownMenuItem(value: b['id'], child: Text(b['name']!)))
          .toList(),
      onChanged: (v) => setState(() => _selectedBranchId = v),
      validator: (v) => v == null ? 'Select a branch' : null,
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String icon,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    bool isNumeric = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _decor(label, icon),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) {
          return '$label is required';
        }
        if (isNumeric && v != null && v.trim().isNotEmpty) {
          if (double.tryParse(v.trim()) == null) {
            return 'Enter a valid number';
          }
        }
        return null;
      },
    );
  }

  InputDecoration _decor(String label, String icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: AppIcon(icon, size: 16, color: const Color(0xFF8A8FA3)),
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
      );
}
