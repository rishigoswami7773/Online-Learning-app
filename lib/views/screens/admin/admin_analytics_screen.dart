import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import 'admin_widgets.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_AdminAnalyticsData> _loadData() async {
    final usersSnap = await FirebaseFirestore.instance
        .collection('users')
        .get();
    final coursesSnap = await FirebaseFirestore.instance
        .collection('courses')
        .get();
    final enrollmentsSnap = await FirebaseFirestore.instance
        .collection('enrollments')
        .get();

    final userMap = {
      for (final doc in usersSnap.docs)
        doc.id: (doc.data()['name'] as String? ?? ''),
    };

    final sorted =
        enrollmentsSnap.docs.map((doc) {
          final d = Map<String, dynamic>.from(doc.data());
          final sid = d['studentId'] as String? ?? '';
          final resolvedName = userMap[sid];
          if (resolvedName != null && resolvedName.isNotEmpty) {
            d['studentName'] = resolvedName;
          }
          return d;
        }).toList()..sort((a, b) {
          final aDate =
              (a['enrolledAt'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bDate =
              (b['enrolledAt'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

    final pendingCoursesSnap = await FirebaseFirestore.instance
        .collection('courses')
        .where('status', isEqualTo: 'pending')
        .get();

    return _AdminAnalyticsData(
      totalUsers: usersSnap.docs.length,
      totalCourses: coursesSnap.docs.length,
      totalEnrollments: enrollmentsSnap.docs.length,
      recentEnrollments: sorted.take(10).cast<Map<String, dynamic>>().toList(),
      pendingCourses: pendingCoursesSnap.docs.length,
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    final date = timestamp.toDate().toLocal();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageWrapper(
      title: 'Analytics',
      showBackButton: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            adminHeroHeader(
              title: 'Analytics',
              subtitle: 'Platform health and engagement overview',
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Users'),
                Tab(text: 'Courses'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Users Tab
                  _buildUsersTab(),
                  // Courses Tab
                  _buildCoursesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return FutureBuilder<_AdminAnalyticsData>(
      future: _loadData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load user analytics: ${snapshot.error}'),
          );
        }

        final data =
            snapshot.data ??
            const _AdminAnalyticsData(
              totalUsers: 0,
              totalCourses: 0,
              totalEnrollments: 0,
              recentEnrollments: [],
              pendingCourses: 0,
            );

        return ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => context.push(AppRoutes.adminManageUsers),
                      child: adminStatCard(
                        label: 'Total Users',
                        value: data.totalUsers.toString(),
                        icon: Icons.people,
                        trend: '+8% this week',
                        trendColor: Colors.green,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No user data available',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }

                final users = snap.data!.docs;
                return adminListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Users',
                        style: AdminTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 12),
                      ...users.asMap().entries.map((entry) {
                        final userDoc = entry.value;
                        final userData = userDoc.data() as Map<String, dynamic>;
                        final name = userData['name'] ?? 'Unknown';
                        final email = userData['email'] ?? 'No email';
                        final createdAt = userData['createdAt'] as Timestamp?;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Text(name),
                              subtitle: Text(email),
                              trailing: Text(
                                _formatDate(createdAt),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCoursesTab() {
    return FutureBuilder<_AdminAnalyticsData>(
      future: _loadData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load course analytics: ${snapshot.error}'),
          );
        }

        final data =
            snapshot.data ??
            const _AdminAnalyticsData(
              totalUsers: 0,
              totalCourses: 0,
              totalEnrollments: 0,
              recentEnrollments: [],
              pendingCourses: 0,
            );

        return ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => context.push(AppRoutes.adminManageCourses),
                      child: adminStatCard(
                        label: 'Total Courses',
                        value: data.totalCourses.toString(),
                        icon: Icons.menu_book,
                        trend: '+4% this week',
                        trendColor: Colors.green,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No course data available',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }

                final courses = snap.data!.docs;
                return adminListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Course Popularity',
                        style: AdminTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 12),
                      ...courses.asMap().entries.map((entry) {
                        final courseDoc = entry.value;
                        final courseData =
                            courseDoc.data() as Map<String, dynamic>;
                        final title = courseData['title'] ?? 'Untitled';
                        final enrollmentCount =
                            (courseData['enrollmentCount'] as num?)?.toInt() ??
                            0;
                        final createdAt = courseData['createdAt'] as Timestamp?;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange.withValues(
                                  alpha: 0.2,
                                ),
                                child: const Icon(
                                  Icons.menu_book,
                                  color: Colors.orange,
                                ),
                              ),
                              title: Text(title),
                              subtitle: Text('$enrollmentCount enrollments'),
                              trailing: Text(
                                _formatDate(createdAt),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _AdminAnalyticsData {
  const _AdminAnalyticsData({
    required this.totalUsers,
    required this.totalCourses,
    required this.totalEnrollments,
    required this.recentEnrollments,
    required this.pendingCourses,
  });

  final int totalUsers;
  final int totalCourses;
  final int totalEnrollments;
  final List<Map<String, dynamic>> recentEnrollments;
  final int pendingCourses;
}
