import 'package:flutter/material.dart';

import 'app_icon.dart';
import '../constants/app_icons.dart';

/// "Low Stock" (1–4 pairs) / "Out of Stock" (0) toggle buttons for the stock
/// inventory screens. [level] is `'low'`, `'out'` or null (all stock);
/// tapping the active button clears it.
class StockLevelFilter extends StatelessWidget {
  final String? level;
  final int lowCount;
  final int outCount;
  final ValueChanged<String?> onChanged;

  const StockLevelFilter({
    super.key,
    required this.level,
    required this.lowCount,
    required this.outCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button('low', 'Low Stock', lowCount, AppIcons.warningAmberOutlined,
            Colors.orange.shade700),
        const SizedBox(width: 10),
        _button('out', 'Out of Stock', outCount, AppIcons.block,
            Colors.red.shade600),
      ],
    );
  }

  Widget _button(
      String value, String label, int count, String icon, Color color) {
    final active = level == value;
    return OutlinedButton.icon(
      onPressed: () => onChanged(active ? null : value),
      icon: AppIcon(icon, size: 18, color: active ? Colors.white : color),
      label: Text('$label ($count)'),
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? Colors.white : color,
        backgroundColor: active ? color : Colors.white,
        side: BorderSide(color: active ? color : const Color(0xFFE7E9F0)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
