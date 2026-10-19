import 'package:flutter/material.dart';

import '../utils/responsive.dart';

/// Page body shared by the invoice-style screens (purchase, sale, assign…).
///
/// Desktop/tablet: fixed column, the cart card fills the leftover height.
/// Mobile: the whole page scrolls and the cart gets a fixed-height window,
/// so the header, selector and footer never squeeze it to nothing.
class InvoicePageBody extends StatelessWidget {
  /// Widgets above the cart (title, header card, product selector…).
  final List<Widget> top;

  /// The cart card (already decorated).
  final Widget cart;

  /// Widgets below the cart (footer…).
  final List<Widget> bottom;

  const InvoicePageBody({
    super.key,
    required this.top,
    required this.cart,
    this.bottom = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive(context).isMobile;

    if (!isMobile) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...top,
            Expanded(child: cart),
            ...bottom,
          ],
        ),
      );
    }

    final cartHeight = (MediaQuery.of(context).size.height * 0.55)
        .clamp(320.0, 520.0)
        .toDouble();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ...top,
        SizedBox(height: cartHeight, child: cart),
        ...bottom,
      ],
    );
  }
}
