import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/uid_resolver.dart';

class MentorStudentsController {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  String get uid => UidResolver.uid ?? '';

  Stream<QuerySnapshot<Map<String, dynamic>>> enrollmentsStream() {
    if (uid.isEmpty) return const Stream.empty();
    return _fs
        .collection('enrollments')
        .where('mentorId', isEqualTo: uid)
        .orderBy('enrolledAt', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getUser(String uid) async {
    if (uid.isEmpty) return null;
    final doc = await _fs.collection('users').doc(uid).get();
    return doc.exists ? doc : null;
  }
}
