import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/theme_helper.dart';

class StudentCourseDetailPageNew extends StatefulWidget {
  const StudentCourseDetailPageNew({super.key});

  @override
  State<StudentCourseDetailPageNew> createState() =>
      _StudentCourseDetailPageNewState();
}

class _StudentCourseDetailPageNewState
    extends State<StudentCourseDetailPageNew> {
  late Future<Map<String, dynamic>> _dataFuture;
  bool _isEnrolling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dataFuture = _loadData();
    });
  }

  Future<Map<String, dynamic>> _loadData() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final courseId = args?['courseId']?.toString();
    if (courseId == null || courseId.isEmpty) {
      throw Exception('Course ID not provided');
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    final courseSnap = await FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .get();
    if (!courseSnap.exists) throw Exception('Course not found');

    final enrollmentSnap = await FirebaseFirestore.instance
        .collection('enrollments')
        .where('studentId', isEqualTo: uid)
        .where('courseId', isEqualTo: courseId)
        .limit(1)
        .get();

    final course = {...courseSnap.data() ?? {}, 'id': courseSnap.id};
    final enrollment = enrollmentSnap.docs.isEmpty
        ? null
        : enrollmentSnap.docs.first.data();

    return {
      'course': course,
      'enrollment': enrollment,
      'courseId': courseId,
      'uid': uid,
    };
  }

  Future<void> _enrollCourse(
    String courseId,
    String uid,
    Map<String, dynamic> course,
  ) async {
    if (_isEnrolling) return;
    setState(() => _isEnrolling = true);

    try {
      await FirebaseFirestore.instance.collection('enrollments').add({
        'studentId': uid,
        'courseId': courseId,
        'courseTitle': course['title'] ?? 'Untitled',
        'mentorId': course['mentorId'] ?? '',
        'status': 'active',
        'progress': 0.0,
        'progressPercent': 0.0,
        'lessonsCompleted': 0,
        'completedLessons': 0,
        'totalLessons': course['totalLessons'] ?? 0,
        'enrolledAt': FieldValue.serverTimestamp(),
        'lastAccessedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enrolled successfully!')));
        setState(() {
          _dataFuture = _loadData();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Enrollment failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isEnrolling = false);
      } else {
        _isEnrolling = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Course Detail'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No course data'));
          }

          final data = snapshot.data!;
          final course = data['course'] as Map<String, dynamic>;
          final enrollment = data['enrollment'] as Map<String, dynamic>?;
          final courseId = data['courseId'] as String;
          final uid = data['uid'] as String;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner
                if ((course['thumbnailUrl'] ?? '').toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      course['thumbnailUrl'],
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 180,
                        color: context.borderColor,
                        child: const Center(child: Icon(Icons.menu_book)),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Icon(Icons.menu_book, size: 52)),
                  ),
                const SizedBox(height: 16),

                // Title
                Text(
                  course['title'] ?? 'Untitled Course',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Chips
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text(course['category'] ?? 'General')),
                    Chip(label: Text('${course['durationHours'] ?? 0} hours')),
                    Chip(label: Text('${course['totalLessons'] ?? 0} lessons')),
                    Chip(
                      label: Text(
                        'Ã¢Â­Â ${(course['rating'] ?? 0).toStringAsFixed(1)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Instructor
                Text(
                  'Instructor: ${course['instructor'] ?? 'Instructor'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  course['description'] ?? 'No description available.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),

                // Progress (if enrolled)
                if (enrollment != null) ...[
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
                          LinearProgressIndicator(
                            value: ((enrollment['progressPercent'] ?? 0) / 100)
                                .clamp(0.0, 1.0),
                            minHeight: 6,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${enrollment['lessonsCompleted'] ?? 0}/${enrollment['totalLessons'] ?? 0} lessons completed',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Syllabus
                if (course['syllabus'] != null &&
                    (course['syllabus'] as List).isNotEmpty)
                  Card(
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: const Text('Course Content'),
                        children: [
                          for (final lesson in (course['syllabus'] as List))
                            ListTile(
                              leading: const Icon(Icons.play_circle_outline),
                              title: Text(lesson.toString()),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Buttons
                SizedBox(
                  width: double.infinity,
                  child: enrollment == null
                      ? FilledButton.icon(
                          onPressed: _isEnrolling
                              ? null
                              : () => _enrollCourse(courseId, uid, course),
                          icon: const Icon(Icons.school),
                          label: _isEnrolling
                              ? const Text('Enrolling...')
                              : const Text('Enroll Now'),
                        )
                      : FilledButton.icon(
                          onPressed: () {
                            final url = course['videoUrl']?.toString() ?? '';
                            if (url.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Video not available yet.'),
                                ),
                              );
                              return;
                            }
                            context.push(
                              AppRoutes.studentVideo,
                              extra: {
                                'title': course['title'],
                                'videoUrl': url,
                                'courseId': courseId,
                              },
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Resume Learning'),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
