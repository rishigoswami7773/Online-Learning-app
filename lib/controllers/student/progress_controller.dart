import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CourseProgress {
  final String id;
  final String userId;
  final String courseId;
  final int totalLessons;
  final int completedLessons;
  final List<int> completedLessonIndices;
  final int watchTimeMinutes;
  final DateTime enrolledAt;
  final DateTime? completedAt;

  CourseProgress({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.totalLessons,
    required this.completedLessons,
    required this.completedLessonIndices,
    required this.watchTimeMinutes,
    required this.enrolledAt,
    this.completedAt,
  });

  double get completionPercentage {
    if (totalLessons == 0) return 0;
    return completionFraction * 100;
  }

  double get completionFraction {
    if (totalLessons == 0) return 0;
    return (completedLessons / totalLessons).clamp(0.0, 1.0);
  }

  factory CourseProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseProgress(
      id: doc.id,
      userId: data['userId'] ?? data['studentId'] ?? '',
      courseId: data['courseId'] ?? '',
      totalLessons: data['totalLessons'] ?? 0,
      completedLessons:
          data['completedLessons'] ?? data['lessonsCompleted'] ?? 0,
      completedLessonIndices: List<int>.from(
        data['completedLessonIndices'] ?? [],
      ),
      watchTimeMinutes: data['watchTimeMinutes'] ?? 0,
      enrolledAt:
          (data['enrolledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'studentId': userId,
    'courseId': courseId,
    'totalLessons': totalLessons,
    'completedLessons': completedLessons,
    'lessonsCompleted': completedLessons,
    'progress': completionFraction,
    'progressPercent': completionPercentage,
    'completedLessonIndices': completedLessonIndices,
    'watchTimeMinutes': watchTimeMinutes,
    'enrolledAt': Timestamp.fromDate(enrolledAt),
    'completedAt': completedAt != null
        ? Timestamp.fromDate(completedAt!)
        : null,
  };
}

class ProgressController {
  ProgressController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Get progress for a specific course
  Future<CourseProgress?> getCourseProgress(String courseId) async {
    final uid = currentUserId;
    if (uid == null) return null;

    // enrollments is the live source; progress was a legacy collection.
    final query = await _firestore
        .collection('enrollments')
        .where('studentId', isEqualTo: uid)
        .where('courseId', isEqualTo: courseId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return CourseProgress.fromFirestore(query.docs.first);
  }

  /// Stream all progress for current user
  Stream<List<CourseProgress>> getAllProgress() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('enrollments')
        .where('studentId', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CourseProgress.fromFirestore(doc))
              .toList(),
        );
  }

  /// Mark lesson as completed
  Future<void> markLessonComplete(String courseId, int lessonIndex) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    final progress = await getCourseProgress(courseId);
    if (progress == null) {
      throw Exception('Course progress not found');
    }

    final updatedIndices = {
      ...progress.completedLessonIndices,
      lessonIndex,
    }.toList()..sort();
    final newCompletedCount = updatedIndices.length;
    final progressFraction = progress.totalLessons == 0
        ? 0.0
        : (newCompletedCount / progress.totalLessons).clamp(0.0, 1.0);

    await _firestore.collection('enrollments').doc(progress.id).update({
      'completedLessonIndices': updatedIndices,
      'completedLessons': newCompletedCount,
      'lessonsCompleted': newCompletedCount,
      'progress': progressFraction,
      'progressPercent': progressFraction * 100,
      'lastAccessedAt': FieldValue.serverTimestamp(),
      if (newCompletedCount == progress.totalLessons) 'status': 'completed',
      if (newCompletedCount == progress.totalLessons)
        'completedAt': Timestamp.now(),
    });
  }

  /// Update watch time for a course
  Future<void> updateWatchTime(String courseId, int additionalMinutes) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    final progress = await getCourseProgress(courseId);
    if (progress == null) {
      throw Exception('Course progress not found');
    }

    await _firestore.collection('progress').doc(progress.id).update({
      'watchTimeMinutes': progress.watchTimeMinutes + additionalMinutes,
    });
  }

  /// Create initial progress for newly enrolled course
  Future<String> createProgress({
    required String courseId,
    required int totalLessons,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    final progress = CourseProgress(
      id: '',
      userId: uid,
      courseId: courseId,
      totalLessons: totalLessons,
      completedLessons: 0,
      completedLessonIndices: [],
      watchTimeMinutes: 0,
      enrolledAt: DateTime.now(),
    );

    final docRef = await _firestore.collection('enrollments').add({
      ...progress.toFirestore(),
      'status': 'active',
    });
    return docRef.id;
  }

  /// Get overall completion stats
  Future<Map<String, dynamic>> getCompletionStats() async {
    final uid = currentUserId;
    if (uid == null) return {};

    final progressDocs = await _firestore
        .collection('enrollments')
        .where('studentId', isEqualTo: uid)
        .get();

    int totalCourses = 0;
    int completedCourses = 0;
    double avgCompletion = 0;

    if (progressDocs.docs.isNotEmpty) {
      totalCourses = progressDocs.docs.length;
      double totalPercentage = 0;

      for (final doc in progressDocs.docs) {
        final progress = CourseProgress.fromFirestore(doc);
        totalPercentage += progress.completionPercentage;
        if (progress.completionPercentage == 100) {
          completedCourses++;
        }
      }

      avgCompletion = totalPercentage / totalCourses;
    }

    return {
      'totalCourses': totalCourses,
      'completedCourses': completedCourses,
      'averageCompletion': avgCompletion,
    };
  }
}
