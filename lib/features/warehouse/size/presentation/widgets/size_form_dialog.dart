import 'package:flutter/material.dart';
import '../../data/model/size_model.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class SizeFormDialog extends StatefulWidget {
  final SizeModel? item;
  final ValueChanged<SizeModel> onSave;

  const SizeFormDialog({
    super.key,
    this.item,
    required this.onSave,
  });

  @override
  State<SizeFormDialog> createState() => _SizeFormDialogState();
}

class _SizeFormDialogState extends State<SizeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.item?.number ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const AppIcon(AppIcons.formatSizeOutlined, color: Color(0xFF3E63DD), size: 20),
          const SizedBox(width: 8),
          Text(isEdit ? 'Edit Size' : 'Add Size',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Size Number *',
              hintText: 'e.g. 42',
              labelStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Center(child: AppIcon(AppIcons.formatSizeOutlined, size: 16, color: Color(0xFF8A8FA3))),
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
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Size Number is required' : null,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              widget.onSave(SizeModel(
                id: widget.item?.id ?? '',
                number: _ctrl.text.trim(),
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
