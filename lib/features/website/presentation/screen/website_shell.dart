import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/app_icon.dart';
import '../../data/website_data.dart';
import '../provider/website_providers.dart';
import '../theme/website_theme.dart';
import '../widget/website_widgets.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'shop_screen.dart';

const _tabs = [
  (WebsiteTab.home, 'Home', AppIcons.home),
  (WebsiteTab.shop, 'Shop', AppIcons.storefrontOutlined),
  (WebsiteTab.cart, 'Cart', AppIcons.shoppingBagOutlined),
];

/// Website shell: utility bar, header, and tab navigation
/// (bottom bar on phones, header links on wide screens).
class WebsiteShell extends ConsumerWidget {
  const WebsiteShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(websiteTabProvider);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: Column(
        children: [
          const _UtilityBar(),
          _Header(wide: wide),
          Expanded(
            child: _TabFade(
              index: tab.index,
              child: IndexedStack(
                index: tab.index,
                children: const [HomeScreen(), ShopScreen(), CartScreen()],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide ? null : const _BottomNav(),
    );
  }
}

/// Fades and lifts the page in whenever the tab changes. Wraps the IndexedStack
/// instead of re-keying it, so each tab keeps its scroll position and inputs.
class _TabFade extends StatefulWidget {
  final int index;
  final Widget child;

  const _TabFade({required this.index, required this.child});

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380), value: 1);
  late final _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(_TabFade old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && !MediaQuery.disableAnimationsOf(context)) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curve,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: 0.2 + 0.8 * _curve.value,
      child: Transform.translate(offset: Offset(0, (1 - _curve.value) * 14), child: child),
    ),
  );
}

class _UtilityBar extends StatelessWidget {
  const _UtilityBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WColors.ink,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 7, 16, 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppIcon(AppIcons.localShippingOutlined, size: 12, color: WColors.tanLight),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              'Order online · Pick-up from ${SafiData.branches.length} branches or home delivery',
              overflow: TextOverflow.ellipsis,
              style: WText.body(11.5, color: WColors.tanPale, weight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final bool wide;

  const _Header({required this.wide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(websiteTabProvider);
    void go(WebsiteTab t) => ref.read(websiteTabProvider.notifier).state = t;

    return Container(
      decoration: const BoxDecoration(
        color: WColors.paper,
        border: Border(bottom: BorderSide(color: WColors.line)),
      ),
      padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 16, vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: wMaxContentWidth),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => go(WebsiteTab.home),
                child: const BrandMark(),
              ),
              const Spacer(),
              if (wide) ...[
                for (final (t, label, _) in _tabs)
                  if (t != WebsiteTab.cart) _NavLink(label: label, active: tab == t, onTap: () => go(t)),
                const SizedBox(width: 16),
                PillButton(
                  label: 'Order Now',
                  small: true,
                  icon: AppIcons.chevronRight,
                  onPressed: () => go(WebsiteTab.shop),
                ),
                const SizedBox(width: 12),
              ],
              _CartButton(onTap: () => go(WebsiteTab.cart)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header text link with an animated underline marking the current page.
class _NavLink extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavLink({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Hoverable(
      lift: 0,
      builder: (context, hovered) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: WText.body(14.5, color: active || hovered ? WColors.red : WColors.ink, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 2,
                width: active ? 22 : (hovered ? 10 : 0),
                decoration: BoxDecoration(color: WColors.red, borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartButton extends ConsumerWidget {
  final VoidCallback onTap;

  const _CartButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    // Pops each time the count changes, e.g. when a shoe is added.
    return TweenAnimationBuilder<double>(
      key: ValueKey(count),
      tween: Tween(begin: count > 0 ? 1.25 : 1, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: WColors.red,
        offset: const Offset(-2, 2),
        child: Material(
          color: WColors.ink,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: AppIcon(AppIcons.shoppingBagOutlined, size: 17, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(websiteTabProvider);
    final count = ref.watch(cartCountProvider);

    return Container(
      decoration: const BoxDecoration(
        color: WColors.paper,
        border: Border(top: BorderSide(color: WColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(10, 8, 10, 8 + MediaQuery.paddingOf(context).bottom),
      child: Row(
        children: [
          for (final (t, label, icon) in _tabs)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => ref.read(websiteTabProvider.notifier).state = t,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          color: tab == t ? WColors.tanPale : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Badge(
                          isLabelVisible: t == WebsiteTab.cart && count > 0,
                          label: Text('$count'),
                          backgroundColor: WColors.red,
                          child: AppIcon(icon, size: 18, color: tab == t ? WColors.red : WColors.muted),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: WText.body(
                          11.5,
                          color: tab == t ? WColors.ink : WColors.muted,
                          weight: tab == t ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
