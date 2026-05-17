import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnrolledStudent {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final DateTime enrolledAt;
  final int progressPercentage;

  EnrolledStudent({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.enrolledAt,
    required this.progressPercentage,
  });

  factory EnrolledStudent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EnrolledStudent(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      courseId: data['courseId'] ?? '',
      enrolledAt:
          (data['enrolledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      progressPercentage: data['progressPercentage'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'studentId': studentId,
    'studentName': studentName,
    'courseId': courseId,
    'enrolledAt': Timestamp.fromDate(enrolledAt),
    'progressPercentage': progressPercentage,
  };
}

class MentorStudentsController {
  MentorStudentsController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Get all enrolled students for a course
  Stream<List<EnrolledStudent>> getEnrolledStudents(String courseId) {
    return _firestore
        .collection('enrollments')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .asyncMap((snapshot) async {
          final students = <EnrolledStudent>[];
          for (final doc in snapshot.docs) {
            students.add(EnrolledStudent.fromFirestore(doc));
          }
          return students;
        });
  }

  /// Get all students for mentor's courses
  Stream<List<EnrolledStudent>> getAllMentorStudents() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('enrollments')
        .where('mentorId', isEqualTo: uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final students = <EnrolledStudent>[];
          for (final doc in snapshot.docs) {
            students.add(EnrolledStudent.fromFirestore(doc));
          }
          return students;
        });
  }

  /// Get total enrolled students count
  Future<int> getTotalEnrolledCount() async {
    final uid = currentUserId;
    if (uid == null) return 0;

    final snapshot = await _firestore
        .collection('enrollments')
        .where('mentorId', isEqualTo: uid)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Send notification to a student
  Future<void> sendStudentNotification({
    required String studentId,
    required String title,
    required String message,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': studentId,
      'title': title,
      'message': message,
      'createdAt': Timestamp.now(),
      'read': false,
    });
  }

  /// Send notification to all students in a course
  Future<void> sendBulkNotification({
    required String courseId,
    required String title,
    required String message,
  }) async {
    final enrollments = await _firestore
        .collection('enrollments')
        .where('courseId', isEqualTo: courseId)
        .get();

    for (final enrollment in enrollments.docs) {
      final studentId = enrollment['studentId'] as String?;
      if (studentId != null) {
        await sendStudentNotification(
          studentId: studentId,
          title: title,
          message: message,
        );
      }
    }
  }
}
