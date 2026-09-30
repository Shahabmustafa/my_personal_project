import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/app_icon.dart';
import '../../data/model/website_models.dart';
import '../../data/website_data.dart';
import '../provider/website_providers.dart';
import '../theme/website_theme.dart';
import 'reveal.dart';
import 'website_widgets.dart';

/// Grid card for a shoe: photo, name, sizes, price and an "Order Now" button.
class ShoeCard extends StatelessWidget {
  final Shoe shoe;

  const ShoeCard({super.key, required this.shoe});

  @override
  Widget build(BuildContext context) {
    final off = shoe.discountPercent;
    return Hoverable(
      builder: (context, hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: hovered ? WShadows.soft : null,
        ),
        child: Material(
          color: WColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: hovered ? WColors.tan.withValues(alpha: .6) : WColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => showShoeDialog(context, shoe),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ZoomImage(shoe.image, zoomed: hovered),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Row(
                          children: [
                            if (shoe.isNew) const _Badge('NEW', WColors.ink),
                            if (shoe.isNew && off != null) const SizedBox(width: 6),
                            if (off != null) _Badge('-$off%', WColors.red),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shoe.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WText.body(14, color: WColors.ink, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Sizes ${shoe.sizes.first}–${shoe.sizes.last}',
                        style: WText.body(12, color: WColors.muted),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: PriceText(shoe: shoe)),
                          _OrderButton(onTap: () => showShoeDialog(context, shoe)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30)),
    child: Text(
      text,
      style: WText.body(10, color: Colors.white, weight: FontWeight.w700).copyWith(letterSpacing: .6),
    ),
  );
}

/// Price, with the pre-discount price struck through when there is one.
class PriceText extends StatelessWidget {
  final Shoe shoe;
  final double size;

  const PriceText({super.key, required this.shoe, this.size = 15});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(formatPrice(shoe.price), style: WText.body(size, color: WColors.red, weight: FontWeight.w700)),
        if (shoe.oldPrice != null)
          Text(
            formatPrice(shoe.oldPrice!),
            style: WText.body(size * .78, color: WColors.mutedLight).copyWith(decoration: TextDecoration.lineThrough),
          ),
      ],
    );
  }
}

class _OrderButton extends StatelessWidget {
  final VoidCallback onTap;

  const _OrderButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WColors.red,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text('Order', style: WText.body(12.5, color: Colors.white, weight: FontWeight.w600)),
        ),
      ),
    );
  }
}

/// Responsive shoe grid: 2 columns on phones, up to 4 on wide screens.
class ShoeGrid extends StatelessWidget {
  final List<Shoe> shoes;

  const ShoeGrid({super.key, required this.shoes});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 14.0;
        final cols = (c.maxWidth / 260).floor().clamp(2, 4);
        final cellWidth = (c.maxWidth - gap * (cols - 1)) / cols;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: shoes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            // Image scales with the card; the text block below it is fixed height.
            mainAxisExtent: cellWidth * 0.9 + 104,
          ),
          // Keyed by shoe so cards animate in again when the category changes.
          itemBuilder: (_, i) => Reveal(
            key: ValueKey(shoes[i].id),
            delay: Duration(milliseconds: 80 * (i % cols)),
            child: ShoeCard(shoe: shoes[i]),
          ),
        );
      },
    );
  }
}

