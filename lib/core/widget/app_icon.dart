import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Drop-in replacement for Icon(Icons.*) backed by an SVG asset.
///
/// Usage: AppIcon(AppIcons.home, size: 24, color: Colors.black)
class AppIcon extends StatelessWidget {
  const AppIcon(this.assetPath, {super.key, this.size = 24, this.color});

  /// Renders slightly larger than [size] across the whole app, since the
  /// hand-drawn outline set reads a bit thin next to the old Material glyphs.
  static const double _scale = 1.2;

  final String assetPath;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final renderSize = size * _scale;
    return SvgPicture.asset(
      assetPath,
      width: renderSize,
      height: renderSize,
      colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
