import 'package:flutter/material.dart';

class DashboardConstants {
  // Colors
  static const Color brandColor = Color(0xFF0F766E);
  static const Color accentColor = Color(0xFF1D4ED8);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color neutralLight = Color(0xFFF3F9F8);
  static const Color neutralDark = Color(0xFF1F2937);

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 20.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacing2XL = 24.0;

  // Animation durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
}

class DashboardMotivations {
  static const List<String> motivations = [
    'Keep going, you\'re doing great! 🌟',
    'Consistency beats motivation. Keep learning! 💪',
    'Small lessons today, big wins tomorrow. 🚀',
    'Your future skills are built one session at a time. 📚',
    'Progress beats perfection. Keep pushing! 🎯',
    'Every expert was once a beginner. 🌱',
    'You\'re one step closer to mastery! 👑',
    'Learning is the best investment! 💎',
    'Make it a great learning day! ☀️',
    'Your dedication will pay off! 🏆',
  ];

  static String getMotivation() {
    final index = DateTime.now().day % motivations.length;
    return motivations[index];
  }
}

String getGreeting() {
  final now = DateTime.now();
  final hour = now.hour;

  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  if (hour < 21) return 'Good Evening';
  return 'Good Night';
}

String formatLearningHours(double hours) {
  if (hours < 1) {
    return '${(hours * 60).toStringAsFixed(0)} mins';
  }
  return '${hours.toStringAsFixed(1)} hours';
}

String formatStudentCount(int count) {
  if (count >= 1000000) {
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
  if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(1)}K';
  }
  return count.toString();
}
