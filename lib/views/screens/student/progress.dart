import 'package:flutter/material.dart';

class CourseProgressPage extends StatelessWidget {
  const CourseProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Progress')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: const [
            Text('Progress details (demo)'),
          ],
        ),
      ),
    );
  }
}
