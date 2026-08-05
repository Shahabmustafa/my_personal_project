import 'package:flutter/material.dart';
import '../../data/model/company_model.dart';

class CompanyFormDialog extends StatefulWidget {
  final CompanyModel? company;
  final String warehouseId;
  final ValueChanged<CompanyModel> onSave;

  const CompanyFormDialog({
    super.key,
    this.company,
    required this.warehouseId,
    required this.onSave,
  });

  @override
  State<CompanyFormDialog> createState() => _CompanyFormDialogState();
}

class _CompanyFormDialogState extends State<CompanyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _balanceCtrl;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _phoneCtrl = TextEditingController(text: c?.phoneNumber ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _balanceCtrl = TextEditingController(
        text: (c?.openingBalance != null && c!.openingBalance != 0)
            ? c.openingBalance.toString()
            : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.company != null;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.business_outlined,
              color: Color(0xFF3E63DD), size: 20),
          const SizedBox(width: 8),
          Text(isEdit ? 'Edit Company' : 'Add Company',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 17)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                _Field(
                  controller: _nameCtrl,
                  label: 'Company Name *',
                  hint: 'ABC Traders',
                  icon: Icons.business_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Company name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  hint: '0300-0000000',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'company@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$');
                      if (!emailRegex.hasMatch(v.trim())) {
                        return 'Enter a valid email';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _addressCtrl,
                  label: 'Address',
                  hint: 'Street, City',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _balanceCtrl,
                  label: 'Opening Balance',
                  hint: '0.00',
                  icon: Icons.account_balance_wallet_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      if (double.tryParse(v) == null) {
                        return 'Enter a valid amount';
                      }
                    }
                    return null;
                  },
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              widget.onSave(CompanyModel(
                id: widget.company?.id ?? '',
                warehouseId: widget.warehouseId,
                name: _nameCtrl.text.trim(),
                phoneNumber: _phoneCtrl.text.trim(),
                email: _emailCtrl.text.trim(),
                address: _addressCtrl.text.trim(),
                openingBalance:
                    double.tryParse(_balanceCtrl.text.trim()) ?? 0,
              ));
              Navigator.pop(context);
            }
          },
          child: Text(isEdit ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF8A8FA3)),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }
}
