import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';

class Dimensions {
  /// Returns fractional height of screen minus AppBar if specified
  static double getHeight(
    BuildContext context,
    int fraction, {
    bool removeAppBarHeight = true,
  }) {
    final mediaQuery = MediaQuery.of(context);
    double height = mediaQuery.size.height;
    if (removeAppBarHeight) {
      height -= AppBar().preferredSize.height + mediaQuery.padding.top;
    }
    return height / fraction;
  }

  /// Returns fractional width of screen
  static double getWidth(BuildContext context, int fraction) {
    return MediaQuery.of(context).size.width / fraction;
  }

  /// Responsive scaling factor based on screen width
  static double scaleFactor(BuildContext context, [double baseWidth = 375]) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scale = screenWidth / baseWidth;
    return min(scale, 1.2); // Cap it for large screens
  }
}

extension DimensionsExtension on num {
  /// Responsive height
  double get height => h;

  /// Responsive width
  double get width => w;

  /// Responsive radius (with capping)
  double get radius {
    final capped = min(toDouble(), 20.0);
    return capped.r;
  }

  /// Responsive font size (with cap)
  double rsp(BuildContext context) {
    double scale = Dimensions.scaleFactor(context);
    return toDouble() * scale.sp;
  }
}