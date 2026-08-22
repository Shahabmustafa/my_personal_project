import 'package:flutter/material.dart';
import '../../data/model/warehouse_cash_counter_model.dart';

class CashCounterFormDialog extends StatefulWidget {
  final WarehouseCashCounterModel? record;
  final String warehouseId;
  final ValueChanged<WarehouseCashCounterModel> onSave;

  const CashCounterFormDialog({
    super.key,
    this.record,
    required this.warehouseId,
    required this.onSave,
  });

  @override
  State<CashCounterFormDialog> createState() => _CashCounterFormDialogState();
}

class _CashCounterFormDialogState extends State<CashCounterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late final TextEditingController _netAmountCtrl;
  late final TextEditingController _purchaseCtrl;
  late final TextEditingController _returnCtrl;
  late final TextEditingController _expenseCtrl;

  static const _blue = Color(0xFF3E63DD);

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _selectedDate = r?.counterDate ?? DateTime.now();
    _netAmountCtrl =
        TextEditingController(text: r != null ? r.netAmount.toStringAsFixed(2) : '');
    _purchaseCtrl =
        TextEditingController(text: r != null ? r.totalPurchase.toStringAsFixed(2) : '');
    _returnCtrl = TextEditingController(
        text: r != null ? r.totalReturnPurchase.toStringAsFixed(2) : '');
    _expenseCtrl =
        TextEditingController(text: r != null ? r.expense.toStringAsFixed(2) : '');
  }

  @override
  void dispose() {
    _netAmountCtrl.dispose();
    _purchaseCtrl.dispose();
    _returnCtrl.dispose();
    _expenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _blue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.record != null;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              color: _blue, size: 20),
          const SizedBox(width: 8),
          Text(isEdit ? 'Edit Cash Counter' : 'Add Cash Counter',
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

                // Date picker
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFFE7E9F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 18, color: Color(0xFF8A8FA3)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _formatDate(_selectedDate),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down,
                            color: Color(0xFF8A8FA3)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                _AmountField(
                  controller: _netAmountCtrl,
                  label: 'Net Amount *',
                  hint: '0.00',
                  icon: Icons.monetization_on_outlined,
                  required: true,
                ),
                const SizedBox(height: 14),
                _AmountField(
                  controller: _purchaseCtrl,
                  label: 'Total Purchase',
                  hint: '0.00',
                  icon: Icons.shopping_cart_outlined,
                ),
                const SizedBox(height: 14),
                _AmountField(
                  controller: _returnCtrl,
                  label: 'Total Return / Purchase Return',
                  hint: '0.00',
                  icon: Icons.assignment_return_outlined,
                ),
                const SizedBox(height: 14),
                _AmountField(
                  controller: _expenseCtrl,
                  label: 'Expense',
                  hint: '0.00',
                  icon: Icons.receipt_long_outlined,
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
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              widget.onSave(WarehouseCashCounterModel(
                id: widget.record?.id ?? '',
                warehouseId: widget.warehouseId,
                counterDate: _selectedDate,
                netAmount:
                    double.tryParse(_netAmountCtrl.text.trim()) ?? 0,
                totalPurchase:
                    double.tryParse(_purchaseCtrl.text.trim()) ?? 0,
                totalReturnPurchase:
                    double.tryParse(_returnCtrl.text.trim()) ?? 0,
                expense:
                    double.tryParse(_expenseCtrl.text.trim()) ?? 0,
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

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool required;

  const _AmountField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) {
          return '$label is required';
        }
        if (v != null && v.trim().isNotEmpty) {
          if (double.tryParse(v.trim()) == null) {
            return 'Enter a valid amount';
          }
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon:
            Icon(icon, size: 18, color: const Color(0xFF8A8FA3)),
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
            borderSide: const BorderSide(
                color: Color(0xFF3E63DD), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }
}
