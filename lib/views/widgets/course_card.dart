import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';

class CourseCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const CourseCard({super.key, required this.data});

  static final List<Map<String, dynamic>> dummyCourses = [
    {
      'id': 'c1',
      'title': 'Flutter for Beginners',
      'instructor': 'Celine',
      'rating': 4.5,
      'description': 'Learn basics of Flutter and build real apps.',
    },
    {
      'id': 'c2',
      'title': 'Advanced Dart',
      'instructor': 'Admin',
      'rating': 4.2,
      'description': 'Deep dive into Dart language features.',
    },
    {
      'id': 'c3',
      'title': 'UI/UX for Mobile',
      'instructor': 'Alice',
      'rating': 4.7,
      'description': 'Design beautiful mobile user interfaces.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppRoutes.courseDetail, arguments: data),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  data['title'][0],
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'By ${data['instructor']}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('${data['rating']}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
