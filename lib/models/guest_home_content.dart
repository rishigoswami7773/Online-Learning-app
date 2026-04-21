import 'package:flutter/material.dart';

class GuestCourse {
  const GuestCourse({
    required this.title,
    required this.category,
    required this.instructor,
    required this.description,
    required this.rating,
    required this.duration,
    required this.level,
    required this.priceLabel,
    required this.highlights,
    required this.thumbnailAsset,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String category;
  final String instructor;
  final String description;
  final double rating;
  final String duration;
  final String level;
  final String priceLabel;
  final List<String> highlights;
  final String thumbnailAsset;
  final IconData icon;
  final Color accentColor;
}

class GuestCategory {
  const GuestCategory({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;
}

class GuestBenefit {
  const GuestBenefit({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

class GuestTestimonial {
  const GuestTestimonial({
    required this.name,
    required this.role,
    required this.feedback,
    required this.rating,
  });

  final String name;
  final String role;
  final String feedback;
  final double rating;
}

class GuestHomeContent {
  static const List<GuestCourse> featuredCourses = [
    GuestCourse(
      title: 'Flutter App Development',
      category: 'Programming',
      instructor: 'Celine Thomas',
      description:
          'Build polished cross-platform apps with modern UI patterns and Firebase.',
      rating: 4.8,
      duration: '8 Weeks',
      level: 'Beginner to Intermediate',
      priceLabel: 'INR 1499',
      highlights: [
        'Flutter UI fundamentals and responsive layouts',
        'State management and API integration',
        'Firebase authentication and cloud data basics',
      ],
      thumbnailAsset: 'assets/reference/image.png',
      icon: Icons.phone_iphone,
      accentColor: Color(0xFF0E7C86),
    ),
    GuestCourse(
      title: 'Business Strategy Essentials',
      category: 'Business',
      instructor: 'Rohan Mehta',
      description:
          'Understand planning, communication, and decision-making for growth.',
      rating: 4.7,
      duration: '6 Weeks',
      level: 'All Levels',
      priceLabel: 'INR 1199',
      highlights: [
        'Business planning and market positioning',
        'Frameworks for strategic decision-making',
        'Team communication and execution alignment',
      ],
      thumbnailAsset: 'assets/reference/image.png',
      icon: Icons.trending_up,
      accentColor: Color(0xFF3B82F6),
    ),
    GuestCourse(
      title: 'UI/UX Design Masterclass',
      category: 'Design',
      instructor: 'Meera Shah',
      description:
          'Create user-friendly interfaces with wireframes, color systems, and flows.',
      rating: 4.9,
      duration: '10 Weeks',
      level: 'Beginner',
      priceLabel: 'INR 1699',
      highlights: [
        'User research and problem framing',
        'Wireframing, prototyping, and interaction flow',
        'Visual design systems and accessibility basics',
      ],
      thumbnailAsset: 'assets/reference/image.png',
      icon: Icons.palette,
      accentColor: Color(0xFF7C3AED),
    ),
    GuestCourse(
      title: 'Data Analytics Fundamentals',
      category: 'Data',
      instructor: 'Ananya Kapoor',
      description:
          'Work with dashboards, insights, and practical data-driven decisions.',
      rating: 4.6,
      duration: '7 Weeks',
      level: 'Intermediate',
      priceLabel: 'INR 1399',
      highlights: [
        'Data cleaning and storytelling basics',
        'KPI tracking and dashboard thinking',
        'Practical interpretation for business outcomes',
      ],
      thumbnailAsset: 'assets/reference/image.png',
      icon: Icons.analytics,
      accentColor: Color(0xFFF97316),
    ),
  ];

  static const List<GuestCategory> categories = [
    GuestCategory(
      title: 'Programming',
      icon: Icons.code,
      color: Color(0xFF0E7C86),
    ),
    GuestCategory(
      title: 'Business',
      icon: Icons.work_outline,
      color: Color(0xFF3B82F6),
    ),
    GuestCategory(
      title: 'Design',
      icon: Icons.brush_outlined,
      color: Color(0xFF7C3AED),
    ),
    GuestCategory(
      title: 'Data',
      icon: Icons.bar_chart,
      color: Color(0xFFF97316),
    ),
    GuestCategory(
      title: 'Marketing',
      icon: Icons.campaign_outlined,
      color: Color(0xFF10B981),
    ),
  ];

  static const List<GuestBenefit> benefits = [
    GuestBenefit(
      title: 'Expert Instructors',
      description:
          'Learn from mentors with real-world experience and practical guidance.',
      icon: Icons.school_outlined,
      color: Color(0xFF0E7C86),
    ),
    GuestBenefit(
      title: 'Flexible Learning',
      description:
          'Study anytime with mobile-friendly lessons and self-paced tracks.',
      icon: Icons.schedule_outlined,
      color: Color(0xFF3B82F6),
    ),
    GuestBenefit(
      title: 'Affordable Courses',
      description:
          'Access quality education with pricing designed for every learner.',
      icon: Icons.payments_outlined,
      color: Color(0xFFF97316),
    ),
  ];

  static const List<GuestTestimonial> testimonials = [
    GuestTestimonial(
      name: 'Aarav',
      role: 'Student',
      feedback:
          'I could explore the platform first and join the right course later.',
      rating: 4.9,
    ),
    GuestTestimonial(
      name: 'Meera',
      role: 'Working Professional',
      feedback:
          'The guest preview made it easy to trust the learning experience.',
      rating: 4.8,
    ),
  ];
}
