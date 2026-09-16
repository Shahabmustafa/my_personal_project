import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Icon widget dedicated to text-field prefix/suffix icons (search bars,
/// form fields, password toggles, etc).
///
/// Renders at exactly [size] — unlike [AppIcon] it does not apply the
/// app-wide icon scale factor, so field icons stay a fixed, predictable
/// size regardless of that global setting.
class TextFieldIcon extends StatelessWidget {
  const TextFieldIcon(this.assetPath, {super.key, this.size = 24, this.color});

  final String assetPath;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: (){},
      icon: SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      ),
    );
  }
}
