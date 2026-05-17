import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get surfaceColor => isDark ? AppColors.surfaceDark : AppColors.surface;
  Color get bgColor => isDark ? AppColors.backgroundDark : AppColors.background;
  Color get cardColor => isDark ? AppColors.cardDark : AppColors.surface;
  Color get textPrimary =>
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  Color get textSecondary =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
  Color get dividerColor => isDark ? AppColors.dividerDark : AppColors.divider;
  Color get borderColor =>
      isDark ? AppColors.borderDark : AppColors.borderLight;
  Color get brandSoftColor =>
      isDark ? AppColors.brandSoftDark : AppColors.brandSoft;
  Color get inputFillColor =>
      isDark ? AppColors.surfaceDark : AppColors.surface;
  List<BoxShadow> get cardShadow => isDark
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ];

  // Helper for adaptive border sides
  BorderSide get adaptiveBorder =>
      BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight);

  // Helper for subtle divider line color
  Color get subtleBg => isDark
      ? AppColors.cardDark.withValues(alpha: 0.6)
      : AppColors.background;
}
