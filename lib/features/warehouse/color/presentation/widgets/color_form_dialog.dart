import 'package:flutter/material.dart';
import '../../data/model/color_model.dart';

class ColorFormDialog extends StatefulWidget {
  final ColorModel? item;
  final ValueChanged<ColorModel> onSave;

  const ColorFormDialog({
    super.key,
    this.item,
    required this.onSave,
  });

  @override
  State<ColorFormDialog> createState() => _ColorFormDialogState();
}

class _ColorFormDialogState extends State<ColorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.item?.name ?? '');
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
          const Icon(Icons.color_lens_outlined, color: Color(0xFF3E63DD), size: 20),
          const SizedBox(width: 8),
          Text(isEdit ? 'Edit Color' : 'Add Color',
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
              labelText: 'Color Name *',
              hintText: 'e.g. Red',
              labelStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.color_lens_outlined, size: 18, color: Color(0xFF8A8FA3)),
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
                (v == null || v.trim().isEmpty) ? 'Color Name is required' : null,
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
              widget.onSave(ColorModel(
                id: widget.item?.id ?? '',
                name: _ctrl.text.trim(),
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
