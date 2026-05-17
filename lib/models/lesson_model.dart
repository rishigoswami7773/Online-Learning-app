import 'package:cloud_firestore/cloud_firestore.dart';

class LessonModel {
  const LessonModel({
    required this.id,
    required this.moduleId,
    required this.courseId,
    required this.title,
    required this.type,
    required this.contentUrl,
    required this.order,
    this.description = '',
    this.duration = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String moduleId;
  final String courseId;
  final String title;
  final String type; // 'video', 'text', 'pdf'
  final String contentUrl;
  final int order;
  final String description;
  final int duration; // in minutes
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LessonModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return LessonModel.fromMap(data, fallbackId: doc.id);
  }

  factory LessonModel.fromMap(
    Map<String, dynamic> data, {
    String fallbackId = '',
  }) {
    return LessonModel(
      id: (data['id'] ?? fallbackId).toString(),
      moduleId: (data['moduleId'] ?? '').toString(),
      courseId: (data['courseId'] ?? '').toString(),
      title: (data['title'] ?? 'Untitled Lesson').toString(),
      type: (data['type'] ?? 'video').toString(),
      contentUrl: (data['contentUrl'] ?? '').toString(),
      order: (data['order'] ?? 0) as int,
      description: (data['description'] ?? '').toString(),
      duration: (data['duration'] ?? 0) as int,
      createdAt: _safeDate(data['createdAt']),
      updatedAt: _safeDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'moduleId': moduleId,
      'courseId': courseId,
      'title': title,
      'type': type,
      'contentUrl': contentUrl,
      'order': order,
      'description': description,
      'duration': duration,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  LessonModel copyWith({
    String? id,
    String? moduleId,
    String? courseId,
    String? title,
    String? type,
    String? contentUrl,
    int? order,
    String? description,
    int? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonModel(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      type: type ?? this.type,
      contentUrl: contentUrl ?? this.contentUrl,
      order: order ?? this.order,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _safeDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  return null;
}
