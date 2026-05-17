import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/quiz_model.dart';
import '../../models/quiz_result_model.dart';
import '../../models/assignment_model.dart';

class MentorQuizController {
  MentorQuizController({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Create a new quiz for a module
  Future<QuizModel?> createQuiz({
    required String courseId,
    required String moduleId,
    required String title,
    required double passingScore,
    String description = '',
    int maxAttempts = 3,
    int timeLimit = 0,
  }) async {
    try {
      final mentorId = _auth.currentUser?.uid;
      if (mentorId == null) return null;

      // Verify course belongs to mentor
      final courseDoc = await _firestore
          .collection('courses')
          .doc(courseId)
          .get();
      if (!courseDoc.exists || courseDoc.get('mentorId') != mentorId) {
        debugPrint('Mentor not authorized for this course');
        return null;
      }

      final quizId =
          '${courseId}_${moduleId}_${DateTime.now().millisecondsSinceEpoch}';
      final quiz = QuizModel(
        id: quizId,
        courseId: courseId,
        moduleId: moduleId,
        title: title,
        passingScore: passingScore,
        description: description,
        maxAttempts: maxAttempts,
        timeLimit: timeLimit,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('quizzes').doc(quizId).set(quiz.toMap());

      return quiz;
    } catch (e) {
      debugPrint('Error creating quiz: $e');
      return null;
    }
  }

  /// Add question to quiz
  Future<QuestionModel?> addQuestion({
    required String quizId,
    required String text,
    required int order,
    String explanation = '',
  }) async {
    try {
      final questionId = _firestore.collection('quizzes').doc().id;
      final question = QuestionModel(
        id: questionId,
        quizId: quizId,
        text: text,
        order: order,
        explanation: explanation,
      );

      await _firestore
          .collection('quizzes')
          .doc(quizId)
          .collection('questions')
          .doc(questionId)
          .set(question.toMap());

      return question;
    } catch (e) {
      debugPrint('Error adding question: $e');
      return null;
    }
  }

  /// Add option to question
  Future<OptionModel?> addOption({
    required String quizId,
    required String questionId,
    required String text,
    required bool isCorrect,
  }) async {
    try {
      final optionId = _firestore.collection('quizzes').doc().id;
      final option = OptionModel(
        id: optionId,
        questionId: questionId,
        text: text,
        isCorrect: isCorrect,
      );

      await _firestore
          .collection('quizzes')
          .doc(quizId)
          .collection('questions')
          .doc(questionId)
          .collection('options')
          .doc(optionId)
          .set(option.toMap());

      return option;
    } catch (e) {
      debugPrint('Error adding option: $e');
      return null;
    }
  }

  /// Fetch all quizzes for a course
  Future<List<QuizModel>> fetchCourseQuizzes(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('quizzes')
          .where('courseId', isEqualTo: courseId)
          .get();

      return snapshot.docs.map(QuizModel.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching quizzes: $e');
      return [];
    }
  }

  /// Fetch quiz results for a specific quiz
  Future<List<QuizResultModel>> fetchQuizResults(String quizId) async {
    try {
      final snapshot = await _firestore
          .collection('quizResults')
          .where('quizId', isEqualTo: quizId)
          .orderBy('attemptedAt', descending: true)
          .get();

      return snapshot.docs.map(QuizResultModel.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching quiz results: $e');
      return [];
    }
  }

  /// Update quiz settings
  Future<bool> updateQuiz(
    String quizId, {
    String? title,
    String? description,
    double? passingScore,
    int? maxAttempts,
    int? timeLimit,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (passingScore != null) updates['passingScore'] = passingScore;
      if (maxAttempts != null) updates['maxAttempts'] = maxAttempts;
      if (timeLimit != null) updates['timeLimit'] = timeLimit;
      updates['updatedAt'] = DateTime.now();

      await _firestore.collection('quizzes').doc(quizId).update(updates);

      return true;
    } catch (e) {
      debugPrint('Error updating quiz: $e');
      return false;
    }
  }

  /// Delete quiz (and all questions/options)
  Future<bool> deleteQuiz(String quizId) async {
    try {
      // Delete all options
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

class MentorAssignmentGradingController {
  MentorAssignmentGradingController({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Fetch all submissions for an assignment
  Future<List<AssignmentSubmissionModel>> fetchAssignmentSubmissions(
    String assignmentId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('assignmentSubmissions')
          .where('assignmentId', isEqualTo: assignmentId)
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

  /// Grade a submission
  Future<bool> gradeSubmission({
    required String submissionId,
    required double grade,
    required String feedback,
  }) async {
    try {
      await _firestore
          .collection('assignmentSubmissions')
          .doc(submissionId)
          .update({
            'grade': grade,
            'feedback': feedback,
            'gradeDate': DateTime.now(),
          });

      return true;
    } catch (e) {
      debugPrint('Error grading submission: $e');
      return false;
    }
  }

  /// Get all submissions for a course
  Future<List<AssignmentSubmissionModel>> fetchCourseSubmissions(
    String courseId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('assignmentSubmissions')
          .where('courseId', isEqualTo: courseId)
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs
          .map(AssignmentSubmissionModel.fromFirestore)
          .toList();
    } catch (e) {
      debugPrint('Error fetching course submissions: $e');
      return [];
    }
  }
}
