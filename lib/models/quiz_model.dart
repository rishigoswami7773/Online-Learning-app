import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  const QuizModel({
    required this.id,
    required this.courseId,
    required this.moduleId,
    required this.title,
    required this.passingScore,
    this.description = '',
    this.maxAttempts = 3,
    this.timeLimit = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String courseId;
  final String moduleId;
  final String title;
  final double passingScore; // percentage (0-100)
  final String description;
  final int maxAttempts;
  final int timeLimit; // in minutes, 0 = no limit
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory QuizModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return QuizModel.fromMap(data, fallbackId: doc.id);
  }

  factory QuizModel.fromMap(
    Map<String, dynamic> data, {
    String fallbackId = '',
  }) {
    return QuizModel(
      id: (data['id'] ?? fallbackId).toString(),
      courseId: (data['courseId'] ?? '').toString(),
      moduleId: (data['moduleId'] ?? '').toString(),
      title: (data['title'] ?? 'Untitled Quiz').toString(),
      passingScore: _safeDouble(data['passingScore'], fallback: 60.0),
      description: (data['description'] ?? '').toString(),
      maxAttempts: (data['maxAttempts'] ?? 3) as int,
      timeLimit: (data['timeLimit'] ?? 0) as int,
      createdAt: _safeDate(data['createdAt']),
      updatedAt: _safeDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'moduleId': moduleId,
      'title': title,
      'passingScore': passingScore,
      'description': description,
      'maxAttempts': maxAttempts,
      'timeLimit': timeLimit,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  QuizModel copyWith({
    String? id,
    String? courseId,
    String? moduleId,
    String? title,
    double? passingScore,
    String? description,
    int? maxAttempts,
    int? timeLimit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuizModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      passingScore: passingScore ?? this.passingScore,
      description: description ?? this.description,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      timeLimit: timeLimit ?? this.timeLimit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class QuestionModel {
  const QuestionModel({
    required this.id,
    required this.quizId,
    required this.text,
    required this.order,
    this.explanation = '',
  });

  final String id;
  final String quizId;
  final String text;
  final int order;
  final String explanation;

  factory QuestionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return QuestionModel.fromMap(data, fallbackId: doc.id);
  }

  factory QuestionModel.fromMap(
    Map<String, dynamic> data, {
    String fallbackId = '',
  }) {
    return QuestionModel(
      id: (data['id'] ?? fallbackId).toString(),
      quizId: (data['quizId'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      order: (data['order'] ?? 0) as int,
      explanation: (data['explanation'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'text': text,
      'order': order,
      'explanation': explanation,
    };
  }

  QuestionModel copyWith({
    String? id,
    String? quizId,
    String? text,
    int? order,
    String? explanation,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      text: text ?? this.text,
      order: order ?? this.order,
      explanation: explanation ?? this.explanation,
    );
  }
}

class OptionModel {
  const OptionModel({
    required this.id,
    required this.questionId,
    required this.text,
    required this.isCorrect,
  });

  final String id;
  final String questionId;
  final String text;
  final bool isCorrect;

  factory OptionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return OptionModel.fromMap(data, fallbackId: doc.id);
  }

  factory OptionModel.fromMap(
    Map<String, dynamic> data, {
    String fallbackId = '',
  }) {
    return OptionModel(
      id: (data['id'] ?? fallbackId).toString(),
      questionId: (data['questionId'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      isCorrect: (data['isCorrect'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionId': questionId,
      'text': text,
      'isCorrect': isCorrect,
    };
  }

  OptionModel copyWith({
    String? id,
    String? questionId,
    String? text,
    bool? isCorrect,
  }) {
    return OptionModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
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
