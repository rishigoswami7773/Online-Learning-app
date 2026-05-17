import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/uid_resolver.dart';

class MentorDashboardController {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  String get uid => UidResolver.uid ?? '';

  Stream<int> coursesCountStream() {
    if (uid.isEmpty) return const Stream<int>.empty();
    return _fs
        .collection('courses')
        .where('mentorId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Count enrollments across all of this mentor's courses.
  /// We first get all courseIds, then count enrollments with courseId in that list.
  Stream<int> enrollmentsCountStream() {
    if (uid.isEmpty) return const Stream<int>.empty();

    // Stream of course IDs for this mentor
    return _fs
        .collection('courses')
        .where('mentorId', isEqualTo: uid)
        .snapshots()
        .asyncMap((courseSnap) async {
          final courseIds = courseSnap.docs.map((d) => d.id).toList();
          if (courseIds.isEmpty) return 0;

          // Firestore whereIn supports up to 30 items
          int total = 0;
          for (int i = 0; i < courseIds.length; i += 30) {
            final chunk = courseIds.skip(i).take(30).toList();
            final enSnap = await _fs
                .collection('enrollments')
                .where('courseId', whereIn: chunk)
                .count()
                .get();
            total += enSnap.count ?? 0;
          }
          return total;
        });
  }

  /// Average rating computed from mentor's courses' `averageRating` fields.
  Stream<double> averageRatingStream() {
    if (uid.isEmpty) return const Stream<double>.empty();
    return _fs
        .collection('courses')
        .where('mentorId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final docs = snap.docs;
          double total = 0.0;
          int count = 0;
          for (final d in docs) {
            final avg = (d.data()['averageRating'] as num?)?.toDouble() ??
                (d.data()['rating'] as num?)?.toDouble() ?? 0.0;
            if (avg > 0) {
              total += avg;
              count++;
            }
          }
          return count > 0 ? (total / count) : 0.0;
        });
  }

  void dispose() {}
}
