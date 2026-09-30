import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/app_icon.dart';
import '../../data/model/website_models.dart';
import '../../data/website_data.dart';
import '../provider/website_providers.dart';
import '../theme/website_theme.dart';
import '../widget/branches_section.dart';
import '../widget/reveal.dart';
import '../widget/shoe_card.dart';
import '../widget/website_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _branchesKey = GlobalKey();

  void _openShop([String? categoryId]) {
    ref.read(shopCategoryProvider.notifier).state = categoryId;
    ref.read(websiteTabProvider.notifier).state = WebsiteTab.shop;
  }

  void _scrollToBranches() {
    final ctx = _branchesKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        // Not a lazy ListView: "Find a branch" scrolls to a section that must already be built.
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(wide: wide, onShop: _openShop, onBranches: _scrollToBranches),
              const _StatsBand(),
              WSection(
                key: _branchesKey,
                child: BranchesSection(wide: wide),
              ),
              WSection(
                background: WColors.paper,
                child: _Categories(wide: wide, onCategory: _openShop),
              ),
              _Spotlight(wide: wide, onShop: () => _openShop()),
              WSection(child: _NewArrivals(onSeeAll: _openShop)),
              WSection(background: WColors.paper, child: _WhyUs(wide: wide)),
              _Cta(wide: wide, onShop: () => _openShop(), onBranches: _scrollToBranches),
              const WebsiteFooter(),
            ],
          ),
        );
      },
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final bool wide;
  final VoidCallback onShop;
  final VoidCallback onBranches;

  const _Hero({required this.wide, required this.onShop, required this.onBranches});

  @override
  Widget build(BuildContext context) {
    // Hero copy enters line by line on page load.
    var step = 0;
    Widget enter(Widget w) => EntranceFade(delay: Duration(milliseconds: 110 * step++), child: w);

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        enter(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: WColors.paper,
              borderRadius: BorderRadius.circular(30),
              boxShadow: WShadows.soft,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon(AppIcons.star, size: 13, color: WColors.tan),
                const SizedBox(width: 7),
                Text(
                  '${SafiData.branches.length} branches across the city',
                  style: WText.body(12.5, color: WColors.inkSoft, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        enter(
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Step Into Comfort with '),
                TextSpan(
                  text: 'Safi',
                  style: WText.display(wide ? 62 : 40, color: WColors.red, style: FontStyle.italic),
                ),
                const TextSpan(text: ' Shoes'),
              ],
            ),
            style: WText.display(wide ? 62 : 40),
          ),
        ),
        const SizedBox(height: 18),
        enter(
          Text(
            'Formal, casual, sports and ladies footwear — genuine quality at fair prices, for the whole family.',
            style: WText.body(17, color: WColors.muted, height: 1.6),
          ),
        ),
        const SizedBox(height: 30),
        if (wide)
          enter(
            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                PillButton(label: 'Shop Now', icon: AppIcons.chevronRight, onPressed: onShop),
                PillButton(label: 'Find a Branch', style: PillStyle.outlineDark, onPressed: onBranches),
              ],
            ),
          )
        else
          // Full-width stacked buttons are easier to hit and line up on phones.
          enter(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PillButton(label: 'Shop Now', icon: AppIcons.chevronRight, expand: true, onPressed: onShop),
                const SizedBox(height: 12),
                PillButton(
                  label: 'Find a Branch',
                  style: PillStyle.outlineDark,
                  expand: true,
                  onPressed: onBranches,
                ),
              ],
            ),
          ),
        const SizedBox(height: 34),
        enter(
          const Wrap(
            spacing: 22,
            runSpacing: 14,
            children: [
              _Trust(AppIcons.checkCircleOutline, 'Genuine Quality'),
              _Trust(AppIcons.straightenOutlined, 'All Sizes'),
              _Trust(AppIcons.localShippingOutlined, 'Home Delivery'),
            ],
          ),
        ),
      ],
    );

    final visual = SizedBox(
      height: wide ? 520 : 360,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            right: 0,
            left: wide ? 70 : 24,
            bottom: 50,
            child: EntranceFade(
              delay: const Duration(milliseconds: 150),
              offsetY: 0,
              fromScale: 0.94,
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: WShadows.large),
                clipBehavior: Clip.antiAlias,
                child: const ShoeImage(SafiData.heroImage),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: EntranceFade(
              delay: const Duration(milliseconds: 550),
              child: Floating(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
                  decoration: BoxDecoration(
                    color: WColors.paper,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: WShadows.large,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: const SizedBox(width: 58, height: 58, child: ShoeImage(SafiData.spotlightImage)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BEST SELLER', style: WText.eyebrow(color: WColors.tan)),
                          const SizedBox(height: 2),
                          Text('Tan Leather Derby', style: WText.display(16)),
                          Text(
                            'Hand-finished leather',
                            style: WText.body(12.5, color: WColors.red, weight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: WColors.cream,
        gradient: RadialGradient(
          center: Alignment(0.76, -0.84),
          radius: 1.1,
          colors: [Color(0x29B27B45), Color(0x00F8F3EA)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -180, right: -180, child: _Ring(520, WColors.tan.withValues(alpha: .25))),
          Positioned(top: -120, right: -120, child: _Ring(340, WColors.red.withValues(alpha: .15))),
          WSection(
            reveal: false, // the hero has its own entrance animation
            child: wide
                ? Row(
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: 60),
                      Expanded(child: visual),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [copy, const SizedBox(height: 44), visual],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double size;
  final Color color;

  const _Ring(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color)),
  );
}

class _Trust extends StatelessWidget {
  final String icon;
  final String label;

  const _Trust(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconBadge(icon, size: 34),
        const SizedBox(width: 10),
        Text(label, style: WText.body(13.5, color: WColors.inkSoft, weight: FontWeight.w600)),
      ],
    );
  }
}

// ── Stats band ────────────────────────────────────────────────────────────────
class _StatsBand extends StatelessWidget {
  const _StatsBand();

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('${SafiData.branches.length}', 'Branches'),
      ('${SafiData.categories.length}', 'Categories'),
      ('${SafiData.shoes.length}+', 'Styles'),
      ('100%', 'Quality checked'),
    ];
    return Container(
      decoration: const BoxDecoration(gradient: WColors.tanGradient),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runSpacing: 20,
        children: [
          for (final (value, label) in stats)
            SizedBox(
              width: 150,
              child: Column(
                children: [
                  Text(value, style: WText.display(34)),
                  const SizedBox(height: 2),
                  Text(
                    label.toUpperCase(),
                    style: WText.body(11.5, color: WColors.inkSoft, weight: FontWeight.w600).copyWith(letterSpacing: 1.4),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shop by category (bento) ──────────────────────────────────────────────────
class _Categories extends StatelessWidget {
  final bool wide;
  final ValueChanged<String> onCategory;

  const _Categories({required this.wide, required this.onCategory});

  @override
  Widget build(BuildContext context) {
    const cats = SafiData.categories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          eyebrow: 'Collections',
          title: 'Shop by Category',
          subtitle: 'Pick a category to see every style — then order in a minute.',
        ),
        const SizedBox(height: 30),
        LayoutBuilder(
          builder: (context, c) {
            const gap = 14.0;
            final cols = wide ? 3 : 2;
            final cell = (c.maxWidth - gap * (cols - 1)) / cols;
            double span(int cells) => cell * cells + gap * (cells - 1);
            // The first tile takes two cells; the last one stretches to fill its row.
            final leftover = (cats.length + 1) % cols;
            final lastSpan = leftover == 0 ? 1 : cols - leftover + 1;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < cats.length; i++)
                  SizedBox(
                    width: i == 0 ? span(2) : (i == cats.length - 1 ? span(lastSpan) : cell),
                    height: wide ? 260 : (i == 0 ? 210 : 190),
                    child: Reveal(
                      delay: Duration(milliseconds: 90 * (i % cols)),
                      child: _CategoryTile(category: cats[i], onTap: () => onCategory(cats[i].id)),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ShoeCategory category;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = SafiData.byCategory(category.id).length;
    return Hoverable(
      builder: (context, hovered) => Material(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ZoomImage(category.image, zoomed: hovered),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x0017130F), Color(0xE617130F)],
                    stops: [0.3, 1],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: WColors.paper.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '$count ${count == 1 ? 'style' : 'styles'}',
                    style: WText.body(11, color: WColors.ink, weight: FontWeight.w600),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WText.display(20, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            category.tagline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WText.body(12, color: WColors.tanPale),
                          ),
                        ),
                        AnimatedPadding(
                          duration: const Duration(milliseconds: 220),
                          padding: EdgeInsets.only(left: hovered ? 10 : 6),
                          child: const AppIcon(AppIcons.chevronRight, size: 13, color: WColors.tanLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Spotlight ─────────────────────────────────────────────────────────────────
class _Spotlight extends StatelessWidget {
  final bool wide;
  final VoidCallback onShop;

  const _Spotlight({required this.wide, required this.onShop});

  @override
  Widget build(BuildContext context) {
    final image = AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: WColors.tan.withValues(alpha: .5), width: 1.5),
        ),
        padding: const EdgeInsets.all(14),
        child: const ClipOval(child: ShoeImage(SafiData.spotlightImage)),
      ),
    );

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          eyebrow: 'Crafted to last',
          title: 'Real Leather. Real Comfort.',
          subtitle:
              'Our formal range is cut from genuine leather with cushioned insoles and stitched soles — '
              'shoes that look sharp on day one and still feel good years later.',
          light: true,
        ),
        const SizedBox(height: 24),
        PillButton(label: 'Browse All Shoes', style: PillStyle.tan, icon: AppIcons.chevronRight, onPressed: onShop),
      ],
    );

    return Container(
      color: WColors.ink,
      child: WSection(
        child: wide
            ? Row(
                children: [
                  SizedBox(width: 420, child: image),
                  const SizedBox(width: 60),
                  Expanded(child: copy),
                ],
              )
            : Column(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 30), child: image),
                  const SizedBox(height: 36),
                  copy,
                ],
              ),
      ),
    );
  }
}

// ── New arrivals ──────────────────────────────────────────────────────────────
class _NewArrivals extends StatefulWidget {
  final ValueChanged<String?> onSeeAll;

  const _NewArrivals({required this.onSeeAll});

  @override
  State<_NewArrivals> createState() => _NewArrivalsState();
}

class _NewArrivalsState extends State<_NewArrivals> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final shoes = (_category == null
            ? SafiData.shoes.where((s) => s.isNew)
            : SafiData.shoes.where((s) => s.categoryId == _category))
        .take(8)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          eyebrow: 'Order Online',
          title: 'New Arrivals',
          subtitle: 'Pick your size, tap Order Now and we\'ll confirm on WhatsApp.',
          align: CrossAxisAlignment.center,
        ),
        const SizedBox(height: 26),
        CategoryChips(
          categories: SafiData.categories,
          selected: _category,
          showAll: true,
          onSelected: (id) => setState(() => _category = id),
        ),
        const SizedBox(height: 24),
        ShoeGrid(shoes: shoes),
        const SizedBox(height: 28),
        Center(
          child: PillButton(
            label: 'See All Shoes',
            style: PillStyle.outlineDark,
            icon: AppIcons.chevronRight,
            onPressed: () => widget.onSeeAll(_category),
          ),
        ),
      ],
    );
  }
}

