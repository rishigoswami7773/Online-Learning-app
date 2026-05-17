import 'package:cloud_firestore/cloud_firestore.dart';

class QuizResultModel {
  const QuizResultModel({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.courseId,
    required this.moduleId,
    required this.score,
    required this.passed,
    required this.attemptedAt,
    this.answers = const {},
    this.totalQuestions = 0,
    this.correctAnswers = 0,
  });

  final String id;
  final String userId;
  final String quizId;
  final String courseId;
  final String moduleId;
  final double score; // percentage (0-100)
  final bool passed;
  final DateTime attemptedAt;
  final Map<String, String> answers; // questionId -> selectedOptionId
  final int totalQuestions;
  final int correctAnswers;

  factory QuizResultModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return QuizResultModel.fromMap(data, fallbackId: doc.id);
  }

  factory QuizResultModel.fromMap(
    Map<String, dynamic> data, {
    String fallbackId = '',
  }) {
    return QuizResultModel(
      id: (data['id'] ?? fallbackId).toString(),
      userId: (data['userId'] ?? '').toString(),
      quizId: (data['quizId'] ?? '').toString(),
      courseId: (data['courseId'] ?? '').toString(),
      moduleId: (data['moduleId'] ?? '').toString(),
      score: _safeDouble(data['score'], fallback: 0.0),
      passed: (data['passed'] ?? false) as bool,
      attemptedAt: _safeDate(data['attemptedAt']) ?? DateTime.now(),
      answers: Map<String, String>.from(
        (data['answers'] as Map<dynamic, dynamic>?) ?? {},
      ),
      totalQuestions: (data['totalQuestions'] ?? 0) as int,
      correctAnswers: (data['correctAnswers'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'quizId': quizId,
      'courseId': courseId,
      'moduleId': moduleId,
      'score': score,
      'passed': passed,
      'attemptedAt': attemptedAt,
      'answers': answers,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
    };
  }

  QuizResultModel copyWith({
    String? id,
    String? userId,
    String? quizId,
    String? courseId,
    String? moduleId,
    double? score,
    bool? passed,
    DateTime? attemptedAt,
    Map<String, String>? answers,
    int? totalQuestions,
    int? correctAnswers,
  }) {
    return QuizResultModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      quizId: quizId ?? this.quizId,
      courseId: courseId ?? this.courseId,
      moduleId: moduleId ?? this.moduleId,
      score: score ?? this.score,
      passed: passed ?? this.passed,
      attemptedAt: attemptedAt ?? this.attemptedAt,
      answers: answers ?? this.answers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
    );
  }
}

DateTime? _safeDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  return null;
}

double _safeDouble(dynamic value, {required double fallback}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}
