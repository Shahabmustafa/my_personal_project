import 'package:flutter/material.dart';
import '../../data/model/branch_model.dart';

class BranchFormDialog extends StatefulWidget {
  final BranchModel? branch;
  final ValueChanged<BranchModel> onSave;

  const BranchFormDialog({super.key, this.branch, required this.onSave});

  @override
  State<BranchFormDialog> createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends State<BranchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    _name = TextEditingController(text: b?.branchName ?? '');
    _address = TextEditingController(text: b?.address ?? '');
    _phone = TextEditingController(text: b?.phoneNumber ?? '');
    _city = TextEditingController(text: b?.city ?? '');
    _status = b?.status ?? 'active';
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.branch != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 480;
    final dialogWidth = isMobile ? screenWidth - 48 : 400.0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 24, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      scrollable: true,
      title: Text(isEdit ? 'Edit Branch' : 'Add Branch',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: dialogWidth,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(controller: _name, label: 'Branch Name *', required: true),
              const SizedBox(height: 12),
              _field(controller: _address, label: 'Address'),
              const SizedBox(height: 12),
              _field(controller: _city, label: 'City'),
              const SizedBox(height: 12),
              _field(controller: _phone, label: 'Phone Number', keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: _decor('Status'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'active'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3E63DD),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              widget.onSave(BranchModel(
                id: widget.branch?.id ?? '',
                branchName: _name.text.trim(),
                address: _address.text.trim(),
                phoneNumber: _phone.text.trim(),
                city: _city.text.trim(),
                status: _status,
                // Discount settings is dialog se edit nahi hote — jo pehle
                // set the (Discount screens se) unhe preserve karo.
                canApplyInvoiceDiscount:
                    widget.branch?.canApplyInvoiceDiscount ?? false,
                maxInvoiceDiscountPct:
                    widget.branch?.maxInvoiceDiscountPct ?? 0,
              ));
              Navigator.pop(context);
            }
          },
          child: Text(isEdit ? 'Update' : 'Save'),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _decor(label),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null : null,
    );
  }

  InputDecoration _decor(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF3E63DD), width: 1.5)),
      );
}
