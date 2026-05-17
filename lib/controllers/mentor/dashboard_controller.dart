import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MentorCourse {
  final String id;
  final String mentorId;
  final String title;
  final String description;
  final String category;
  final double rating;
  final int enrolledCount;
  final List<String> lessons;
  final DateTime createdAt;

  MentorCourse({
    required this.id,
    required this.mentorId,
    required this.title,
    required this.description,
    required this.category,
    required this.rating,
    required this.enrolledCount,
    required this.lessons,
    required this.createdAt,
  });

  factory MentorCourse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MentorCourse(
      id: doc.id,
      mentorId: data['mentorId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      enrolledCount: data['enrolledCount'] ?? 0,
      lessons: List<String>.from(data['lessons'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'mentorId': mentorId,
    'title': title,
    'description': description,
    'category': category,
    'rating': rating,
    'enrolledCount': enrolledCount,
    'lessons': lessons,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class MentorDashboardStats {
  final int activeCourses;
  final int totalStudents;
  final double averageRating;
  final int totalEarnings;

  MentorDashboardStats({
    required this.activeCourses,
    required this.totalStudents,
    required this.averageRating,
    required this.totalEarnings,
  });
}

class MentorDashboardController {
  MentorDashboardController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Get all courses for current mentor
  Stream<List<MentorCourse>> getMentorCourses() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('courses')
        .where('mentorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MentorCourse.fromFirestore(doc))
              .toList(),
        );
  }

  /// Load dashboard stats for the UI
  Future<MentorDashboardStats> loadDashboardStats() async {
    final uid = currentUserId;
    if (uid == null) {
      return MentorDashboardStats(
        activeCourses: 0,
        totalStudents: 0,
        averageRating: 0,
        totalEarnings: 0,
      );
    }

    try {
      final coursesSnapshot = await _firestore
          .collection('courses')
          .where('mentorId', isEqualTo: uid)
          .count()
          .get();

      final enrollmentsSnapshot = await _firestore
          .collection('enrollments')
          .where('mentorId', isEqualTo: uid)
          .count()
          .get();

      final ratingsSnapshot = await _firestore
          .collection('course_reviews')
          .where('mentorId', isEqualTo: uid)
          .get();

      double avgRating = 0;
      if (ratingsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (final doc in ratingsSnapshot.docs) {
          totalRating += (doc['rating'] as num?)?.toDouble() ?? 0;
        }
        avgRating = totalRating / ratingsSnapshot.docs.length;
      }

      return MentorDashboardStats(
        activeCourses: coursesSnapshot.count ?? 0,
        totalStudents: enrollmentsSnapshot.count ?? 0,
        averageRating: avgRating,
        totalEarnings:
            0, // Add earnings calculation when payment system is implemented
      );
    } catch (e) {
      return MentorDashboardStats(
        activeCourses: 0,
        totalStudents: 0,
        averageRating: 0,
        totalEarnings: 0,
      );
    }
  }

  /// Get dashboard stats (legacy)
  Future<Map<String, dynamic>> getDashboardStats() async {
    final uid = currentUserId;
    if (uid == null) return {};

    try {
      // Get courses count
      final coursesSnapshot = await _firestore
          .collection('courses')
          .where('mentorId', isEqualTo: uid)
          .count()
          .get();

      // Get enrolled students count
      final enrollmentsSnapshot = await _firestore
          .collection('enrollments')
          .where('mentorId', isEqualTo: uid)
          .count()
          .get();

      // Get rating
      final ratingsSnapshot = await _firestore
          .collection('course_reviews')
          .where('mentorId', isEqualTo: uid)
          .get();

      double avgRating = 0;
      if (ratingsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (final doc in ratingsSnapshot.docs) {
          totalRating += (doc['rating'] as num?)?.toDouble() ?? 0;
        }
        avgRating = totalRating / ratingsSnapshot.docs.length;
      }

      return {
        'coursesCount': coursesSnapshot.count ?? 0,
        'enrolledStudentsCount': enrollmentsSnapshot.count ?? 0,
        'averageRating': avgRating,
        'totalReviews': ratingsSnapshot.docs.length,
      };
    } catch (_) {
      return {};
    }
  }
}
