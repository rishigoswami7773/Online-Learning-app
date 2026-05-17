import 'package:flutter/foundation.dart';

class Course {
  String id;
  String title;
  String instructor;
  double rating;
  String description;
  String category;
  double price;
  bool published;
  DateTime createdAt;

  Course({
    required this.id,
    required this.title,
    required this.instructor,
    required this.rating,
    required this.description,
    required this.category,
    required this.price,
    this.published = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'instructor': instructor,
        'rating': rating,
        'description': description,
        'category': category,
        'price': price,
        'published': published,
        'createdAt': createdAt.toIso8601String(),
      };

  static Course fromMap(Map<String, dynamic> m) => Course(
        id: m['id'] as String,
        title: m['title'] as String,
        instructor: m['instructor'] as String,
        rating: (m['rating'] as num).toDouble(),
        description: m['description'] as String,
        category: m['category'] as String,
        price: (m['price'] as num).toDouble(),
        published: m['published'] as bool? ?? false,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class CourseRepository {
  CourseRepository._internal() {
    // seed with demo content
    _courses.value = [
      Course(id: 'c1', title: 'Flutter for Beginners', instructor: 'Celine', rating: 4.5, description: 'Learn basics of Flutter and build real apps.', category: 'Development', price: 0.0, published: true),
      Course(id: 'c2', title: 'Advanced Dart', instructor: 'Admin', rating: 4.2, description: 'Deep dive into Dart language features.', category: 'Development', price: 9.99, published: true),
      Course(id: 'c3', title: 'UI/UX for Mobile', instructor: 'Alice', rating: 4.7, description: 'Design beautiful mobile user interfaces.', category: 'Design', price: 14.99, published: false),
    ];
  }

  static final CourseRepository instance = CourseRepository._internal();

  final ValueNotifier<List<Course>> _courses = ValueNotifier<List<Course>>([]);

  ValueListenable<List<Course>> get coursesListenable => _courses;

  List<Course> get courses => List.unmodifiable(_courses.value);

  void addCourse(Course c) {
    final next = List<Course>.from(_courses.value);
    next.insert(0, c);
    _courses.value = next;
  }

  void updateCourse(String id, Course updated) {
    final idx = _courses.value.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    final next = List<Course>.from(_courses.value);
    next[idx] = updated;
    _courses.value = next;
  }

  void removeCourse(String id) {
    final next = List<Course>.from(_courses.value)..removeWhere((c) => c.id == id);
    _courses.value = next;
  }

  void togglePublish(String id) {
    final idx = _courses.value.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    final c = _courses.value[idx];
    updateCourse(id, Course(
      id: c.id,
      title: c.title,
      instructor: c.instructor,
      rating: c.rating,
      description: c.description,
      category: c.category,
      price: c.price,
      published: !c.published,
      createdAt: c.createdAt,
    ));
  }
}
