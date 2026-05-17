import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/uid_resolver.dart';

class MentorNotificationsController {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  String get uid => UidResolver.uid ?? '';

  /// Stream of notifications for this mentor from subcollection.
  /// Matches the path that admin writes to: notifications/{uid}/items/{auto-id}
  Stream<QuerySnapshot> notificationsStream() {
    if (uid.isEmpty) return const Stream.empty();
    return _fs
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markRead(String docId) async {
    if (docId.isEmpty || uid.isEmpty) return;
    await _fs
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .doc(docId)
        .update({'isRead': true, 'read': true});
  }
}
