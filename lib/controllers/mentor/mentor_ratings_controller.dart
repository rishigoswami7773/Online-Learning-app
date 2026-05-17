import 'dart:async';

import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/uid_resolver.dart';

class MentorRatingsController {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  String get uid => UidResolver.uid ?? '';

  /// Streams all reviews for the mentor's courses as a flattened list.
  Stream<List<QueryDocumentSnapshot>> reviewsStream() async* {
    if (uid.isEmpty) return;
    final coursesSnap = await _fs
        .collection('courses')
        .where('mentorId', isEqualTo: uid)
        .get();
    final courseIds = coursesSnap.docs.map((d) => d.id).toList();
    if (courseIds.isEmpty) {
      yield <QueryDocumentSnapshot>[];
      return;
    }
    // Firestore 'in' supports up to 10 items — fall back to single queries if needed
    if (courseIds.length <= 10) {
      yield* _fs
          .collection('course_reviews')
          .where('courseId', whereIn: courseIds)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs);
    } else {
      // for >10, listen to each course reviews stream and merge
      final controllers = <Stream<List<QueryDocumentSnapshot>>>[];
      for (final id in courseIds) {
        controllers.add(
          _fs
              .collection('course_reviews')
              .where('courseId', isEqualTo: id)
              .orderBy('createdAt', descending: true)
              .snapshots()
              .map((s) => s.docs),
        );
      }
      await for (final lists in StreamZip(controllers)) {
        final merged = <QueryDocumentSnapshot>[];
        for (final l in lists) {
          merged.addAll(l);
        }
        yield merged;
      }
    }
  }

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
            final avg = (d.data()['averageRating'] as num?)?.toDouble() ?? 0.0;
            final rc = (d.data()['reviewCount'] as num?)?.toInt() ?? 0;
            if (rc > 0) {
              total += avg * rc;
              count += rc;
            }
          }
          return count > 0 ? (total / count) : 0.0;
        });
  }
}
