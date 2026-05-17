import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/quiz_model.dart';
import '../../models/quiz_result_model.dart';

class StudentQuizController {
  StudentQuizController({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Fetch quiz for a specific module
  Future<QuizModel?> fetchQuiz(String courseId, String moduleId) async {
    try {
      final snapshot = await _firestore
          .collection('quizzes')
          .where('courseId', isEqualTo: courseId)
          .where('moduleId', isEqualTo: moduleId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return QuizModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('Error fetching quiz: $e');
      return null;
    }
  }

  /// Fetch all questions for a quiz
  Future<List<QuestionModel>> fetchQuizQuestions(String quizId) async {
    try {
      final snapshot = await _firestore
          .collection('quizzes')
          .doc(quizId)
          .collection('questions')
          .orderBy('order')
          .get();

      return snapshot.docs.map(QuestionModel.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching quiz questions: $e');
      return [];
    }
  }

  /// Fetch all options for a question
  Future<List<OptionModel>> fetchQuestionOptions(
    String quizId,
    String questionId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('quizzes')
          .doc(quizId)
          .collection('questions')
          .doc(questionId)
          .collection('options')
          .get();

      return snapshot.docs.map(OptionModel.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching question options: $e');
      return [];
    }
  }

  /// Submit quiz attempt and save result
  Future<QuizResultModel?> submitQuizAttempt({
    required String quizId,
    required String courseId,
    required String moduleId,
    required Map<String, String> answers,
    required double calculatedScore,
    required bool passed,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('No authenticated user');
        return null;
      }

      // Fetch quiz to get passing score
      final quiz = await _firestore.collection('quizzes').doc(quizId).get();
      if (!quiz.exists) {
        debugPrint('Quiz not found');
        return null;
      }

      // Create result document
      final resultDocId =
          '${userId}_${quizId}_${DateTime.now().millisecondsSinceEpoch}';
      final quizResult = QuizResultModel(
        id: resultDocId,
        userId: userId,
        quizId: quizId,
        courseId: courseId,
        moduleId: moduleId,
        score: calculatedScore,
        passed: passed,
        attemptedAt: DateTime.now(),
        answers: answers,
        totalQuestions: answers.length,
        correctAnswers: 0, // Will be calculated
      );

      await _firestore
          .collection('quizResults')
          .doc(resultDocId)
          .set(quizResult.toMap());

      return quizResult;
    } catch (e) {
      debugPrint('Error submitting quiz attempt: $e');
      return null;
    }
  }

  /// Get all quiz results for a student
  Future<List<QuizResultModel>> fetchStudentQuizResults({
    String? courseId,
    String? moduleId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      var query = _firestore
          .collection('quizResults')
          .where('userId', isEqualTo: userId);

      if (courseId != null) {
        query = query.where('courseId', isEqualTo: courseId);
      }

      if (moduleId != null) {
        query = query.where('moduleId', isEqualTo: moduleId);
      }

      final snapshot = await query
          .orderBy('attemptedAt', descending: true)
          .get();
      return snapshot.docs.map(QuizResultModel.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching quiz results: $e');
      return [];
    }
  }

  /// Get best quiz result for a specific quiz
  Future<QuizResultModel?> fetchBestQuizResult(String quizId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final snapshot = await _firestore
          .collection('quizResults')
          .where('userId', isEqualTo: userId)
          .where('quizId', isEqualTo: quizId)
          .orderBy('score', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return QuizResultModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('Error fetching best quiz result: $e');
      return null;
    }
  }

  /// Calculate score from answers (requires fetching correct answers)
  Future<double> calculateScore(
    String quizId,
    Map<String, String> answers,
  ) async {
    try {
      final questions = await fetchQuizQuestions(quizId);
      if (questions.isEmpty) return 0.0;

      int correctCount = 0;

      for (final question in questions) {
        final selectedOptionId = answers[question.id];
        if (selectedOptionId == null) continue;

        // Fetch the selected option to check if it's correct
        final optionSnapshot = await _firestore
            .collection('quizzes')
            .doc(quizId)
            .collection('questions')
            .doc(question.id)
            .collection('options')
            .doc(selectedOptionId)
            .get();

        if (optionSnapshot.exists) {
          final isCorrect = optionSnapshot.get('isCorrect') as bool? ?? false;
          if (isCorrect) correctCount++;
        }
      }

      return (correctCount / questions.length * 100).clamp(0.0, 100.0);
    } catch (e) {
      debugPrint('Error calculating score: $e');
      return 0.0;
    }
  }
}
