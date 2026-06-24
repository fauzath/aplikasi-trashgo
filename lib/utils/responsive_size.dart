import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppSize {
  const AppSize._();

  static Size screen(BuildContext context) => MediaQuery.sizeOf(context);

  static bool isSmallPhone(BuildContext context) {
    final size = screen(context);
    return size.shortestSide <= 360 || size.height <= 720;
  }

  static bool isNormalPhone(BuildContext context) {
    final size = screen(context);
    return size.shortestSide > 360 && size.shortestSide <= 430;
  }

  static double horizontalPadding(BuildContext context) {
    final width = screen(context).width;
    if (width <= 360) return 24;
    if (width <= 390) return 28;
    if (width <= 430) return 32;
    return 38;
  }

  static double topPadding(BuildContext context) {
    final height = screen(context).height;
    if (height <= 700) return 20;
    if (height <= 800) return 28;
    return 34;
  }

  static double gap(BuildContext context, double value) {
    final height = screen(context).height;
    final scale = height <= 700 ? 0.78 : (height <= 800 ? 0.9 : 1.0);
    return value * scale;
  }

  static double icon(BuildContext context, double value) {
    final width = screen(context).width;
    final scale = width <= 360 ? 0.9 : (width <= 430 ? 1.0 : 1.08);
    return value * scale;
  }

  static double clampDouble(double value, double min, double max) {
    return math.max(min, math.min(max, value));
  }

  static double readableTextScale(BuildContext context) {
    final media = MediaQuery.of(context);
    final userScale = media.textScaler.scale(1.0);
    final width = media.size.width;

    final boost = width <= 360 ? 1.12 : 1.08;
    return (userScale * boost).clamp(1.0, 1.22).toDouble();
  }
}
