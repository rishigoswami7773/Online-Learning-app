import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistController {
  WishlistController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Get wishlist courses for current user
  Stream<List<Map<String, dynamic>>> getWishlist() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('wishlist')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final courses = <Map<String, dynamic>>[];
          for (final doc in snapshot.docs) {
            final courseId = doc['courseId'] as String?;
            if (courseId != null) {
              try {
                final courseDocs = await _firestore
                    .collection('courses')
                    .doc(courseId)
                    .get();
                if (courseDocs.exists) {
                  courses.add({...courseDocs.data() ?? {}, 'id': courseId});
                }
              } catch (_) {}
            }
          }
          return courses;
        });
  }

  /// Add course to wishlist
  Future<void> addToWishlist(String courseId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    // Check if already in wishlist
    final existing = await _firestore
        .collection('wishlist')
        .where('userId', isEqualTo: uid)
        .where('courseId', isEqualTo: courseId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return;
    }

    await _firestore.collection('wishlist').add({
      'userId': uid,
      'courseId': courseId,
      'addedAt': Timestamp.now(),
    });
  }

  /// Remove course from wishlist
  Future<void> removeFromWishlist(String courseId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    final query = await _firestore
        .collection('wishlist')
        .where('userId', isEqualTo: uid)
        .where('courseId', isEqualTo: courseId)
        .get();

    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }

  /// Check if course is in wishlist
  Future<bool> isInWishlist(String courseId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    final query = await _firestore
        .collection('wishlist')
        .where('userId', isEqualTo: uid)
        .where('courseId', isEqualTo: courseId)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }
}
