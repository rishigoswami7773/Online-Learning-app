import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentController {
  StudentController({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> saveStudentDataToFirestore({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String? dob,
    required String gender,
    required String educationLevel,
    required String classYear,
    required String stream,
    required List<String> courses,
    required Map<String, dynamic> preferences,
    required String referralCode,
    String profileImage = '',
  }) async {
    final batch = _firestore.batch();
    final location = Map<String, dynamic>.from(
      preferences['location'] as Map? ?? const <String, dynamic>{},
    );
    final languagePreference =
        (preferences['languagePreference'] as String? ?? '').trim();
    final learningGoal = (preferences['learningGoal'] as String? ?? '').trim();

    final usersRef = _firestore.collection('users').doc(userId);
    batch.set(usersRef, {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'dob': dob ?? '',
      'gender': gender,
      'city': (location['city'] as String? ?? '').trim(),
      'state': (location['state'] as String? ?? '').trim(),
      'country': (location['country'] as String? ?? '').trim(),
      'languagePreference': languagePreference,
      'learningGoals': learningGoal,
      'selectedCourses': courses,
      'role': 'student',
      'profileImage': profileImage,
      'isVerified': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final profileRef = _firestore.collection('student_profiles').doc(userId);
    batch.set(profileRef, {
      'userId': userId,
      'dob': dob,
      'gender': gender,
      'educationLevel': educationLevel,
      'classYear': classYear,
      'stream': stream,
      'courses': courses,
      'preferences': preferences,
      'referralCode': referralCode,
      'languagePreference': languagePreference,
      'learningGoals': learningGoal,
      'city': (location['city'] as String? ?? '').trim(),
      'state': (location['state'] as String? ?? '').trim(),
      'country': (location['country'] as String? ?? '').trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<Map<String, dynamic>?> getStudentProfile(String userId) async {
    final profileDoc = await _firestore
        .collection('student_profiles')
        .doc(userId)
        .get();
    return profileDoc.data();
  }

  Future<void> updateStudentProfile(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    final data = Map<String, dynamic>.from(payload)
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('student_profiles')
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }

  Future<void> deleteStudentAccount(String userId) async {
    final batch = _firestore.batch();

    batch.delete(_firestore.collection('users').doc(userId));
    batch.delete(_firestore.collection('student_profiles').doc(userId));

    await batch.commit();

    if (_auth.currentUser?.uid == userId) {
      await _auth.currentUser?.delete();
    }
  }
}
