import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';

import '../../widgets/course_card.dart';

class StudentBrowseCourses extends StatelessWidget {
  const StudentBrowseCourses({super.key});

  @override
  Widget build(BuildContext context) {
    final courses = CourseCard.dummyCourses;
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Courses')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.separated(
          itemCount: courses.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, idx) => ListTile(
            onTap: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.courseDetail, arguments: courses[idx]),
            leading: CircleAvatar(child: Text(courses[idx]['title'][0])),
            title: Text(courses[idx]['title']),
            subtitle: Text('By ${courses[idx]['instructor']}'),
          ),
        ),
      ),
    );
  }
}