// ── Why choose us ─────────────────────────────────────────────────────────────
class _WhyUs extends StatelessWidget {
  final bool wide;

  const _WhyUs({required this.wide});

  static const _items = [
    (AppIcons.checkCircleOutline, 'Quality You Can Feel', 'Every pair is checked in-store before it goes on the shelf.'),
    (AppIcons.straightenOutlined, 'Every Size in Stock', 'Men, ladies and kids — with easy size exchange at any branch.'),
    (AppIcons.localShippingOutlined, 'Order from Home', 'Order online and collect from a branch, or get it delivered.'),
  ];

  @override
  Widget build(BuildContext context) {
    final cards = [
      for (final (icon, title, body) in _items)
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: WColors.cream,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: WColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(gradient: WColors.tanGradient, borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: AppIcon(icon, size: 20, color: WColors.ink),
              ),
              const SizedBox(height: 18),
              Text(title, style: WText.display(20)),
              const SizedBox(height: 8),
              Text(body, style: WText.body(14, color: WColors.muted, height: 1.6)),
            ],
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(eyebrow: 'Why Choose Us', title: 'Why Safi Shoes', align: CrossAxisAlignment.center),
        const SizedBox(height: 30),
        if (wide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 18),
                  Expanded(
                    child: Reveal(delay: Duration(milliseconds: 120 * i), child: cards[i]),
                  ),
                ],
              ],
            ),
          )
        else
          for (final card in cards)
            Padding(padding: const EdgeInsets.only(bottom: 14), child: Reveal(child: card)),
      ],
    );
  }
}

