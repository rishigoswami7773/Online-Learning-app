import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import '../../models/course_repo.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  double _rating = 4.0;
  final _feedbackCtrl = TextEditingController();

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final courseMap = args ?? {};
    final course = args != null
        ? Course.fromMap(courseMap)
        : Course(
            id: 'unknown',
            title: 'Unknown',
            instructor: 'Unknown',
            rating: 0.0,
            description: '',
            category: 'General',
            price: 0.0,
          );

    // mock progress data
    final students = [
      {'name': 'Alice', 'progress': 0.8},
      {'name': 'Bob', 'progress': 0.5},
      {'name': 'Charlie', 'progress': 0.25},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.mentorCreate, arguments: course.toMap()),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                course.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Instructor: ${course.instructor}'),
                  const SizedBox(width: 12),
                  Chip(label: Text(course.category)),
                ],
              ),
              const SizedBox(height: 12),
              Text(course.description),
              const SizedBox(height: 16),

              const Text(
                'Student progress',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...students.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(s['name'] as String)),
                      SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(
                          value: s['progress'] as double,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text('Rate this course'),
              Slider(
                value: _rating,
                min: 1,
                max: 5,
                divisions: 8,
                label: _rating.toStringAsFixed(1),
                onChanged: (v) => setState(() => _rating = v),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _feedbackCtrl,
                decoration: const InputDecoration(labelText: 'Leave feedback'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Thanks (demo)'),
                    content: Text(
                      'Rating: ${_rating.toStringAsFixed(1)}\nFeedback: ${_feedbackCtrl.text}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
