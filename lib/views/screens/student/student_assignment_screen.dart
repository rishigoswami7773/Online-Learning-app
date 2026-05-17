import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Student assignment submission screen
/// Displays assignment details and allows student to upload file
class StudentAssignmentScreen extends StatefulWidget {
  const StudentAssignmentScreen({
    super.key,
    this.assignmentId = '',
    this.courseId = '',
    this.moduleId = '',
  });

  final String assignmentId;
  final String courseId;
  final String moduleId;

  @override
  State<StudentAssignmentScreen> createState() =>
      _StudentAssignmentScreenState();
}

class _StudentAssignmentScreenState extends State<StudentAssignmentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment'),
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
                'Assignment Submission',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Assignment ID: ${widget.assignmentId}',
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
                'Assignment submission interface coming soon',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
