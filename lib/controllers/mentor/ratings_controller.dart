import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MentorReview {
  final String id;
  final String mentorId;
  final String studentId;
  final String studentName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  MentorReview({
    required this.id,
    required this.mentorId,
    required this.studentId,
    required this.studentName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory MentorReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MentorReview(
      id: doc.id,
      mentorId: data['mentorId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'mentorId': mentorId,
    'studentId': studentId,
    'studentName': studentName,
    'rating': rating,
    'comment': comment,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class MentorRatingsController {
  MentorRatingsController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Get all reviews for current mentor
  Stream<List<MentorReview>> getMentorReviews() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('course_reviews')
        .where('mentorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MentorReview.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get average rating for mentor
  Future<double> getAverageRating() async {
    final uid = currentUserId;
    if (uid == null) return 0.0;

    final snapshot = await _firestore
        .collection('course_reviews')
        .where('mentorId', isEqualTo: uid)
        .get();

    if (snapshot.docs.isEmpty) return 0.0;

    double totalRating = 0;
    for (final doc in snapshot.docs) {
      totalRating += (doc['rating'] as num?)?.toDouble() ?? 0;
    }

    return totalRating / snapshot.docs.length;
  }

  /// Get rating summary
  Future<Map<String, dynamic>> getRatingSummary() async {
    final uid = currentUserId;
    if (uid == null) return {};

    final snapshot = await _firestore
        .collection('course_reviews')
        .where('mentorId', isEqualTo: uid)
        .get();

    final ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (final doc in snapshot.docs) {
      final rating = (doc['rating'] as num?)?.toInt() ?? 0;
      if (ratingCounts.containsKey(rating)) {
        ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
      }
    }

    final avgRating = await getAverageRating();

    return {
      'averageRating': avgRating,
      'totalReviews': snapshot.docs.length,
      'ratingDistribution': ratingCounts,
    };
  }

  /// Get reviews for a specific course
  Stream<List<MentorReview>> getCourseReviews(String courseId) {
    return _firestore
        .collection('course_reviews')
        .where('courseId', isEqualTo: courseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MentorReview.fromFirestore(doc))
              .toList(),
        );
  }

  /// Reply to a review
  Future<void> replyToReview(String reviewId, String reply) async {
    await _firestore.collection('course_reviews').doc(reviewId).update({
      'mentorReply': reply,
      'mentorReplyAt': Timestamp.now(),
    });
  }
}
