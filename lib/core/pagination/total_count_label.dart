import 'package:flutter/material.dart';

/// Groups an integer with thousands separators without pulling in `intl`.
/// `30245 -> "30,245"`.
String groupThousands(int value) {
  final s = value.abs().toString();
  final buf = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Small "Total Products: 30,245" line shown under a list header. Renders a
/// subtle placeholder while the first count is still loading.
class TotalCountLabel extends StatelessWidget {
  final String label;
  final int count;
  final bool loading;
  final TextStyle? style;

  const TotalCountLabel({
    super.key,
    required this.label,
    required this.count,
    this.loading = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ??
        const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3));
    return Text(
      loading ? 'Total $label: …' : 'Total $label: ${groupThousands(count)}',
      style: effectiveStyle,
    );
  }
}
