import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentTask {
  final String id;
  final String userId;
  final String courseId;
  final String title;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime createdAt;

  StudentTask({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.isCompleted,
    required this.createdAt,
  });

  factory StudentTask.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentTask(
      id: doc.id,
      userId: data['userId'] ?? '',
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'courseId': courseId,
    'title': title,
    'description': description,
    'dueDate': Timestamp.fromDate(dueDate),
    'isCompleted': isCompleted,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class TasksController {
  TasksController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Get all tasks for current user
  Stream<List<StudentTask>> getTasks({bool pendingOnly = false}) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    Query query = _firestore
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .orderBy('dueDate', descending: false);

    if (pendingOnly) {
      query = query.where('isCompleted', isEqualTo: false);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => StudentTask.fromFirestore(doc)).toList(),
    );
  }

  /// Get tasks for a specific course
  Stream<List<StudentTask>> getCourseTasksFor(String courseId) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .where('courseId', isEqualTo: courseId)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudentTask.fromFirestore(doc))
              .toList(),
        );
  }

  /// Mark task as completed
  Future<void> markTaskComplete(String taskId, bool isCompleted) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'isCompleted': isCompleted,
    });
  }

  /// Create a new task
  Future<void> createTask({
    required String courseId,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    final task = StudentTask(
      id: '',
      userId: uid,
      courseId: courseId,
      title: title,
      description: description,
      dueDate: dueDate,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('tasks').add(task.toFirestore());
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  /// Get task count for dashboard
  Future<int> getPendingTaskCount() async {
    final uid = currentUserId;
    if (uid == null) return 0;

    final snapshot = await _firestore
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .where('isCompleted', isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}
