import 'package:flutter/material.dart';

import '../../../models/student/course_model.dart';
import '../../../models/student/enrollment_model.dart';

class StudentCourseDetailPage extends StatelessWidget {
  const StudentCourseDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        <String, dynamic>{};

    final courseMap = args['course'] as Map<String, dynamic>?;
    final enrollmentMap = args['enrollment'] as Map<String, dynamic>?;

    final course = courseMap != null
        ? CourseModel.fromMap(courseMap)
        : CourseModel.dummyCourses.first;
    final enrollment = enrollmentMap == null
        ? null
        : EnrollmentModel.fromMap(enrollmentMap);

    final progress = enrollment?.progress ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Course Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BannerImage(url: course.thumbnailUrl),
            const SizedBox(height: 16),
            Text(
              course.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(course.category)),
                Chip(label: Text('${course.durationHours} hours')),
                Chip(label: Text('${course.totalLessons} lessons')),
                Chip(label: Text('⭐ ${course.rating.toStringAsFixed(1)}')),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Instructor: ${course.instructor}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              course.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            if (enrollment != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Progress',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 8),
                      Text(
                        '${enrollment.progressPercent}% completed • ${enrollment.completedLessons}/${enrollment.totalLessons} lessons',
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final text = enrollment == null
                      ? 'Enroll action is coming soon.'
                      : 'Resuming your lesson...';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(text)));
                },
                icon: Icon(
                  enrollment == null ? Icons.school : Icons.play_arrow,
                ),
                label: Text(enrollment == null ? 'Enroll' : 'Resume Learning'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Icon(Icons.menu_book, size: 52)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return Container(
            height: 180,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Center(child: Icon(Icons.menu_book, size: 52)),
          );
        },
      ),
    );
  }
}
