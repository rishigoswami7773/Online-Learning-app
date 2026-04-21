import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/student/course_model.dart';
import '../../models/student/enrollment_model.dart';

class EnrollmentController {
  EnrollmentController({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  Future<List<EnrollmentModel>>? _cachedEnrollmentsFuture;

  Future<List<EnrollmentModel>> fetchEnrollments({
    bool forceRefresh = false,
  }) async {
    final enrollments = await _loadEnrollments(forceRefresh: forceRefresh);
    return enrollments;
  }

  Future<List<EnrollmentModel>> _loadEnrollments({bool forceRefresh = false}) {
    if (!forceRefresh) {
      final cachedEnrollmentsFuture = _cachedEnrollmentsFuture;
      if (cachedEnrollmentsFuture != null) {
        return cachedEnrollmentsFuture;
      }
    }

    final future = _fetchEnrollmentsFromSource();
    if (!forceRefresh) {
      _cachedEnrollmentsFuture = future;
    }
    return future;
  }

  Future<List<EnrollmentModel>> _fetchEnrollmentsFromSource() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return _buildDummyEnrollments();
    }

    List<EnrollmentModel> enrollments = const <EnrollmentModel>[];

    try {
      final snapshot = await _firestore
          .collection('enrolled_courses')
          .where('userId', isEqualTo: userId)
          .get();
      enrollments = snapshot.docs.map(EnrollmentModel.fromFirestore).toList();
    } catch (_) {
      enrollments = const <EnrollmentModel>[];
    }

    if (enrollments.isEmpty) {
      return _buildDummyEnrollments(userId: userId);
    }

    enrollments.sort((a, b) {
      final aDate = a.lastViewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.lastViewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return enrollments;
  }

  Future<List<EnrollmentModel>> getInProgressCourses({
    bool forceRefresh = false,
  }) async {
    final enrollments = await fetchEnrollments(forceRefresh: forceRefresh);
    return enrollments.where((enrollment) => !enrollment.isCompleted).toList();
  }

  Future<List<EnrollmentModel>> getCompletedCourses({
    bool forceRefresh = false,
  }) async {
    final enrollments = await fetchEnrollments(forceRefresh: forceRefresh);
    return enrollments.where((enrollment) => enrollment.isCompleted).toList();
  }

  List<EnrollmentModel> _buildDummyEnrollments({String userId = 'student'}) {
    final now = DateTime.now();
    final seedCourses = CourseModel.dummyCourses.take(3).toList();

    return [
      EnrollmentModel(
        id: 'enr-1',
        userId: userId,
        courseId: seedCourses[0].id,
        courseTitle: seedCourses[0].title,
        courseCategory: seedCourses[0].category,
        courseThumbnail: seedCourses[0].thumbnailUrl,
        progress: 0.42,
        totalLessons: seedCourses[0].totalLessons,
        completedLessons: 15,
        lastViewedAt: now.subtract(const Duration(hours: 3)),
        enrolledAt: now.subtract(const Duration(days: 28)),
      ),
      EnrollmentModel(
        id: 'enr-2',
        userId: userId,
        courseId: seedCourses[1].id,
        courseTitle: seedCourses[1].title,
        courseCategory: seedCourses[1].category,
        courseThumbnail: seedCourses[1].thumbnailUrl,
        progress: 0.18,
        totalLessons: seedCourses[1].totalLessons,
        completedLessons: 5,
        lastViewedAt: now.subtract(const Duration(days: 1, hours: 4)),
        enrolledAt: now.subtract(const Duration(days: 10)),
      ),
      EnrollmentModel(
        id: 'enr-3',
        userId: userId,
        courseId: seedCourses[2].id,
        courseTitle: seedCourses[2].title,
        courseCategory: seedCourses[2].category,
        courseThumbnail: seedCourses[2].thumbnailUrl,
        progress: 0.74,
        totalLessons: seedCourses[2].totalLessons,
        completedLessons: 22,
        lastViewedAt: now.subtract(const Duration(days: 4)),
        enrolledAt: now.subtract(const Duration(days: 40)),
      ),
    ];
  }
}