/// Horizontal category pill tabs shared by Home and Shop.
/// With [showAll], an "All" chip comes first and a null [selected] means All.
class CategoryChips extends StatelessWidget {
  final List<ShoeCategory> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool showAll;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.showAll = false,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <(String?, String, String)>[
      if (showAll) (null, 'All', ''),
      for (final c in categories) (c.id, c.name, c.image),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (id, name, image) = chips[i];
          final active = id == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () => onSelected(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.fromLTRB(image.isEmpty ? 18 : 5, 5, 18, 5),
              decoration: BoxDecoration(
                color: active ? WColors.ink : WColors.paper,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: active ? WColors.ink : WColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (image.isEmpty)
                    AppIcon(AppIcons.categoryOutlined, size: 15, color: active ? WColors.tanLight : WColors.red)
                  else
                    ClipOval(child: SizedBox(width: 32, height: 32, child: ShoeImage(image))),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: WText.body(13.5, color: active ? Colors.white : WColors.ink, weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Size + quantity picker. "Add to cart" keeps browsing; "Order Now" also opens the cart.
Future<void> showShoeDialog(BuildContext context, Shoe shoe) {
  return showDialog(
    context: context,
    builder: (_) => _ShoeDialog(shoe: shoe),
  );
}

class _ShoeDialog extends ConsumerStatefulWidget {
  final Shoe shoe;

  const _ShoeDialog({required this.shoe});

  @override
  ConsumerState<_ShoeDialog> createState() => _ShoeDialogState();
}

class _ShoeDialogState extends ConsumerState<_ShoeDialog> {
  int? _size;
  int _qty = 1;

  void _add({required bool checkout}) {
    ref.read(cartProvider.notifier).add(widget.shoe, _size!, qty: _qty);
    Navigator.pop(context);
    if (checkout) {
      ref.read(websiteTabProvider.notifier).state = WebsiteTab.cart;
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${widget.shoe.name} (size $_size) added to cart')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final shoe = widget.shoe;
    final category = SafiData.category(shoe.categoryId);
    final wide = MediaQuery.sizeOf(context).width >= 760;

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(aspectRatio: wide ? .9 : 1.5, child: ShoeImage(shoe.image)),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (category != null) Text(category.name.toUpperCase(), style: WText.eyebrow()),
        const SizedBox(height: 8),
        Text(shoe.name, style: WText.display(26)),
        const SizedBox(height: 10),
        PriceText(shoe: shoe, size: 20),
        if (shoe.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(shoe.description, style: WText.body(14, color: WColors.muted, height: 1.6)),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            const AppIcon(AppIcons.straightenOutlined, size: 15, color: WColors.ink),
            const SizedBox(width: 8),
            Text('Select size (EU)', style: WText.body(13.5, color: WColors.ink, weight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in shoe.sizes)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _size = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 50,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _size == s ? WColors.ink : WColors.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _size == s ? WColors.ink : WColors.line),
                  ),
                  child: Text(
                    '$s',
                    style: WText.body(14, color: _size == s ? Colors.white : WColors.ink, weight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text('Quantity', style: WText.body(13.5, color: WColors.ink, weight: FontWeight.w600)),
            const SizedBox(width: 14),
            QtyStepper(qty: _qty, onChanged: (q) => setState(() => _qty = q.clamp(1, 20))),
          ],
        ),
        const SizedBox(height: 24),
        if (_size == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('Choose a size to continue', style: WText.body(12.5, color: WColors.red)),
          ),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: 'Add to cart',
                style: PillStyle.outlineDark,
                small: true,
                expand: true,
                onPressed: _size == null ? null : () => _add(checkout: false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(
                label: 'Order Now',
                small: true,
                expand: true,
                icon: AppIcons.chevronRight,
                onPressed: _size == null ? null : () => _add(checkout: true),
              ),
            ),
          ],
        ),
      ],
    );

    return Dialog(
      backgroundColor: WColors.cream,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 860 : 480),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: image),
                        const SizedBox(width: 28),
                        Expanded(child: details),
                      ],
                    )
                  : Column(children: [image, const SizedBox(height: 20), details]),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: WColors.paper,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const AppIcon(AppIcons.close, size: 16, color: WColors.ink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// − qty + control.
class QtyStepper extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;

  const QtyStepper({super.key, required this.qty, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget btn(String icon, int next) => InkWell(
      customBorder: const CircleBorder(),
      onTap: () => onChanged(next),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: AppIcon(icon, size: 14, color: WColors.ink),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: WColors.paper,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: WColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(AppIcons.remove, qty - 1),
          SizedBox(
            width: 28,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: WText.body(14, color: WColors.ink, weight: FontWeight.w600),
            ),
          ),
          btn(AppIcons.add, qty + 1),
        ],
      ),
    );
  }
}
