import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnalyticsController {
  AdminAnalyticsController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Get overall analytics dashboard data
  Future<Map<String, dynamic>> getDashboardMetrics() async {
    try {
      // Get user counts
      final totalUsersSnapshot = await _firestore
          .collection('users')
          .count()
          .get();
      final studentCountSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .count()
          .get();
      final mentorCountSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'mentor')
          .count()
          .get();

      // Get course data
      final totalCoursesSnapshot = await _firestore
          .collection('courses')
          .count()
          .get();
      final enrollmentsSnapshot = await _firestore
          .collection('enrollments')
          .count()
          .get();

      // Get revenue data (if exists)
      final transactionsSnapshot = await _firestore
          .collection('payments')
          .get();

      double totalRevenue = 0;
      for (final doc in transactionsSnapshot.docs) {
        totalRevenue += (doc['amount'] as num?)?.toDouble() ?? 0;
      }

      return {
        'totalUsers': totalUsersSnapshot.count ?? 0,
        'students': studentCountSnapshot.count ?? 0,
        'mentors': mentorCountSnapshot.count ?? 0,
        'totalCourses': totalCoursesSnapshot.count ?? 0,
        'totalEnrollments': enrollmentsSnapshot.count ?? 0,
        'totalRevenue': totalRevenue,
        'averageRating': await getAverageSystemRating(),
      };
    } catch (_) {
      return {};
    }
  }

  /// Get user growth data
  Future<List<Map<String, dynamic>>> getUserGrowthData({int days = 30}) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection('users')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .orderBy('createdAt', descending: false)
        .get();

    final growthMap = <String, int>{};

    for (final doc in snapshot.docs) {
      final createdAt = (doc['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final dateStr = '${createdAt.year}-${createdAt.month}-${createdAt.day}';
        growthMap[dateStr] = (growthMap[dateStr] ?? 0) + 1;
      }
    }

    return growthMap.entries
        .map((e) => {'date': e.key, 'count': e.value})
        .toList();
  }

  /// Get course popularity data
  Future<List<Map<String, dynamic>>> getCoursePopularity() async {
    final snapshot = await _firestore.collection('courses').get();

    final courses = snapshot.docs
        .map(
          (doc) => {
            'title': doc['title'] ?? 'Unknown',
            'enrollments': doc['enrolledCount'] ?? 0,
            'rating': doc['rating'] ?? 0.0,
          },
        )
        .toList();

    // Sort by enrollments
    courses.sort(
      (a, b) => (b['enrollments'] as int).compareTo(a['enrollments'] as int),
    );

    return courses.take(10).toList();
  }

  /// Get category distribution
  Future<List<Map<String, dynamic>>> getCategoryDistribution() async {
    final snapshot = await _firestore.collection('courses').get();

    final categoryMap = <String, int>{};

    for (final doc in snapshot.docs) {
      final category = doc['category'] as String? ?? 'Uncategorized';
      categoryMap[category] = (categoryMap[category] ?? 0) + 1;
    }

    return categoryMap.entries
        .map((e) => {'category': e.key, 'count': e.value})
        .toList();
  }

  /// Get mentor performance data
  Future<List<Map<String, dynamic>>> getMentorPerformance() async {
    final mentorsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'mentor')
        .get();

    final mentorData = <Map<String, dynamic>>[];

    for (final mentorDoc in mentorsSnapshot.docs) {
      final mentorId = mentorDoc.id;
      final mentorName = mentorDoc['name'] ?? 'Unknown';

      final coursesCount = await _firestore
          .collection('courses')
          .where('mentorId', isEqualTo: mentorId)
          .count()
          .get();

      final studentsCount = await _firestore
          .collection('enrollments')
          .where('mentorId', isEqualTo: mentorId)
          .count()
          .get();

      final reviewsSnapshot = await _firestore
          .collection('course_reviews')
          .where('mentorId', isEqualTo: mentorId)
          .get();

      double avgRating = 0;
      if (reviewsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (final review in reviewsSnapshot.docs) {
          totalRating += (review['rating'] as num?)?.toDouble() ?? 0;
        }
        avgRating = totalRating / reviewsSnapshot.docs.length;
      }

      mentorData.add({
        'name': mentorName,
        'courses': coursesCount.count ?? 0,
        'students': studentsCount.count ?? 0,
        'rating': avgRating,
        'reviews': reviewsSnapshot.docs.length,
      });
    }

    // Sort by students count
    mentorData.sort(
      (a, b) => (b['students'] as int).compareTo(a['students'] as int),
    );

    return mentorData;
  }

  /// Get average system rating
  Future<double> getAverageSystemRating() async {
    final snapshot = await _firestore.collection('course_reviews').get();

    if (snapshot.docs.isEmpty) return 0.0;

    double totalRating = 0;
    for (final doc in snapshot.docs) {
      totalRating += (doc['rating'] as num?)?.toDouble() ?? 0;
    }

    return totalRating / snapshot.docs.length;
  }

  /// Get revenue data by date
  Future<List<Map<String, dynamic>>> getRevenueData({int days = 30}) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection('payments')
        .where('paidAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('paidAt', descending: false)
        .get();

    final revenueMap = <String, double>{};

    for (final doc in snapshot.docs) {
      final createdAt = (doc['paidAt'] as Timestamp?)?.toDate();
      final amount = (doc['amount'] as num?)?.toDouble() ?? 0;
      if (createdAt != null) {
        final dateStr = '${createdAt.year}-${createdAt.month}-${createdAt.day}';
        revenueMap[dateStr] = (revenueMap[dateStr] ?? 0) + amount;
      }
    }

    return revenueMap.entries
        .map((e) => {'date': e.key, 'revenue': e.value})
        .toList();
  }
}
