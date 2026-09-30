import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/app_icon.dart';
import '../../data/model/website_models.dart';
import '../../data/website_data.dart';
import '../provider/website_providers.dart';
import '../theme/website_theme.dart';
import '../widget/shoe_card.dart';
import '../widget/website_widgets.dart';

/// All shoes, grouped by category, with search and pinned category chips.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = SafiData.category(ref.watch(shopCategoryProvider));
    final sections = _sectionsFor(category, _query.trim().toLowerCase());

    final width = MediaQuery.sizeOf(context).width;
    // Same content column as Home: side gutter, then centred at the max width.
    final gutter = ((width - wMaxContentWidth) / 2).clamp(wGutter(context), double.infinity);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, 28, gutter, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OUR COLLECTION', style: WText.eyebrow()),
                const SizedBox(height: 8),
                Text('Find your perfect pair', style: WText.display(32)),
                const SizedBox(height: 6),
                Text(
                  'Choose a shoe, pick your size and tap Order Now.',
                  style: WText.body(14.5, color: WColors.muted),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  style: WText.body(14.5),
                  decoration: InputDecoration(
                    hintText: 'Search shoes…',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: AppIcon(AppIcons.search, size: 17, color: WColors.muted),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 48),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => setState(() {
                              _search.clear();
                              _query = '';
                            }),
                            icon: const AppIcon(AppIcons.close, size: 15, color: WColors.muted),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Chips stay pinned while scrolling so switching category is always one tap.
        SliverPersistentHeader(
          pinned: true,
          delegate: _ChipsHeader(
            gutter: gutter,
            child: CategoryChips(
              categories: SafiData.categories,
              showAll: true,
              selected: category?.id,
              onSelected: (id) => ref.read(shopCategoryProvider.notifier).state = id,
            ),
          ),
        ),
        if (sections.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIcon(AppIcons.searchOffOutlined, size: 34, color: WColors.mutedLight),
                  const SizedBox(height: 10),
                  Text('No shoes match "$_query"', style: WText.body(15, color: WColors.muted)),
                ],
              ),
            ),
          )
        else
          for (final section in sections)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 30),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionTitle(section: section),
                    const SizedBox(height: 16),
                    ShoeGrid(shoes: section.shoes),
                  ],
                ),
              ),
            ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

class _ChipsHeader extends SliverPersistentHeaderDelegate {
  final double gutter;
  final Widget child;

  const _ChipsHeader({required this.gutter, required this.child});

  static const _height = 72.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: WColors.cream,
        border: Border(bottom: BorderSide(color: overlapsContent ? WColors.line : Colors.transparent)),
      ),
      padding: EdgeInsets.fromLTRB(gutter, 14, gutter, 14),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_ChipsHeader old) => old.gutter != gutter || old.child != child;
}

/// A titled group of shoes on the shop page.
class _Section {
  final String title;
  final String subtitle;
  final List<Shoe> shoes;

  const _Section(this.title, this.subtitle, this.shoes);
}

String _countLabel(int n) => '$n ${n == 1 ? 'style' : 'styles'}';

/// Search results, one chosen category, or every category.
List<_Section> _sectionsFor(ShoeCategory? category, String query) {
  if (query.isNotEmpty) {
    final hits = SafiData.shoes.where((s) => s.name.toLowerCase().contains(query)).toList();
    return hits.isEmpty ? const [] : [_Section('Search results', _countLabel(hits.length), hits)];
  }
  return [
    for (final c in category == null ? SafiData.categories : [category])
      if (SafiData.byCategory(c.id).isNotEmpty)
        _Section(c.name, '${c.tagline} · ${_countLabel(SafiData.byCategory(c.id).length)}', SafiData.byCategory(c.id)),
  ];
}

class _SectionTitle extends StatelessWidget {
  final _Section section;

  const _SectionTitle({required this.section});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.title, style: WText.display(24)),
              const SizedBox(height: 3),
              Text(section.subtitle, style: WText.body(13, color: WColors.muted)),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(height: 1, color: WColors.line),
          ),
        ),
      ],
    );
  }
}
