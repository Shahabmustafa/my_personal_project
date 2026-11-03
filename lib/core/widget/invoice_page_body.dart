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

  /// true: desktop par bhi poora page scroll hota hai aur cart ko fixed
  /// height window milti hai — jin screens ka upar ka hissa lamba ho (jaise
  /// exchange ki return-items list) wahan cart rows na dab jayein.
  final bool scrollOnDesktop;

  const InvoicePageBody({
    super.key,
    required this.top,
    required this.cart,
    this.bottom = const [],
    this.scrollOnDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive(context).isMobile;

    if (!isMobile && !scrollOnDesktop) {
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
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      children: [
        ...top,
        SizedBox(height: cartHeight, child: cart),
        ...bottom,
      ],
    );
  }
}
