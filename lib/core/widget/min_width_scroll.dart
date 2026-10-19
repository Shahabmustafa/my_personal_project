import 'package:flutter/material.dart';

/// Flex-based (Row + Expanded) tables need a minimum width to stay readable.
/// Wide screens: [child] simply fills the available width. Narrower screens:
/// [child] is laid out at [minWidth] and scrolls horizontally.
///
/// [child] may contain vertical `Expanded`/`ListView`s — the height from the
/// parent is passed through unchanged.
class MinWidthScroll extends StatelessWidget {
  final double minWidth;
  final Widget child;

  const MinWidthScroll({super.key, required this.child, this.minWidth = 900});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= minWidth) return child;
        return Scrollbar(
          notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: minWidth,
              height: c.hasBoundedHeight ? c.maxHeight : null,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
