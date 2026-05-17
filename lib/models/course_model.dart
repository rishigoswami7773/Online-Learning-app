import 'package:flutter/material.dart';

class CourseModel {
  const CourseModel({
    required this.title,
    required this.category,
    required this.instructorName,
    required this.rating,
    required this.price,
    required this.description,
    this.thumbnailAsset = 'assets/reference/image.png',
    this.icon = Icons.school,
    this.duration = '6 Weeks',
    this.level = 'Beginner',
    this.highlights = const <String>[],
  });

  final String title;
  final String category;
  final String instructorName;
  final double rating;
  final double price;
  final String description;
  final String thumbnailAsset;
  final IconData icon;
  final String duration;
  final String level;
  final List<String> highlights;

  String get priceLabel => 'INR ${price.toStringAsFixed(0)}';

  static const List<CourseModel> dummyCourses = [
    CourseModel(
      title: 'Flutter App Development',
      category: 'Programming',
      instructorName: 'Celine Thomas',
      rating: 4.8,
      price: 1499,
      description:
          'Build polished mobile apps with Flutter widgets, navigation, and Firebase basics.',
      icon: Icons.phone_iphone,
      duration: '8 Weeks',
      level: 'Beginner to Intermediate',
      highlights: [
        'Responsive UI layouts',
        'State management basics',
        'Deploy-ready app structure',
      ],
    ),
    CourseModel(
      title: 'Business Strategy Essentials',
      category: 'Business',
      instructorName: 'Rohan Mehta',
      rating: 4.7,
      price: 1199,
      description:
          'Learn practical strategy frameworks and decision-making for real business outcomes.',
      icon: Icons.trending_up,
      duration: '6 Weeks',
      level: 'All Levels',
      highlights: [
        'Market analysis fundamentals',
        'Strategic planning templates',
        'Execution and measurement',
      ],
    ),
    CourseModel(
      title: 'UI/UX Design Masterclass',
      category: 'Design',
      instructorName: 'Meera Shah',
      rating: 4.9,
      price: 1699,
      description:
          'Design intuitive product experiences using modern UI principles and UX workflows.',
      icon: Icons.palette,
      duration: '10 Weeks',
      level: 'Beginner',
      highlights: [
        'User flow mapping',
        'Design systems and consistency',
        'Wireframes and prototypes',
      ],
    ),
    CourseModel(
      title: 'Data Analytics Fundamentals',
      category: 'Data',
      instructorName: 'Ananya Kapoor',
      rating: 4.6,
      price: 1399,
      description:
          'Turn raw data into clear insights with practical analytics and dashboard thinking.',
      icon: Icons.analytics,
      duration: '7 Weeks',
      level: 'Intermediate',
      highlights: [
        'Data cleaning basics',
        'Insight generation',
        'Business storytelling with metrics',
      ],
    ),
  ];
}
