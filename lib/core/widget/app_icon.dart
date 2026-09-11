import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Drop-in replacement for Icon(Icons.*) backed by an SVG asset.
///
/// Usage: AppIcon(AppIcons.home, size: 24, color: Colors.black)
class AppIcon extends StatelessWidget {
  const AppIcon(this.assetPath, {super.key, this.size = 24, this.color});

  final String assetPath;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
