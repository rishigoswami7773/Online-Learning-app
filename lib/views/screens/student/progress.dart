import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import '../../../utils/animations.dart';
import '../../../utils/theme_helper.dart';

void _safeBackToStudentDashboard(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.studentDashboard);
  }
}

class CourseProgressPage extends StatelessWidget {
  const CourseProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _safeBackToStudentDashboard(context);
      },
      child: Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          backgroundColor: context.surfaceColor,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _safeBackToStudentDashboard(context),
          ),
          title: const Text('Course Progress'),
        ),
        body: uid == null
            ? const Center(child: Text('Not logged in'))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('enrollments')
                    .where('studentId', isEqualTo: uid)
                    .where('status', isEqualTo: 'active')
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 56),
                          const SizedBox(height: 12),
                          Text('Unable to load progress: ${snap.error}'),
                        ],
                      ),
                    );
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          const Text('No active enrollments'),
                          const SizedBox(height: 6),
                          const Text('Enroll in a course to see your progress here.'),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final courseTitle =
                          data['courseTitle'] ?? 'Untitled Course';
                      final courseId = data['courseId'] ?? '';
                      // progressPercent is stored as 0-100, but the bar needs 0-1.
                      // progressPercent is stored as 0-100, while progress is already 0-1.
                      final rawProgress =
                          (data['progressPercent'] as num?)?.toDouble() ??
                          (data['progress'] as num?)?.toDouble() ??
                          0.0;
                      final progress = rawProgress > 1.0
                          ? (rawProgress / 100.0).clamp(0.0, 1.0)
                          : rawProgress.clamp(0.0, 1.0);
                      final completed =
                          (data['lessonsCompleted'] as num?)?.toInt() ?? 0;
                      final total =
                          (data['totalLessons'] as num?)?.toInt() ?? 0;
                      final percent = (progress * 100).toStringAsFixed(0);

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.push(
                            AppRoutes.studentCourseDetail,
                            extra: {'courseId': courseId},
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        courseTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    AnimatedCounter(
                                      target: int.tryParse(percent) ?? 0,
                                      textStyle: const TextStyle(
                                        color: Color(0xFF0E7C86),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      '%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0E7C86),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$completed of $total lessons completed',
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress.clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: context.borderColor,
                                    valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFF0E7C86),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
