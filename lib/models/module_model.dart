import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleModel {
  const ModuleModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.order,
    this.description = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String courseId;
  final String title;
  final int order;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ModuleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return ModuleModel.fromMap(data, fallbackId: doc.id);
  }

  factory ModuleModel.fromMap(
    Map<String, dynamic> data, {
    String fallbackId = '',
  }) {
    return ModuleModel(
      id: (data['id'] ?? fallbackId).toString(),
      courseId: (data['courseId'] ?? '').toString(),
      title: (data['title'] ?? 'Untitled Module').toString(),
      order: (data['order'] ?? 0) as int,
      description: (data['description'] ?? '').toString(),
      createdAt: _safeDate(data['createdAt']),
      updatedAt: _safeDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'order': order,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ModuleModel copyWith({
    String? id,
    String? courseId,
    String? title,
    int? order,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModuleModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      order: order ?? this.order,
      description: description ?? this.description,
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
