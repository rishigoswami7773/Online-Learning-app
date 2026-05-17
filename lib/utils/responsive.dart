import 'package:flutter/material.dart';

class Responsive {
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) => screenWidth(context) < 600;

  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= 600 && screenWidth(context) < 1024;

  static bool isDesktop(BuildContext context) => screenWidth(context) >= 1024;

  // Responsive font size
  static double fontSize(BuildContext context, double size) {
    double width = screenWidth(context);
    if (width < 360) {
      return size * 0.85;
    }
    if (width < 480) {
      return size * 0.95;
    }
    return size;
  }

  // Responsive spacing
  static double spacing(BuildContext context, double space) {
    double width = screenWidth(context);
    if (width < 360) {
      return space * 0.7;
    }
    if (width < 480) {
      return space * 0.85;
    }
    return space;
  }

  // Responsive horizontal padding
  static EdgeInsets pagePadding(BuildContext context) {
    double width = screenWidth(context);
    if (width < 360) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 16);
    }
    if (width < 480) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 24);
  }
}
