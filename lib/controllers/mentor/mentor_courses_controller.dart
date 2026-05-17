import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/uid_resolver.dart';

class MentorCoursesController {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  String get uid => UidResolver.uid ?? '';

  Stream<QuerySnapshot> myCoursesStream() {
    if (uid.isEmpty) return const Stream.empty();
    // orderBy removed — requires a Firestore composite index
    return _fs
        .collection('courses')
        .where('mentorId', isEqualTo: uid)
        .snapshots();
  }

  /// Get enrolled students for a specific course
  Future<List<Map<String, dynamic>>> getEnrolledStudents(
    String courseId,
  ) async {
    try {
      final enrollments = await _fs
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .get();

      final students = <Map<String, dynamic>>[];
      for (final enrollment in enrollments.docs) {
        final data = enrollment.data();
        final studentId = data['studentId'] as String?;
        if (studentId != null) {
          final userDoc = await _fs.collection('users').doc(studentId).get();
          final userData = userDoc.data() ?? {};
          students.add({
            'id': studentId,
            'name': userData['name'] ?? 'Student',
            'email': userData['email'] ?? '',
            'progress': (data['progress'] as num?)?.toDouble() ?? 0.0,
            'completedLessons':
                (data['completedLessons'] as num?)?.toInt() ?? 0,
            'totalLessons': (data['totalLessons'] as num?)?.toInt() ?? 10,
            'enrolledAt': data['enrolledAt'],
          });
        }
      }
      return students;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all mentor courses with summary statistics
  Future<List<Map<String, dynamic>>> getCourseSummary() async {
    try {
      if (uid.isEmpty) return [];

      final courses = await _fs
          .collection('courses')
          .where('mentorId', isEqualTo: uid)
          .get();

      final summaries = <Map<String, dynamic>>[];
      for (final courseDoc in courses.docs) {
        final courseData = courseDoc.data();

        // Get enrollment count
        final enrollments = await _fs
            .collection('enrollments')
            .where('courseId', isEqualTo: courseDoc.id)
            .count()
            .get();

        // Get average rating
        final reviews = await _fs
            .collection('course_reviews')
            .where('courseId', isEqualTo: courseDoc.id)
            .get();

        double avgRating = 0.0;
        if (reviews.docs.isNotEmpty) {
          final ratings = reviews.docs
              .map((r) => ((r.data()['rating'] as num?)?.toDouble() ?? 0.0))
              .toList();
          avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
        }

        summaries.add({
          'id': courseDoc.id,
          'title': courseData['title'] ?? 'Untitled',
          'category': courseData['category'] ?? 'General',
          'status': courseData['status'] ?? 'draft',
          'enrollmentCount': enrollments.count ?? 0,
          'rating': avgRating,
          'reviewCount': reviews.docs.length,
          'createdAt': courseData['createdAt'],
          'price': (courseData['price'] as num?)?.toDouble() ?? 0.0,
        });
      }
      return summaries;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete course material (file) from a course
  Future<void> deleteCourseMaterial(String courseId, int materialIndex) async {
    try {
      final courseRef = _fs.collection('courses').doc(courseId);
      final courseDoc = await courseRef.get();
      final materials = List<Map<String, dynamic>>.from(
        (courseDoc.data()?['courseMaterials'] as List?) ?? [],
      );

      if (materialIndex >= 0 && materialIndex < materials.length) {
        materials.removeAt(materialIndex);
        await courseRef.update({'courseMaterials': materials});
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Add course material metadata
  Future<void> addCourseMaterial(
    String courseId,
    Map<String, String> material,
  ) async {
    try {
      final courseRef = _fs.collection('courses').doc(courseId);
      await courseRef.update({
        'courseMaterials': FieldValue.arrayUnion([material]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get student progress statistics for a course
  Future<Map<String, dynamic>> getCourseProgressStats(String courseId) async {
    try {
      final enrollments = await _fs
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .get();

      if (enrollments.docs.isEmpty) {
        return {
          'totalStudents': 0,
          'averageProgress': 0.0,
          'completedCount': 0,
          'inProgressCount': 0,
          'notStartedCount': 0,
        };
      }

      final progressValues = enrollments.docs
          .map((d) => ((d.data()['progress'] as num?)?.toDouble() ?? 0.0))
          .toList();

      final completed = progressValues.where((p) => p >= 1.0).length;
      final inProgress = progressValues.where((p) => p > 0.0 && p < 1.0).length;
      final notStarted = progressValues.where((p) => p == 0.0).length;

      final avgProgress =
          progressValues.reduce((a, b) => a + b) / progressValues.length;

      return {
        'totalStudents': enrollments.docs.length,
        'averageProgress': avgProgress,
        'completedCount': completed,
        'inProgressCount': inProgress,
        'notStartedCount': notStarted,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCourse(String courseId) async {
    final batch = _fs.batch();
    final courseRef = _fs.collection('courses').doc(courseId);
    // delete enrollments and reviews related to this course
    final enrollments = await _fs
        .collection('enrollments')
        .where('courseId', isEqualTo: courseId)
        .get();
    for (final e in enrollments.docs) {
      batch.delete(e.reference);
    }
    final reviews = await _fs
        .collection('course_reviews')
        .where('courseId', isEqualTo: courseId)
        .get();
    for (final r in reviews.docs) {
      batch.delete(r.reference);
    }
    batch.delete(courseRef);
    await batch.commit();
  }

  Future<void> togglePublish(String courseId, bool publish) async {
    await _fs.collection('courses').doc(courseId).update({
      'isPublished': publish,
      'status': publish ? 'active' : 'draft',
    });
  }
}
