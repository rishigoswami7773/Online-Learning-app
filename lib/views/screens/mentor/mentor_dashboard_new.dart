import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../../controllers/mentor/mentor_dashboard_controller.dart';
import '../../../controllers/theme_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/uid_resolver.dart';
import '../../../utils/theme_helper.dart';

class MentorDashboardScreenNew extends StatefulWidget {
  const MentorDashboardScreenNew({super.key});

  @override
  State<MentorDashboardScreenNew> createState() =>
      _MentorDashboardScreenNewState();
}

class _MentorDashboardScreenNewState extends State<MentorDashboardScreenNew> {
  late String _uid;
  late MentorDashboardController _controller;

  @override
  void initState() {
    super.initState();
    _uid = UidResolver.uid ?? '';
    _controller = MentorDashboardController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!UidResolver.isLoggedIn && mounted) {
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!UidResolver.isLoggedIn) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          // No dashboard to go back to since we are on the dashboard
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mentor Dashboard'),
          actions: [
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController().mode,
              builder: (context, mode, _) => IconButton(
                icon: Icon(
                  mode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode_outlined,
                ),
                onPressed: ThemeController().toggle,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                context.push('/mentor_create');
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: _controller.coursesCountStream(),
                      builder: (context, snap) {
                        final val = snap.data ?? 0;
                        return _buildStatCard(
                          'My Courses',
                          val.toString(),
                          Icons.book,
                          Colors.blue,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: _controller.enrollmentsCountStream(),
                      builder: (context, snap) {
                        final val = snap.data ?? 0;
                        return InkWell(
                          onTap: () {
                            context.push(AppRoutes.mentorStudentProgress);
                          },
                          child: _buildStatCard(
                            'Total Students',
                            val.toString(),
                            Icons.people,
                            Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<double>(
                      stream: _controller.averageRatingStream(),
                      builder: (context, snap) {
                        final val = snap.data ?? 0.0;
                        return _buildStatCard(
                          'Avg Rating',
                          val.toStringAsFixed(1),
                          Icons.star,
                          Colors.amber,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Students On Track
              Text(
                'Students On Track',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('enrollments')
                      .where('mentorId', isEqualTo: _uid)
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final mentorEnrollments = snapshot.data?.docs ?? [];
                    if (mentorEnrollments.isNotEmpty) {
                      return _buildOnTrackList(mentorEnrollments);
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('courses')
                          .where('mentorId', isEqualTo: _uid)
                          .snapshots(),
                      builder: (context, courseSnapshot) {
                        if (courseSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final courseIds =
                            courseSnapshot.data?.docs
                                .map((doc) => doc.id)
                                .toSet() ??
                            <String>{};
                        if (courseIds.isEmpty) {
                          return Center(
                            child: Text(
                              'No enrolled students yet',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('enrollments')
                              .snapshots(),
                          builder: (context, enrollmentSnapshot) {
                            if (enrollmentSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final docs =
                                enrollmentSnapshot.data?.docs
                                    .where((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      return courseIds.contains(
                                        data['courseId']?.toString() ?? '',
                                      );
                                    })
                                    .take(10)
                                    .toList() ??
                                [];

                            if (docs.isEmpty) {
                              return Center(
                                child: Text(
                                  'No enrolled students yet',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }

                            return _buildOnTrackList(docs);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // My Courses Section
              Text('My Courses', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .where('mentorId', isEqualTo: _uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: context.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No data yet',
                            style: TextStyle(color: context.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  final courses = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: courses.length,
                    itemBuilder: (context, idx) {
                      final course = courses[idx];
                      final data = course.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(data['title'] ?? 'Untitled'),
                          subtitle: Text(data['category'] ?? 'General'),
                          trailing: PopupMenuButton(
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                child: const Text('Manage Quizzes'),
                                onTap: () {
                                  context.push(
                                    AppRoutes.mentorQuiz,
                                    extra: {
                                      'courseId': course.id,
                                      'moduleId': '',
                                    },
                                  );
                                },
                              ),
                              PopupMenuItem(
                                child: const Text('Edit'),
                                onTap: () {
                                  context.push(
                                    '/mentor_create',
                                    extra: {'id': course.id, ...data},
                                  );
                                },
                              ),
                              PopupMenuItem(
                                child: const Text('View Enrollments'),
                                onTap: () {
                                  context.push(
                                    '/mentor_students',
                                    extra: {
                                      'courseId': course.id,
                                      'courseTitle': data['title'],
                                    },
                                  );
                                },
                              ),
                              PopupMenuItem(
                                child: const Text('Delete'),
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Course?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await FirebaseFirestore.instance
                                        .collection('courses')
                                        .doc(course.id)
                                        .delete();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: context.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.borderColor, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnTrackList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: docs.length,
      itemBuilder: (context, idx) {
        final data = docs[idx].data() as Map<String, dynamic>;
        final name = data['studentName'] as String? ?? 'Student';
        final progress = ((data['progressPercent'] as num?)?.toDouble() ?? 0.0);
        return Container(
          width: 100,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor, width: 0.8),
            boxShadow: context.isDark
                ? const []
                : const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: progress / 100,
                strokeWidth: 6,
                backgroundColor: context.borderColor,
                color: progress >= 70 ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(fontSize: 11, color: context.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
