import 'package:flutter/material.dart';

class CourseVideoPlayerPage extends StatelessWidget {
  const CourseVideoPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final title = args?['title'] ?? 'Course video';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Icon(Icons.play_circle, size: 120, color: Colors.grey)),
    );
  }
}