// ── CTA ───────────────────────────────────────────────────────────────────────
class _Cta extends StatelessWidget {
  final bool wide;
  final VoidCallback onShop;
  final VoidCallback onBranches;

  const _Cta({required this.wide, required this.onShop, required this.onBranches});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WColors.red, WColors.redDeep],
        ),
      ),
      child: WSection(
        background: Colors.transparent,
        child: Column(
          crossAxisAlignment: wide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(
              'Found your perfect pair?',
              textAlign: wide ? TextAlign.center : TextAlign.start,
              style: WText.display(wide ? 40 : 30, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              'Order online now, or walk into your nearest Safi Shoes branch and try it on.',
              textAlign: wide ? TextAlign.center : TextAlign.start,
              style: WText.body(15, color: WColors.tanPale, height: 1.6),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                PillButton(label: 'Order Now', style: PillStyle.tan, onPressed: onShop),
                PillButton(label: 'Find a Branch', style: PillStyle.outlineLight, onPressed: onBranches),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────
class WebsiteFooter extends ConsumerWidget {
  const WebsiteFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    Widget heading(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(t.toUpperCase(), style: WText.eyebrow(color: WColors.tanLight)),
    );

    Widget row(String icon, String text, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: AppIcon(icon, size: 14, color: WColors.tanLight)),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: WText.body(14, color: WColors.mutedLight, height: 1.5))),
          ],
        ),
      ),
    );

    Widget link(String label, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Text(label, style: WText.body(14, color: WColors.mutedLight)),
      ),
    );

    void shop(String? category) {
      ref.read(shopCategoryProvider.notifier).state = category;
      ref.read(websiteTabProvider.notifier).state = WebsiteTab.shop;
    }

    final brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandMark(light: true),
        const SizedBox(height: 16),
        Text(
          '${SafiData.tagline} — formal, casual, sports and ladies shoes at ${SafiData.branches.length} branches.',
          style: WText.body(14, color: WColors.mutedLight, height: 1.6),
        ),
      ],
    );

    final collections = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading('Collections'),
        for (final c in SafiData.categories) link(c.name, () => shop(c.id)),
      ],
    );

    final branches = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading('Branches'),
        for (final b in SafiData.branches)
          row(AppIcons.locationOnOutlined, '${b.area} — ${b.address}', () => openLink(context, b.directionsUrl)),
      ],
    );

    final contact = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading('Contact'),
        row(AppIcons.phoneOutlined, SafiData.phone, () => openLink(context, phoneUrl(SafiData.phone))),
        row(AppIcons.sendOutlined, 'WhatsApp us', () => openLink(context, whatsappUrl(SafiData.whatsapp))),
        row(AppIcons.emailOutlined, SafiData.email, () => openLink(context, Uri(scheme: 'mailto', path: SafiData.email))),
      ],
    );

    return Container(
      color: WColors.ink,
      child: WSection(
        background: Colors.transparent,
        reveal: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: brand),
                  const SizedBox(width: 48),
                  Expanded(flex: 2, child: collections),
                  const SizedBox(width: 32),
                  Expanded(flex: 3, child: branches),
                  const SizedBox(width: 32),
                  Expanded(flex: 2, child: contact),
                ],
              )
            else ...[
              brand,
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: collections),
                  const SizedBox(width: 20),
                  Expanded(child: contact),
                ],
              ),
              const SizedBox(height: 16),
              branches,
            ],
            const SizedBox(height: 22),
            const Divider(color: WColors.inkElev),
            const SizedBox(height: 14),
            Text('© ${DateTime.now().year} Safi Shoes. All rights reserved.', style: WText.body(12.5, color: WColors.muted)),
          ],
        ),
      ),
    );
  }
}
