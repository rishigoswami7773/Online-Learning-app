import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/quiz_model.dart';
import '../../models/quiz_result_model.dart';
import '../../models/assignment_model.dart';

class AdminQuizManagementController {
  AdminQuizManagementController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Fetch all quizzes
  Future<List<QuizModel>> fetchAllQuizzes({String? courseId}) async {
    try {
      final collection = _firestore.collection('quizzes');
      final query = courseId != null
          ? collection.where('courseId', isEqualTo: courseId)
          : collection;

      final snapshot = await query.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map(QuizModel.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching quizzes: $e');
      return [];
    }
  }

  /// Get quiz analytics
  Future<Map<String, dynamic>> getQuizAnalytics(String quizId) async {
    try {
      final resultsSnapshot = await _firestore
          .collection('quizResults')
          .where('quizId', isEqualTo: quizId)
          .get();

      final results = resultsSnapshot.docs
          .map(QuizResultModel.fromFirestore)
          .toList();

      if (results.isEmpty) {
        return {
          'totalAttempts': 0,
          'averageScore': 0.0,
          'passRate': 0.0,
          'totalStudents': 0,
        };
      }

      final totalAttempts = results.length;
      final averageScore =
          results.fold<double>(0, (acc, result) => acc + result.score) /
          totalAttempts;
      final passedCount = results.where((result) => result.passed).length;
      final passRate = (passedCount / totalAttempts * 100);
      final uniqueStudents = results
          .map((result) => result.userId)
          .toSet()
          .length;

      return {
        'totalAttempts': totalAttempts,
        'averageScore': averageScore,
        'passRate': passRate,
        'totalStudents': uniqueStudents,
        'passedCount': passedCount,
      };
    } catch (e) {
      debugPrint('Error getting quiz analytics: $e');
      return {};
    }
  }

  /// Approve/publish a quiz
  Future<bool> approveQuiz(String quizId) async {
    try {
      await _firestore.collection('quizzes').doc(quizId).update({
        'status': 'published',
        'updatedAt': DateTime.now(),
      });

      return true;
    } catch (e) {
      debugPrint('Error approving quiz: $e');
      return false;
    }
  }

  /// Delete a quiz (admin only)
  Future<bool> deleteQuiz(String quizId) async {
    try {
      // Delete all related results first
      final resultsSnapshot = await _firestore
          .collection('quizResults')
          .where('quizId', isEqualTo: quizId)
          .get();

      for (final resultDoc in resultsSnapshot.docs) {
        await resultDoc.reference.delete();
      }

      // Delete quiz structure
      final questionsSnap = await _firestore
          .collection('quizzes')
          .doc(quizId)
          .collection('questions')
          .get();

      for (final questionDoc in questionsSnap.docs) {
        final optionsSnap = await questionDoc.reference
            .collection('options')
            .get();
        for (final optionDoc in optionsSnap.docs) {
          await optionDoc.reference.delete();
        }
        await questionDoc.reference.delete();
      }

      await _firestore.collection('quizzes').doc(quizId).delete();

      return true;
    } catch (e) {
      debugPrint('Error deleting quiz: $e');
      return false;
    }
  }
}

class AdminAssignmentManagementController {
  AdminAssignmentManagementController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Fetch all assignments
  Future<List<AssignmentModel>> fetchAllAssignments({String? courseId}) async {
    try {
      final collection = _firestore.collection('assignments');
      final query = courseId != null
          ? collection.where('courseId', isEqualTo: courseId)
          : collection;

      final snapshot = await query.orderBy('dueDate', descending: true).get();
      return snapshot.docs.map(AssignmentModel.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching assignments: $e');
      return [];
    }
  }

  /// Get submission statistics
  Future<Map<String, dynamic>> getAssignmentStats(String assignmentId) async {
    try {
      final submissionsSnapshot = await _firestore
          .collection('assignmentSubmissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      final submissions = submissionsSnapshot.docs
          .map(AssignmentSubmissionModel.fromFirestore)
          .toList();

      final gradedSubmissions = submissions.where((s) => s.isGraded).toList();
      final averageGrade = gradedSubmissions.isEmpty
          ? 0.0
          : gradedSubmissions.fold<double>(
                  0,
                  (acc, s) => acc + (s.grade ?? 0),
                ) /
                gradedSubmissions.length;

      return {
        'totalSubmissions': submissions.length,
        'gradedSubmissions': gradedSubmissions.length,
        'pendingGrade': submissions.length - gradedSubmissions.length,
        'averageGrade': averageGrade,
      };
    } catch (e) {
      debugPrint('Error getting assignment stats: $e');
      return {};
    }
  }

  /// Delete assignment (and all submissions)
  Future<bool> deleteAssignment(String assignmentId) async {
    try {
      // Delete all submissions
      final submissionsSnapshot = await _firestore
          .collection('assignmentSubmissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      for (final submissionDoc in submissionsSnapshot.docs) {
        await submissionDoc.reference.delete();
      }

      // Delete assignment
      await _firestore.collection('assignments').doc(assignmentId).delete();

      return true;
    } catch (e) {
      debugPrint('Error deleting assignment: $e');
      return false;
    }
  }

  /// Get all enrollments for analytics
  Future<List<Map<String, dynamic>>> fetchAllEnrollments({
    String? courseId,
  }) async {
    try {
      final collection = _firestore.collection('enrollments');
      final query = courseId != null
          ? collection.where('courseId', isEqualTo: courseId)
          : collection;

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      debugPrint('Error fetching enrollments: $e');
      return [];
    }
  }
}
