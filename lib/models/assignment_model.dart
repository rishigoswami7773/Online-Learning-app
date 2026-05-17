import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  const AssignmentModel({
    required this.id,
    required this.courseId,
    required this.moduleId,
    required this.title,
    required this.dueDate,
    this.description = '',
    this.maxScore = 100,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String courseId;
  final String moduleId;
  final String title;
  final DateTime dueDate;
  final String description;
  final int maxScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOverdue => DateTime.now().isAfter(dueDate);

  factory AssignmentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return AssignmentModel.fromMap(data, fallbackId: doc.id);
  }

  factory AssignmentModel.fromMap(
    Map<String, dynamic> data, {
    String fallbackId = '',
  }) {
    return AssignmentModel(
      id: (data['id'] ?? fallbackId).toString(),
      courseId: (data['courseId'] ?? '').toString(),
      moduleId: (data['moduleId'] ?? '').toString(),
      title: (data['title'] ?? 'Untitled Assignment').toString(),
      dueDate:
          _safeDate(data['dueDate']) ??
          DateTime.now().add(const Duration(days: 7)),
      description: (data['description'] ?? '').toString(),
      maxScore: (data['maxScore'] ?? 100) as int,
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
      'dueDate': dueDate,
      'description': description,
      'maxScore': maxScore,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  AssignmentModel copyWith({
    String? id,
    String? courseId,
    String? moduleId,
    String? title,
    DateTime? dueDate,
    String? description,
    int? maxScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      maxScore: maxScore ?? this.maxScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AssignmentSubmissionModel {
  const AssignmentSubmissionModel({
    required this.id,
    required this.userId,
    required this.assignmentId,
    required this.courseId,
    required this.moduleId,
    required this.fileUrl,
    required this.submittedAt,
    this.grade,
    this.feedback = '',
    this.gradeDate,
  });

  final String id;
  final String userId;
  final String assignmentId;
  final String courseId;
  final String moduleId;
  final String fileUrl;
  final DateTime submittedAt;
  final double? grade; // 0-100
  final String feedback;
  final DateTime? gradeDate;

  bool get isGraded => grade != null;

  factory AssignmentSubmissionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return AssignmentSubmissionModel.fromMap(data, fallbackId: doc.id);
  }

  factory AssignmentSubmissionModel.fromMap(
    Map<String, dynamic> data, {
    String fallbackId = '',
  }) {
    return AssignmentSubmissionModel(
      id: (data['id'] ?? fallbackId).toString(),
      userId: (data['userId'] ?? '').toString(),
      assignmentId: (data['assignmentId'] ?? '').toString(),
      courseId: (data['courseId'] ?? '').toString(),
      moduleId: (data['moduleId'] ?? '').toString(),
      fileUrl: (data['fileUrl'] ?? '').toString(),
      submittedAt: _safeDate(data['submittedAt']) ?? DateTime.now(),
      grade: data['grade'] != null
          ? _safeDouble(data['grade'], fallback: 0.0)
          : null,
      feedback: (data['feedback'] ?? '').toString(),
      gradeDate: _safeDate(data['gradeDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'assignmentId': assignmentId,
      'courseId': courseId,
      'moduleId': moduleId,
      'fileUrl': fileUrl,
      'submittedAt': submittedAt,
      'grade': grade,
      'feedback': feedback,
      'gradeDate': gradeDate,
    };
  }

  AssignmentSubmissionModel copyWith({
    String? id,
    String? userId,
    String? assignmentId,
    String? courseId,
    String? moduleId,
    String? fileUrl,
    DateTime? submittedAt,
    double? grade,
    String? feedback,
    DateTime? gradeDate,
  }) {
    return AssignmentSubmissionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assignmentId: assignmentId ?? this.assignmentId,
      courseId: courseId ?? this.courseId,
      moduleId: moduleId ?? this.moduleId,
      fileUrl: fileUrl ?? this.fileUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      grade: grade ?? this.grade,
      feedback: feedback ?? this.feedback,
      gradeDate: gradeDate ?? this.gradeDate,
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
