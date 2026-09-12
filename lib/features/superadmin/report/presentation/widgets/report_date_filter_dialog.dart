import 'package:flutter/material.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
/// Start/end date pick karne wala alert dialog — "Apply" par (start, end)
/// wapas karta hai (dono ya ek hi bhi ho sakta hai), "Clear" par (null, null).
class ReportDateFilterDialog extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const ReportDateFilterDialog({super.key, this.initialStart, this.initialEnd});

  @override
  State<ReportDateFilterDialog> createState() => _ReportDateFilterDialogState();
}

class _ReportDateFilterDialogState extends State<ReportDateFilterDialog> {
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end ?? _start ?? DateTime.now(),
      firstDate: _start ?? DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _end = picked);
  }

  String _fmt(DateTime? d) =>
      d == null ? 'Select date' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        AppIcon(AppIcons.filterAltOutlined, size: 20),
        SizedBox(width: 8),
        Text('Filter by Date', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DateField(label: 'Start Date', value: _fmt(_start), onTap: _pickStart),
          const SizedBox(height: 12),
          _DateField(label: 'End Date', value: _fmt(_end), onTap: _pickEnd),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, const (null, null)),
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_start, _end)),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: const TextFieldIcon(AppIcons.calendarTodayOutlined, size: 12),
        ),
        child: Text(value, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}
