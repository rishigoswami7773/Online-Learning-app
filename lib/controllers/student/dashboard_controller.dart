import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/student/course_model.dart';
import '../../models/student/enrollment_model.dart';
import '../../models/student/user_stats_model.dart';
import 'course_controller.dart';
import 'enrollment_controller.dart';

class DashboardData {
  const DashboardData({
    required this.studentName,
    required this.motivationalText,
    required this.allCourses,
    required this.continueLearning,
    required this.featuredCourses,
    required this.trendingCourses,
    required this.recommendedCourses,
    required this.categories,
    required this.userStats,
    required this.recentlyViewed,
    required this.recentlyEnrolled,
  });

  final String studentName;
  final String motivationalText;
  final List<CourseModel> allCourses;
  final List<EnrollmentModel> continueLearning;
  final List<CourseModel> featuredCourses;
  final List<CourseModel> trendingCourses;
  final List<CourseModel> recommendedCourses;
  final List<String> categories;
  final UserStats userStats;
  final EnrollmentModel? recentlyViewed;
  final EnrollmentModel? recentlyEnrolled;
}

class DashboardController {
  DashboardController({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    CourseController? courseController,
    EnrollmentController? enrollmentController,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _courseController = courseController ?? CourseController(),
       _enrollmentController = enrollmentController ?? EnrollmentController();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final CourseController _courseController;
  final EnrollmentController _enrollmentController;

  Future<DashboardData> loadDashboardData({bool forceRefresh = false}) async {
    final results = await Future.wait([
      _fetchStudentName(),
      _courseController.fetchCourses(forceRefresh: forceRefresh),
      _enrollmentController.fetchEnrollments(forceRefresh: forceRefresh),
      _fetchUserStats(),
    ]);

    final studentName = results[0] as String;
    final allCourses = results[1] as List<CourseModel>;
    final enrollments = results[2] as List<EnrollmentModel>;
    final userStats = results[3] as UserStats;

    final featuredCourses = allCourses
        .where((course) => course.isFeatured)
        .toList();

    // Get trending courses (first 4 highest rated)
    final trendingCourses = [...allCourses]
      ..sort((a, b) => b.rating.compareTo(a.rating))
      ..take(4).toList();

    // Get recommended courses based on enrolled category
    final recommendedCourses = _getRecommendedCourses(allCourses, enrollments);

    final categories = _courseController.extractCategories(allCourses);

    final recentlyViewed = enrollments.isEmpty ? null : enrollments.first;
    EnrollmentModel? recentlyEnrolled;
    if (enrollments.isNotEmpty) {
      final sortedByEnrollment = [...enrollments]
        ..sort((a, b) {
          final aDate = a.enrolledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.enrolledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
      recentlyEnrolled = sortedByEnrollment.first;
    }

    return DashboardData(
      studentName: studentName,
      motivationalText: _motivationalTextForToday(),
      allCourses: allCourses,
      continueLearning: enrollments,
      featuredCourses: featuredCourses.isEmpty
          ? allCourses.take(4).toList()
          : featuredCourses,
      trendingCourses: trendingCourses,
      recommendedCourses: recommendedCourses,
      categories: categories,
      userStats: userStats,
      recentlyViewed: recentlyViewed,
      recentlyEnrolled: recentlyEnrolled,
    );
  }

  Future<String> _fetchStudentName() async {
    final user = _auth.currentUser;
    if (user == null) {
      return 'Student';
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      final name = (data?['name'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        return name;
      }
    } catch (_) {
      // Fallback below uses auth state.
    }

    final authName = (user.displayName ?? '').trim();
    if (authName.isNotEmpty) {
      return authName;
    }

    return 'Student';
  }

  Future<UserStats> _fetchUserStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const UserStats(
        streakDays: 0,
        totalCoursesEnrolled: 0,
        totalCoursesCompleted: 0,
        totalLearningHours: 0,
        currentWeekLearningHours: 0,
        averageRating: 0,
        lastActiveAt: null,
      );
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stats')
          .doc('overview')
          .get();

      if (doc.exists) {
        return UserStats.fromMap(doc.data() ?? {});
      }
    } catch (_) {
      // Use default stats
    }

    return const UserStats(
      streakDays: 0,
      totalCoursesEnrolled: 0,
      totalCoursesCompleted: 0,
      totalLearningHours: 0,
      currentWeekLearningHours: 0,
      averageRating: 0,
      lastActiveAt: null,
    );
  }

  List<CourseModel> _getRecommendedCourses(
    List<CourseModel> allCourses,
    List<EnrollmentModel> enrollments,
  ) {
    if (enrollments.isEmpty) {
      // If no enrollments, recommend top-rated courses
      return [...allCourses]
        ..sort((a, b) => b.rating.compareTo(a.rating))
        ..take(4).toList();
    }

    // Get categories from enrolled courses
    final enrolledCategories = enrollments.map((e) => e.courseCategory).toSet();

    // Recommend similar courses from same categories
    final recommended = allCourses
        .where((course) => enrolledCategories.contains(course.category))
        .where((course) => !enrollments.any((e) => e.courseId == course.id))
        .toList();

    recommended.sort((a, b) => b.rating.compareTo(a.rating));
    return recommended.take(4).toList();
  }

  String _motivationalTextForToday() {
    const lines = [
      'Keep going, you\'re doing great! 🌟',
      'Consistency beats motivation. Keep learning! 💪',
      'Small lessons today, big wins tomorrow. 🚀',
      'Your future skills are built one session at a time. 📚',
      'Progress beats perfection. Keep pushing! 🎯',
      'Every expert was once a beginner. 🌱',
      'You\'re one step closer to mastery! 👑',
      'Learning is the best investment! 💎',
    ];
    final index = DateTime.now().day % lines.length;
    return lines[index];
  }
}
