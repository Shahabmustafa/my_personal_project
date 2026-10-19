import 'package:flutter/material.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
/// Har report screen (invoice/return/exchange) ke top par stat cards ke liye
/// — bilkul branch_cash_counter screen ke _SummaryCard jaisa, taake app mein
/// look consistent rahe.
class ReportSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const ReportSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AppIcon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF8A8FA3), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// [ReportSummaryCard]s ki responsive row — wide screen par ek line, tang
/// screen par 2 columns, bohat tang (< 340) par 1 column.
class ReportSummaryCards extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  const ReportSummaryCards({super.key, required this.children, this.gap = 14});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final cols = w >= 700
          ? children.length
          : w >= 340
              ? 2
              : 1;
      final cardW = (w - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final card in children) SizedBox(width: cardW, child: card),
        ],
      );
    });
  }
}
