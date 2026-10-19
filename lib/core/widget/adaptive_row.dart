import 'package:flutter/material.dart';

/// Form-field row: side by side on wide screens, stacked full-width on mobile.
///
/// [items] is a normal `Row` children list — fields wrapped in `Expanded`
/// plus optional `SizedBox` gaps / `Spacer`s. On mobile only the `Expanded`
/// children are kept (unwrapped) and stacked with [gap] between them.
Widget adaptiveFieldRow(
  bool isMobile,
  List<Widget> items, {
  double gap = 8,
}) {
  if (!isMobile) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: items);
  }
  final fields = [
    for (final w in items)
      if (w is Expanded) w.child,
  ];
  return Column(
    children: [
      for (var i = 0; i < fields.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        fields[i],
      ],
    ],
  );
}
