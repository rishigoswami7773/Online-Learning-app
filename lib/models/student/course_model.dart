import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  const CourseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.instructor,
    required this.description,
    required this.thumbnailUrl,
    required this.durationHours,
    required this.rating,
    required this.totalLessons,
    this.isFeatured = false,
  });

  final String id;
  final String title;
  final String category;
  final String instructor;
  final String description;
  final String thumbnailUrl;
  final int durationHours;
  final double rating;
  final int totalLessons;
  final bool isFeatured;

  factory CourseModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CourseModel.fromMap(data, fallbackId: doc.id);
  }

  factory CourseModel.fromMap(
    Map<String, dynamic> data, {
    String fallbackId = '',
  }) {
    return CourseModel(
      id: (data['id'] ?? fallbackId).toString(),
      title: (data['title'] ?? 'Untitled Course').toString(),
      category: (data['category'] ?? 'General').toString(),
      instructor: (data['instructor'] ?? 'Instructor').toString(),
      description: (data['description'] ?? 'No description available yet.')
          .toString(),
      thumbnailUrl: (data['thumbnailUrl'] ?? data['imageUrl'] ?? '').toString(),
      durationHours: _safeInt(data['durationHours'], fallback: 8),
      rating: _safeDouble(data['rating'], fallback: 4.5),
      totalLessons: _safeInt(data['totalLessons'], fallback: 20),
      isFeatured: data['isFeatured'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'instructor': instructor,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'durationHours': durationHours,
      'rating': rating,
      'totalLessons': totalLessons,
      'isFeatured': isFeatured,
    };
  }

  static int _safeInt(Object? value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _safeDouble(Object? value, {required double fallback}) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static const List<CourseModel> dummyCourses = [
    CourseModel(
      id: 'flutter-101',
      title: 'Flutter App Development',
      category: 'Programming',
      instructor: 'Celine Thomas',
      description:
          'Build production-ready mobile apps using Flutter widgets, state management, and Firebase integration.',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=1200',
      durationHours: 24,
      rating: 4.8,
      totalLessons: 36,
      isFeatured: true,
    ),
    CourseModel(
      id: 'biz-analytics',
      title: 'Business Analytics Essentials',
      category: 'Business',
      instructor: 'Rohan Mehta',
      description:
          'Learn to make data-backed business decisions with practical analytics frameworks.',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1551281044-8b5bd29f457c?w=1200',
      durationHours: 18,
      rating: 4.6,
      totalLessons: 28,
      isFeatured: true,
    ),
    CourseModel(
      id: 'uiux-pro',
      title: 'UI/UX Design Studio',
      category: 'Design',
      instructor: 'Meera Shah',
      description:
          'Design intuitive digital experiences with practical UX research and modern UI systems.',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=1200',
      durationHours: 20,
      rating: 4.9,
      totalLessons: 30,
      isFeatured: false,
    ),
    CourseModel(
      id: 'data-fast',
      title: 'Data Analysis Fast Track',
      category: 'Data',
      instructor: 'Ananya Kapoor',
      description:
          'Turn raw data into meaningful insights using dashboards and storytelling techniques.',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1556155092-490a1ba16284?w=1200',
      durationHours: 16,
      rating: 4.5,
      totalLessons: 25,
      isFeatured: false,
    ),
    CourseModel(
      id: 'digital-marketing',
      title: 'Digital Marketing Playbook',
      category: 'Marketing',
      instructor: 'Sneha Verma',
      description:
          'Master SEO, paid campaigns, and social content planning to grow products online.',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=1200',
      durationHours: 14,
      rating: 4.4,
      totalLessons: 22,
      isFeatured: true,
    ),
  ];
}
