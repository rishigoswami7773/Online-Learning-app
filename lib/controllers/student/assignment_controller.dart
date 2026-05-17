import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../models/assignment_model.dart';

class StudentAssignmentController {
  StudentAssignmentController({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  /// Fetch assignments for a course module
  Future<List<AssignmentModel>> fetchModuleAssignments(
    String courseId,
    String moduleId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .where('moduleId', isEqualTo: moduleId)
          .orderBy('dueDate')
          .get();

      return snapshot.docs.map(AssignmentModel.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching assignments: $e');
      return [];
    }
  }

  /// Fetch all assignments for a course
  Future<List<AssignmentModel>> fetchCourseAssignments(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .orderBy('dueDate')
          .get();

      return snapshot.docs.map(AssignmentModel.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching course assignments: $e');
      return [];
    }
  }

  /// Fetch a single assignment
  Future<AssignmentModel?> fetchAssignment(String assignmentId) async {
    try {
      final doc = await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .get();

      if (!doc.exists) return null;
      return AssignmentModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching assignment: $e');
      return null;
    }
  }

  /// Check if student has already submitted an assignment
  Future<AssignmentSubmissionModel?> fetchStudentSubmission(
    String assignmentId,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final docId = '${userId}_$assignmentId';
      final doc = await _firestore
          .collection('assignmentSubmissions')
          .doc(docId)
          .get();

      if (!doc.exists) return null;
      return AssignmentSubmissionModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching submission: $e');
      return null;
    }
  }

  /// Upload file to Firebase Storage and submit assignment
  Future<AssignmentSubmissionModel?> submitAssignment({
    required String assignmentId,
    required String courseId,
    required String moduleId,
    required String fileBytes,
    required String fileName,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('No authenticated user');
        return null;
      }

      // Upload file to Firebase Storage
      final filePath = 'assignments/$assignmentId/$userId/$fileName';
      final ref = _storage.ref(filePath);

      // Upload bytes (for web)
      await ref.putString(fileBytes);
      final fileUrl = await ref.getDownloadURL();

      // Create submission document
      final docId = '${userId}_$assignmentId';
      final submission = AssignmentSubmissionModel(
        id: docId,
        userId: userId,
        assignmentId: assignmentId,
        courseId: courseId,
        moduleId: moduleId,
        fileUrl: fileUrl,
        submittedAt: DateTime.now(),
      );

      await _firestore
          .collection('assignmentSubmissions')
          .doc(docId)
          .set(submission.toMap());

      return submission;
    } catch (e) {
      debugPrint('Error submitting assignment: $e');
      return null;
    }
  }

  /// Get all submissions for a student
  Future<List<AssignmentSubmissionModel>> fetchStudentSubmissions({
    String? courseId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      var query = _firestore
          .collection('assignmentSubmissions')
          .where('userId', isEqualTo: userId);

      if (courseId != null) {
        query = query.where('courseId', isEqualTo: courseId);
      }

      final snapshot = await query
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs
          .map(AssignmentSubmissionModel.fromFirestore)
          .toList();
    } catch (e) {
      debugPrint('Error fetching submissions: $e');
      return [];
    }
  }

  /// Get submission status for all assignments in a module
  Future<Map<String, AssignmentSubmissionModel?>> fetchModuleSubmissionStatus(
    String courseId,
    String moduleId,
  ) async {
    try {
      final assignments = await fetchModuleAssignments(courseId, moduleId);
      final submissions = <String, AssignmentSubmissionModel?>{};

      for (final assignment in assignments) {
        final submission = await fetchStudentSubmission(assignment.id);
        submissions[assignment.id] = submission;
      }

      return submissions;
    } catch (e) {
      debugPrint('Error fetching module submission status: $e');
      return {};
    }
  }
}
