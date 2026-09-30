import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/app_icon.dart';
import '../../data/model/website_models.dart';
import '../../data/website_data.dart';
import '../theme/website_theme.dart';
import 'reveal.dart';
import 'website_widgets.dart';

/// "Our Branches": branch cards next to a map with a pin per branch.
/// Tapping a card or a pin flies the map to that branch.
class BranchesSection extends StatefulWidget {
  final bool wide;

  const BranchesSection({super.key, required this.wide});

  @override
  State<BranchesSection> createState() => _BranchesSectionState();
}

class _BranchesSectionState extends State<BranchesSection> {
  final _map = MapController();
  String? _selected;

  static final _allPins = CameraFit.coordinates(
    coordinates: [for (final b in SafiData.branches) b.location],
    padding: const EdgeInsets.all(60),
    maxZoom: 15,
  );

  void _select(ShopBranch b) {
    setState(() => _selected = b.id);
    _map.move(b.location, 15);
  }

  void _showAll() {
    setState(() => _selected = null);
    _map.fitCamera(_allPins);
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: WColors.line)),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCameraFit: _allPins,
                // Keep the mouse wheel for scrolling the page; zoom with the buttons or pinch.
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.scrollWheelZoom & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.safishoe.website',
                ),
                MarkerLayer(
                  markers: [
                    for (final b in SafiData.branches)
                      Marker(
                        point: b.location,
                        width: 44,
                        height: 52,
                        alignment: Alignment.topCenter,
                        child: _Pin(active: b.id == _selected, label: b.area, onTap: () => _select(b)),
                      ),
                  ],
                ),
                const RichAttributionWidget(
                  alignment: AttributionAlignment.bottomLeft,
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                children: [
                  _MapButton(
                    icon: AppIcons.add,
                    tooltip: 'Zoom in',
                    onTap: () => _map.move(_map.camera.center, _map.camera.zoom + 1),
                  ),
                  const SizedBox(height: 8),
                  _MapButton(
                    icon: AppIcons.remove,
                    tooltip: 'Zoom out',
                    onTap: () => _map.move(_map.camera.center, _map.camera.zoom - 1),
                  ),
                  const SizedBox(height: 8),
                  _MapButton(icon: AppIcons.locationCityOutlined, tooltip: 'Show all branches', onTap: _showAll),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final cards = [
      for (var i = 0; i < SafiData.branches.length; i++)
        Reveal(
          delay: Duration(milliseconds: 80 * i),
          child: _BranchCard(
            branch: SafiData.branches[i],
            active: SafiData.branches[i].id == _selected,
            onTap: () => _select(SafiData.branches[i]),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          eyebrow: 'Our Branches',
          title: 'Visit a Safi Shoes Near You',
          subtitle:
              '${SafiData.branches.length} branches — tap a branch to see it on the map, get directions or call.',
        ),
        const SizedBox(height: 30),
        if (widget.wide)
          SizedBox(
            height: 540,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 420,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(right: 6),
                    itemCount: cards.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => cards[i],
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(child: map),
              ],
            ),
          )
        else ...[
          SizedBox(height: 340, child: map),
          const SizedBox(height: 18),
          for (final card in cards) Padding(padding: const EdgeInsets.only(bottom: 12), child: card),
        ],
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  final bool active;
  final String label;
  final VoidCallback onTap;

  const _Pin({required this.active, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedScale(
            scale: active ? 1.2 : 1,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 200),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: active ? WColors.red : WColors.ink,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: WShadows.soft,
                  ),
                  alignment: Alignment.center,
                  child: const AppIcon(AppIcons.storefrontOutlined, size: 15, color: Colors.white),
                ),
                Container(width: 3, height: 10, color: active ? WColors.red : WColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final String icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: WColors.paper,
        shape: const CircleBorder(side: BorderSide(color: WColors.line)),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(10), child: AppIcon(icon, size: 15, color: WColors.ink)),
        ),
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final ShopBranch branch;
  final bool active;
  final VoidCallback onTap;

  const _BranchCard({required this.branch, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget line(String icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AppIcon(icon, size: 13, color: WColors.tan),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: WText.body(13, color: WColors.muted, height: 1.45))),
        ],
      ),
    );

    return Hoverable(
      lift: 2,
      builder: (context, hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: WColors.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? WColors.red : (hovered ? WColors.tan : WColors.line), width: active ? 1.5 : 1),
          boxShadow: active || hovered ? WShadows.soft : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: active ? null : WColors.tanGradient,
                          color: active ? WColors.red : null,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: AppIcon(
                          AppIcons.storefrontOutlined,
                          size: 17,
                          color: active ? Colors.white : WColors.ink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(branch.name, style: WText.display(17)),
                            const SizedBox(height: 2),
                            Text(
                              '${branch.area}, ${branch.city}',
                              style: WText.body(12, color: WColors.red, weight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  line(AppIcons.locationOnOutlined, branch.address),
                  line(AppIcons.phoneOutlined, branch.phone),
                  line(AppIcons.hourglassEmpty, 'Open daily ${branch.hours}'),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SmallAction(
                        label: 'Directions',
                        icon: AppIcons.locationOnOutlined,
                        filled: true,
                        onTap: () => openLink(context, branch.directionsUrl),
                      ),
                      _SmallAction(
                        label: 'Call',
                        icon: AppIcons.phoneOutlined,
                        onTap: () => openLink(context, phoneUrl(branch.phone)),
                      ),
                      _SmallAction(
                        label: 'WhatsApp',
                        icon: AppIcons.sendOutlined,
                        onTap: () => openLink(context, whatsappUrl(branch.whatsapp)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final String label;
  final String icon;
  final bool filled;
  final VoidCallback onTap;

  const _SmallAction({required this.label, required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : WColors.ink;
    return Material(
      color: filled ? WColors.ink : WColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: filled ? WColors.ink : WColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon, size: 12, color: fg),
              const SizedBox(width: 6),
              Text(label, style: WText.body(12.5, color: fg, weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
