import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentModel {
  const EnrollmentModel({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.courseTitle,
    required this.courseCategory,
    required this.courseThumbnail,
    required this.progress,
    required this.totalLessons,
    required this.completedLessons,
    required this.lastViewedAt,
    required this.enrolledAt,
  });

  final String id;
  final String userId;
  final String courseId;
  final String courseTitle;
  final String courseCategory;
  final String courseThumbnail;
  final double progress;
  final int totalLessons;
  final int completedLessons;
  final DateTime? lastViewedAt;
  final DateTime? enrolledAt;

  int get progressPercent => (progress * 100).clamp(0, 100).toInt();

  bool get isCompleted => progress >= 1.0 || completedLessons >= totalLessons;

  DateTime? get completedDate =>
      isCompleted ? lastViewedAt ?? enrolledAt : null;

  factory EnrollmentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return EnrollmentModel.fromMap(data, fallbackId: doc.id);
  }

  factory EnrollmentModel.fromMap(
    Map<String, dynamic> data, {
    String fallbackId = '',
  }) {
    return EnrollmentModel(
      id: (data['id'] ?? fallbackId).toString(),
      userId: (data['userId'] ?? '').toString(),
      courseId: (data['courseId'] ?? '').toString(),
      courseTitle: (data['courseTitle'] ?? 'Untitled Course').toString(),
      courseCategory: (data['courseCategory'] ?? 'General').toString(),
      courseThumbnail: (data['courseThumbnail'] ?? '').toString(),
      progress: _safeDouble(data['progress'], fallback: 0.0),
      totalLessons: _safeInt(data['totalLessons'], fallback: 20),
      completedLessons: _safeInt(data['completedLessons'], fallback: 0),
      lastViewedAt: _safeDate(data['lastViewedAt']),
      enrolledAt: _safeDate(data['enrolledAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'courseCategory': courseCategory,
      'courseThumbnail': courseThumbnail,
      'progress': progress,
      'totalLessons': totalLessons,
      'completedLessons': completedLessons,
      'lastViewedAt': lastViewedAt?.toIso8601String(),
      'enrolledAt': enrolledAt?.toIso8601String(),
    };
  }

  static int _safeInt(Object? value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _safeDouble(Object? value, {required double fallback}) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime? _safeDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
