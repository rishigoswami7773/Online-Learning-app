import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Student quiz-taking screen
/// Displays quiz questions one at a time with multiple choice options
/// Student submits answers to calculate score
class StudentQuizScreen extends StatefulWidget {
  const StudentQuizScreen({
    super.key,
    this.quizId = '',
    this.courseId = '',
    this.moduleId = '',
  });

  final String quizId;
  final String courseId;
  final String moduleId;

  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
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
                'Quiz Feature',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Quiz ID: ${widget.quizId}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Course ID: ${widget.courseId}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Module ID: ${widget.moduleId}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              const Text(
                'Quiz taking interface coming soon',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
