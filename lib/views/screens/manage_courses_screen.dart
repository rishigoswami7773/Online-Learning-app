import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import '../../models/course_repo.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Courses'),
        actions: [
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search courses',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ValueListenableBuilder<List<Course>>(
                valueListenable: CourseRepository.instance.coursesListenable,
                builder: (context, list, child) {
                  final filtered = list
                      .where(
                        (c) =>
                            c.title.toLowerCase().contains(query.toLowerCase()),
                      )
                      .toList();
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No courses match your search'),
                    );
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final c = filtered[idx];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withAlpha(25),
                            child: Text(c.title[0]),
                          ),
                          title: Text(
                            c.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text('By ${c.instructor} • ${c.rating} ★'),
                          trailing: SizedBox(
                            width: 140,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  tooltip: 'View',
                                  onPressed: () =>
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.courseDetail,
                                        arguments: c.toMap(),
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Edit',
                                  onPressed: () =>
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.mentorCreate,
                                        arguments: c.toMap(),
                                      ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'delete') {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Delete course'),
                                          content: Text('Delete "${c.title}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                CourseRepository.instance
                                                    .removeCourse(c.id);
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else if (v == 'publish') {
                                      CourseRepository.instance.togglePublish(
                                        c.id,
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'publish',
                                      child: Text(
                                        (c.published == true)
                                            ? 'Unpublish'
                                            : 'Publish',
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.courseDetail,
                            arguments: c.toMap(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.mentorCreate),
        icon: const Icon(Icons.add),
        label: const Text('New Course'),
      ),
    );
  }
}
