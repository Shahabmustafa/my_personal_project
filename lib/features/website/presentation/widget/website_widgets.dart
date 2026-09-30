import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/app_icon.dart';
import '../../data/website_data.dart';
import '../theme/website_theme.dart';
import 'reveal.dart';

const wMaxContentWidth = 1260.0;

/// Side gutter used by every section.
double wGutter(BuildContext context) => MediaQuery.sizeOf(context).width < 640 ? 20.0 : 28.0;

/// Centers content at the site's max width with its side gutter.
class WSection extends StatelessWidget {
  final Widget child;
  final Color? background;
  final bool reveal; // fade the content in when it scrolls into view

  const WSection({super.key, required this.child, this.background, this.reveal = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      padding: EdgeInsets.symmetric(horizontal: wGutter(context), vertical: 56),
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: wMaxContentWidth),
        child: reveal ? Reveal(child: child) : child,
      ),
    );
  }
}

/// Shoe photo — a network URL or a bundled asset — with a warm placeholder
/// while loading, when empty, or on error.
class ShoeImage extends StatelessWidget {
  final String source;
  final BoxFit fit;

  const ShoeImage(this.source, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) return const _Placeholder();
    Widget frame(BuildContext _, Widget child, int? frame, bool sync) =>
        sync || frame != null ? child : const _Placeholder();
    Widget error(BuildContext _, Object _, StackTrace? _) => const _Placeholder();

    return source.startsWith('http')
        ? Image.network(
            source,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            frameBuilder: frame,
            errorBuilder: error,
          )
        : Image.asset(
            source,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            frameBuilder: frame,
            errorBuilder: error,
          );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WColors.cream2,
      alignment: Alignment.center,
      child: const AppIcon(AppIcons.shoppingBagOutlined, size: 26, color: WColors.mutedLight),
    );
  }
}

/// Web hover affordance: lifts [child] and exposes the hover state to [builder]
/// (e.g. to zoom an image). No-op on touch devices, which never report hover.
class Hoverable extends StatefulWidget {
  final Widget Function(BuildContext context, bool hovered) builder;
  final double lift;

  const Hoverable({super.key, required this.builder, this.lift = 4});

  @override
  State<Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<Hoverable> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _hovered ? -widget.lift : 0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, dy, child) => Transform.translate(offset: Offset(0, dy), child: child),
        child: widget.builder(context, _hovered),
      ),
    );
  }
}

/// Image that eases into a slight zoom while [zoomed] is true.
class ZoomImage extends StatelessWidget {
  final String source;
  final bool zoomed;

  const ZoomImage(this.source, {super.key, required this.zoomed});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: zoomed ? 1.06 : 1,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      child: ShoeImage(source),
    );
  }
}

enum PillStyle { red, tan, outlineDark, outlineLight }

/// Rounded pill button used for every call to action on the site.
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final PillStyle style;
  final String? icon;
  final bool small;
  final bool expand;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = PillStyle.red,
    this.icon,
    this.small = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final (Color? bg, Gradient? gradient, Color fg, Color? border, List<BoxShadow>? shadow) = switch (style) {
      PillStyle.red => (WColors.red, null, Colors.white, null, WShadows.red),
      PillStyle.tan => (null, WColors.tanGradient, WColors.ink, null, null),
      PillStyle.outlineDark => (null, null, WColors.ink, WColors.ink, null),
      PillStyle.outlineLight => (null, null, Colors.white, Colors.white70, null),
    };

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: WText.body(small ? 13.5 : 14.5, color: fg, weight: FontWeight.w600),
          ),
        ),
        if (icon != null) ...[const SizedBox(width: 8), AppIcon(icon!, size: 15, color: fg)],
      ],
    );

    return _HoverGrow(
      enabled: onPressed != null,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            gradient: gradient,
            borderRadius: BorderRadius.circular(50),
            border: border == null ? null : Border.all(color: border, width: 1.5),
            boxShadow: onPressed == null ? null : shadow,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: onPressed,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: small ? 22 : 30, vertical: small ? 11 : 15),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Slightly enlarges a button while the mouse is over it.
class _HoverGrow extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const _HoverGrow({required this.enabled, required this.child});

  @override
  State<_HoverGrow> createState() => _HoverGrowState();
}

class _HoverGrowState extends State<_HoverGrow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedScale(
      scale: _hovered && widget.enabled ? 1.04 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// Eyebrow + serif title + optional subtitle, used at the top of each section.
class SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final bool light;
  final CrossAxisAlignment align;

  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.light = false,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final center = align == CrossAxisAlignment.center;
    final textAlign = center ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 22, height: 1.5, color: light ? WColors.tanLight : WColors.red),
            const SizedBox(width: 10),
            Text(eyebrow.toUpperCase(), style: WText.eyebrow(color: light ? WColors.tanLight : WColors.red)),
          ],
        ),
        const SizedBox(height: 12),
        Text(title, textAlign: textAlign, style: WText.display(30, color: light ? Colors.white : WColors.ink)),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: WText.body(15, color: light ? WColors.mutedLight : WColors.muted, height: 1.6),
          ),
        ],
      ],
    );
  }
}

/// Small round icon badge with shadow — used for trust badges and contact rows.
class IconBadge extends StatelessWidget {
  final String icon;
  final double size;
  final Color background;
  final Color color;

  const IconBadge(this.icon, {super.key, this.size = 38, this.background = WColors.paper, this.color = WColors.red});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle, boxShadow: WShadows.soft),
      alignment: Alignment.center,
      child: AppIcon(icon, size: size * 0.4, color: color),
    );
  }
}

/// Logo: shop photo mark + two-line name.
class BrandMark extends StatelessWidget {
  final bool light;

  const BrandMark({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: WColors.tanGradient),
          clipBehavior: Clip.antiAlias,
          child: const ShoeImage(SafiData.logoImage),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Safi Shoes', style: WText.display(19, color: light ? Colors.white : WColors.ink)),
            Text(
              'STEP IN STYLE',
              style: WText.body(
                9.5,
                color: light ? WColors.tanLight : WColors.red,
                weight: FontWeight.w700,
              ).copyWith(letterSpacing: 1.8),
            ),
          ],
        ),
      ],
    );
  }
}

/// Opens [url] in a new tab (web) or the matching app (mobile).
Future<void> openLink(BuildContext context, Uri url) async {
  final ok = await launchUrl(url, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text("Couldn't open the link.")));
  }
}

Uri phoneUrl(String phone) => Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));

Uri whatsappUrl(String number, [String? text]) =>
    Uri.https('wa.me', '/$number', text == null ? null : {'text': text});
