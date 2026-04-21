import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import 'admin_widgets.dart';

class AdminManageCoursesScreen extends StatelessWidget {
  const AdminManageCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courses = List.generate(12, (i) => {'title': 'Course $i', 'subtitle': 'Category ${i % 4}'});
    final isWide = MediaQuery.of(context).size.width >= 900;
    final cross = isWide ? 3 : 1;
    final primary = Theme.of(context).primaryColor;
    return AdminPageWrapper(
      title: 'Manage Courses',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cross, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 3),
          itemCount: courses.length,
          itemBuilder: (c, i) {
            final cs = courses[i];
            return InkWell(
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.courseDetail, arguments: cs),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: [
                    CircleAvatar(backgroundColor: primary.withAlpha(25), child: const FlutterLogo()),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(cs['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(cs['subtitle']!),
                    ])),
                    IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CourseDetailScreen extends StatelessWidget {
  final String title;
  const CourseDetailScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AdminPageWrapper(
      title: title,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text('Course description goes here.'),
          const SizedBox(height: 12),
          ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.publish), label: const Text('Publish update')),
        ]),
      ),
    );
  }
}
