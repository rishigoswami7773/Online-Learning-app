import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../controllers/theme_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../models/student/enrollment_model.dart';
import '../../../models/student/course_model.dart';
import '../../../utils/theme_helper.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    // Parallel queries
    final [
      userName,
      enrolledCount,
      completedCount,
      streakDays,
    ] = await Future.wait([
      _fetchUserName(uid),
      _countEnrollments(uid, 'active'),
      _countEnrollments(uid, 'completed'),
      _fetchStreakDays(uid),
    ]);

    return {
      'userName': userName,
      'enrolledCount': enrolledCount,
      'completedCount': completedCount,
      'streakDays': streakDays,
      'uid': uid,
    };
  }

  Future<String> _fetchUserName(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data()?['name'] ?? 'Student';
  }

  Future<int> _countEnrollments(String uid, String status) async {
    final snap = await FirebaseFirestore.instance
        .collection('enrollments')
        .where('studentId', isEqualTo: uid)
        .where('status', isEqualTo: status)
        .get();
    return snap.docs.length;
  }

  Future<int> _fetchStreakDays(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data()?['streakDays'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data ?? {};
          return _buildDashboard(data);
        },
      ),
    );
  }

  Widget _buildDashboard(Map<String, dynamic> data) {
    final userName = data['userName'] as String;
    final enrolledCount = data['enrolledCount'] as int;
    final completedCount = data['completedCount'] as int;
    final streakDays = data['streakDays'] as int;
    final uid = data['uid'] as String;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _dashboardFuture = _loadDashboardData();
        });
        await _dashboardFuture;
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Greeting
          Text(
            'Welcome back, $userName',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep up the momentum! 🚀',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              Expanded(
                child: Card(
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
                      children: [
                        Text(
                          enrolledCount.toString(),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Enrolled',
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
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
                      children: [
                        Text(
                          completedCount.toString(),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Completed',
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
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
                      children: [
                        Text(
                          '$streakDays',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Day Streak',
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Continue learning
          const Text(
            'Continue Learning',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildContinueLearning(uid),
          const SizedBox(height: 24),

          // Browse courses
          const Text(
            'Browse Courses',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildBrowseCourses(),
        ],
      ),
    );
  }

  Widget _buildContinueLearning(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: uid)
          .where('status', isEqualTo: 'active')
          .orderBy('lastAccessedAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 160,
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(
            height: 160,
            child: Center(child: Text('No active courses')),
          );
        }

        final enrollments = snapshot.data!.docs
            .map(
              (doc) => EnrollmentModel.fromMap(
                doc.data() as Map<String, dynamic>,
                fallbackId: doc.id,
              ),
            )
            .toList();

        return SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: enrollments.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final e = enrollments[idx];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.studentCourseDetail,
                    arguments: {'courseId': e.courseId},
                  );
                },
                child: Card(
                  color: context.cardColor,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: context.borderColor, width: 0.8),
                  ),
                  child: Container(
                    width: 260,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.courseTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: e.progress.clamp(0.0, 1.0),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${e.completedLessons}/${e.totalLessons} lessons',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBrowseCourses() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('courses').limit(4).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 160,
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(
            height: 160,
            child: Center(child: Text('No courses available')),
          );
        }

        final courses = snapshot.data!.docs
            .map(
              (doc) => LegacyCourseModel.fromMap(
                doc.data() as Map<String, dynamic>,
                fallbackId: doc.id,
              ),
            )
            .toList();

        return SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final c = courses[idx];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.studentCourseDetail,
                    arguments: {'courseId': c.id},
                  );
                },
                child: Card(
                  color: context.cardColor,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: context.borderColor, width: 0.8),
                  ),
                  child: SizedBox(
                    width: 260,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: c.thumbnailUrl.isNotEmpty
                              ? Image.network(
                                  c.thumbnailUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: context.bgColor,
                                  child: Center(child: Icon(Icons.menu_book)),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                c.instructor,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                ),
                                maxLines: 1,
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    c.rating.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
