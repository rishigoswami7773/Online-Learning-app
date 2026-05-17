import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MentorCoursesController {
  MentorCoursesController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Create a new course
  Future<String> createCourse({
    required String title,
    required String description,
    required String category,
    required List<String> lessons,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    final courseData = {
      'mentorId': uid,
      'title': title,
      'description': description,
      'category': category,
      'lessons': lessons,
      'rating': 0.0,
      'enrolledCount': 0,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    final docRef = await _firestore.collection('courses').add(courseData);
    return docRef.id;
  }

  /// Update an existing course
  Future<void> updateCourse({
    required String courseId,
    required String title,
    required String description,
    required String category,
    required List<String> lessons,
  }) async {
    await _firestore.collection('courses').doc(courseId).update({
      'title': title,
      'description': description,
      'category': category,
      'lessons': lessons,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete a course
  Future<void> deleteCourse(String courseId) async {
    await _firestore.collection('courses').doc(courseId).delete();

    // Delete all related enrollments
    final enrollments = await _firestore
        .collection('enrollments')
        .where('courseId', isEqualTo: courseId)
        .get();

    for (final doc in enrollments.docs) {
      await doc.reference.delete();
    }
  }

  /// Get course details
  Future<DocumentSnapshot> getCourseDetails(String courseId) async {
    return _firestore.collection('courses').doc(courseId).get();
  }

  /// Upload course content/materials
  Future<void> uploadCourseMaterial({
    required String courseId,
    required String lessonIndex,
    required String materialData,
  }) async {
    await _firestore
        .collection('course_materials')
        .doc('${courseId}_lesson_$lessonIndex')
        .set({
          'courseId': courseId,
          'lessonIndex': lessonIndex,
          'content': materialData,
          'uploadedAt': Timestamp.now(),
        });
  }
}
