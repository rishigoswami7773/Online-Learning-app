import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileController {
  ProfileController({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getStudentProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }
    return _firestore.collection('student_profiles').doc(user.uid).snapshots();
  }

  Future<void> updateUserProfile({
    required String name,
    required String phone,
    String? profileImage,
    String? dob,
    String? gender,
    String? city,
    String? state,
    String? country,
    String? educationLevel,
    String? classYear,
    String? stream,
    String? languagePreference,
    String? learningGoals,
    List<String>? selectedCourses,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    final normalizedCourses = (selectedCourses ?? const <String>[])
        .map((course) => course.trim())
        .where((course) => course.isNotEmpty)
        .toList();

    final timestamp = FieldValue.serverTimestamp();

    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();
    final role = (userDoc.data()?['role'] ?? '').toString().toLowerCase();

    await userRef.set({
      'userId': user.uid,
      'name': name.trim(),
      'email': user.email ?? '',
      'phone': phone.trim(),
      'profileImage': (profileImage ?? '').trim(),
      'dob': (dob ?? '').trim(),
      'gender': (gender ?? '').trim(),
      'city': (city ?? '').trim(),
      'state': (state ?? '').trim(),
      'country': (country ?? '').trim(),
      'languagePreference': (languagePreference ?? '').trim(),
      'learningGoals': (learningGoals ?? '').trim(),
      'selectedCourses': normalizedCourses,
      'updatedAt': timestamp,
    }, SetOptions(merge: true));

    final studentProfileRef = _firestore
        .collection('student_profiles')
        .doc(user.uid);
    final shouldWriteStudentProfile =
        role == 'student' || (await studentProfileRef.get()).exists;

    if (!shouldWriteStudentProfile) {
      return;
    }

    await studentProfileRef.set({
      'userId': user.uid,
      'dob': (dob ?? '').trim(),
      'gender': (gender ?? '').trim(),
      'educationLevel': (educationLevel ?? '').trim(),
      'classYear': (classYear ?? '').trim(),
      'stream': (stream ?? '').trim(),
      'courses': normalizedCourses,
      'preferences': {
        'languagePreference': (languagePreference ?? '').trim(),
        'learningGoal': (learningGoals ?? '').trim(),
        'location': {
          'city': (city ?? '').trim(),
          'state': (state ?? '').trim(),
          'country': (country ?? '').trim(),
        },
      },
      'updatedAt': timestamp,
    }, SetOptions(merge: true));
  }

  Future<String> uploadProfileImageFromPath({required String filePath}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    final normalizedPath = filePath.trim();
    if (normalizedPath.isEmpty) {
      throw StateError('Image path is required.');
    }

    final imageFile = File(normalizedPath);
    if (!imageFile.existsSync()) {
      throw StateError('Selected image file was not found. Please reselect.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'profileImage': normalizedPath,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return normalizedPath;
  }

  Future<void> deleteUserData({required String userId}) async {
    if (userId.isEmpty) {
      throw StateError('User ID is required.');
    }

    final batch = _firestore.batch();
    batch.delete(_firestore.collection('users').doc(userId));
    batch.delete(_firestore.collection('student_profiles').doc(userId));
    await batch.commit();
  }

  Future<void> deleteUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    final uid = user.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    final profileImagePath = (doc.data()?['profileImage'] ?? '').toString();
    if (profileImagePath.isNotEmpty) {
      final localFile = File(profileImagePath);
      if (localFile.existsSync()) {
        await localFile.delete();
      }
    }

    await deleteUserData(userId: uid);
    await user.delete();
  }
}
