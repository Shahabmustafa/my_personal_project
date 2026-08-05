import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Small helper to keep responsive checks consistent across the app.
class Responsive {
  final BuildContext context;
  Responsive(this.context);

  double get width => MediaQuery.of(context).size.width;

  bool get isMobile => width < AppConstants.mobileMaxWidth;
  bool get isTablet =>
      width >= AppConstants.mobileMaxWidth && width < AppConstants.tabletMaxWidth;
  bool get isDesktop => width >= AppConstants.tabletMaxWidth;

  /// Returns a form width that adapts to the current screen size.
  double get formMaxWidth {
    if (isDesktop) return 420;
    if (isTablet) return 400;
    return width * 0.9; // mobile - 90% of screen width
  }

  double get horizontalPadding {
    if (isDesktop) return 40;
    if (isTablet) return 32;
    return 20;
  }
}
