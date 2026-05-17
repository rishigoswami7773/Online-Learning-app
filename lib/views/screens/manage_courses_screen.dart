import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import '../../controllers/mentor/mentor_courses_controller.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  String query = '';

  final _controller = MentorCoursesController();

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
              child: StreamBuilder(
                stream: _controller.myCoursesStream(),
                builder: (context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = (snapshot.data?.docs ?? []) as List;
                  final list = docs
                      .map(
                        (d) =>
                            (d.data() as Map<String, dynamic>)..['id'] = d.id,
                      )
                      .toList()
                      .cast<Map<String, dynamic>>();
                  final filtered = list
                      .where(
                        (c) => (c['title'] as String).toLowerCase().contains(
                          query.toLowerCase(),
                        ),
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
                            child: Text(
                              (c['title'] as String).isNotEmpty
                                  ? (c['title'] as String)[0]
                                  : '?',
                            ),
                          ),
                          title: Text(
                            c['title'] as String? ?? 'Untitled',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            'Enrollments: ${(c['enrollmentCount'] as num?)?.toInt() ?? 0} • Rating: ${((c['averageRating'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)} ★',
                          ),
                          trailing: SizedBox(
                            width: 180,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  tooltip: 'View',
                                  onPressed: () => context.push(
                                    AppRoutes.courseDetail,
                                    extra: c,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Edit',
                                  onPressed: () => context.push(
                                    AppRoutes.mentorCreate,
                                    extra: c,
                                  ),
                                ),
                                Switch.adaptive(
                                  value:
                                      (c['isPublished'] as bool?) ??
                                      (c['status'] == 'active'),
                                  onChanged: (value) async {
                                    await _controller.togglePublish(
                                      c['id'] as String,
                                      value,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          onTap: () =>
                              context.push(AppRoutes.courseDetail, extra: c),
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
        onPressed: () => context.push(AppRoutes.mentorCreate),
        icon: const Icon(Icons.add),
        label: const Text('New Course'),
      ),
    );
  }
}
