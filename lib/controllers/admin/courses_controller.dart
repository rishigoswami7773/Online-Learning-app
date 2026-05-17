import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCoursesController {
  AdminCoursesController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Get all courses
  Stream<QuerySnapshot> getAllCourses() {
    return _firestore
        .collection('courses')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get courses by category
  Stream<QuerySnapshot> getCoursesByCategory(String category) {
    return _firestore
        .collection('courses')
        .where('category', isEqualTo: category)
        .snapshots();
  }

  /// Get courses by mentor
  Stream<QuerySnapshot> getCoursesByMentor(String mentorId) {
    return _firestore
        .collection('courses')
        .where('mentorId', isEqualTo: mentorId)
        .snapshots();
  }

  /// Get course statistics
  Future<Map<String, dynamic>> getCourseStats() async {
    final coursesSnapshot = await _firestore
        .collection('courses')
        .count()
        .get();
    final enrollmentsSnapshot = await _firestore
        .collection('enrollments')
        .count()
        .get();

    return {
      'totalCourses': coursesSnapshot.count ?? 0,
      'totalEnrollments': enrollmentsSnapshot.count ?? 0,
    };
  }

  /// Approve/reject course
  Future<void> updateCourseStatus({
    required String courseId,
    required bool isApproved,
  }) async {
    await _firestore.collection('courses').doc(courseId).update({
      'isApproved': isApproved,
      'approvedAt': isApproved ? Timestamp.now() : null,
    });
  }

  /// Delete course
  Future<void> deleteCourse(String courseId) async {
    // Delete course
    await _firestore.collection('courses').doc(courseId).delete();

    // Delete related enrollments
    final enrollments = await _firestore
        .collection('enrollments')
        .where('courseId', isEqualTo: courseId)
        .get();

    for (final doc in enrollments.docs) {
      await doc.reference.delete();
    }

    // Delete course materials
    final materials = await _firestore
        .collection('course_materials')
        .where('courseId', isEqualTo: courseId)
        .get();

    for (final doc in materials.docs) {
      await doc.reference.delete();
    }

    // Delete progress records
    final progress = await _firestore
        .collection('progress')
        .where('courseId', isEqualTo: courseId)
        .get();

    for (final doc in progress.docs) {
      await doc.reference.delete();
    }
  }

  /// Feature/unfeature course
  Future<void> updateFeatureStatus({
    required String courseId,
    required bool isFeatured,
  }) async {
    await _firestore.collection('courses').doc(courseId).update({
      'isFeatured': isFeatured,
    });
  }

  /// Get categories
  Stream<QuerySnapshot> getCategories() {
    return _firestore.collection('categories').snapshots();
  }

  /// Create category
  Future<void> createCategory(String categoryName) async {
    await _firestore.collection('categories').add({
      'name': categoryName,
      'createdAt': Timestamp.now(),
    });
  }

  /// Delete category
  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
  }

  /// Search courses
  Stream<QuerySnapshot> searchCourses(String query) {
    final normalizedQuery = query.toLowerCase();
    return _firestore
        .collection('courses')
        .where('titleLower', isGreaterThanOrEqualTo: normalizedQuery)
        .where('titleLower', isLessThan: '${normalizedQuery}z')
        .snapshots();
  }
}
