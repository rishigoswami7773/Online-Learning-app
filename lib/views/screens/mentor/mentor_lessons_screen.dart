import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mentor lesson and module management screen
class MentorLessonsScreen extends StatefulWidget {
  const MentorLessonsScreen({super.key, this.courseId = ''});

  final String courseId;

  @override
  State<MentorLessonsScreen> createState() => _MentorLessonsScreenState();
}

class _MentorLessonsScreenState extends State<MentorLessonsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons & Modules'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Lessons & Modules',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Course ID: ${widget.courseId}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              const Text(
                'Lesson and module management coming soon',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
