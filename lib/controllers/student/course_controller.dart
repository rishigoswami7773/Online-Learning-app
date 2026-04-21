import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/student/course_model.dart';

class CourseController {
  CourseController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  Future<List<CourseModel>>? _cachedCoursesFuture;

  Future<List<CourseModel>> fetchCourses({
    String query = '',
    String category = 'All',
    bool forceRefresh = false,
  }) async {
    final courses = await _loadCourses(forceRefresh: forceRefresh);

    final normalizedQuery = query.trim().toLowerCase();
    final normalizedCategory = category.trim().toLowerCase();

    return courses.where((course) {
      final matchesCategory =
          normalizedCategory == 'all' ||
          course.category.toLowerCase() == normalizedCategory;
      if (!matchesCategory) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      return course.title.toLowerCase().contains(normalizedQuery) ||
          course.category.toLowerCase().contains(normalizedQuery) ||
          course.instructor.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  Future<List<CourseModel>> _loadCourses({bool forceRefresh = false}) {
    if (!forceRefresh) {
      final cachedCoursesFuture = _cachedCoursesFuture;
      if (cachedCoursesFuture != null) {
        return cachedCoursesFuture;
      }
    }

    final future = _fetchCoursesFromSource();
    if (!forceRefresh) {
      _cachedCoursesFuture = future;
    }
    return future;
  }

  Future<List<CourseModel>> _fetchCoursesFromSource() async {
    List<CourseModel> courses = const <CourseModel>[];

    try {
      final snapshot = await _firestore.collection('courses').limit(100).get();
      courses = snapshot.docs.map(CourseModel.fromFirestore).toList();
    } catch (_) {
      courses = const <CourseModel>[];
    }

    if (courses.isEmpty) {
      return CourseModel.dummyCourses;
    }

    return courses;
  }

  List<String> extractCategories(List<CourseModel> courses) {
    final categories = <String>{'All'};
    for (final course in courses) {
      categories.add(course.category);
    }
    return categories.toList()..sort();
  }
}
