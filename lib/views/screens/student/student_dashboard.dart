import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../routes/app_routes.dart';
import '../../../models/student/enrollment_model.dart';
import '../../../models/student/course_model.dart';
import '../../../utils/responsive.dart';
import '../../../utils/animations.dart';

bool _isValidImageUrl(String url) =>
    url.startsWith('http://') || url.startsWith('https://');

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<Map<String, dynamic>> _loadStats() async {
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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final appBarBg =
        theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please login first')));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Do you want to exit the application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Exit', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: appBarBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text('Dashboard'),
          centerTitle: false,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _statsFuture = _loadStats();
            });
            await _statsFuture;
          },
          child: FutureBuilder<Map<String, dynamic>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ShimmerBox(
                      width: double.infinity,
                      height: 240,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: List.generate(
                        3,
                        (index) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index == 2 ? 0 : 12,
                            ),
                            child: ShimmerBox(
                              width: double.infinity,
                              height: 96,
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: SizedBox(
                    height: 200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 56,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF52616B)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _statsFuture = _loadStats();
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final stats = snapshot.data ?? {};
              return _buildContent(context, uid, stats);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    String uid,
    Map<String, dynamic> stats,
  ) {
    const Color studentTeal = Color(0xFF0E7C86);
    final theme = Theme.of(context);
    final titleColor = theme.colorScheme.onSurface;
    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        // Premium Hero Banner
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [studentTeal, Color(0xFF17A2B8), Color(0xFF20C997)],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: studentTeal.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${stats['userName'] ?? 'Student'}! 🎓',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep pushing forward with your learning journey!',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              // Quick stats row in hero
              Row(
                children: [
                  Expanded(
                    child: _statPill(
                      label: 'Enrolled',
                      value: '${stats['enrolledCount'] ?? 0}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statPill(
                      label: 'Completed',
                      value: '${stats['completedCount'] ?? 0}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statPill(
                      label: 'Streak',
                      value: '${stats['streakDays'] ?? 0}',
                      suffix: '🔥',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                StaggeredItem(
                  child: _quickActionChip('Browse', Icons.explore, () {
                    context.go(AppRoutes.studentBrowse);
                  }),
                ),
                const SizedBox(width: 10),
                StaggeredItem(
                  delay: const Duration(milliseconds: 60),
                  child: _quickActionChip('My Courses', Icons.menu_book, () {
                    context.go(AppRoutes.studentMyCourses);
                  }),
                ),
                const SizedBox(width: 10),
                StaggeredItem(
                  delay: const Duration(milliseconds: 120),
                  child: _quickActionChip('Progress', Icons.pie_chart, () {
                    context.go(AppRoutes.studentProgress);
                  }),
                ),
                const SizedBox(width: 10),
                StaggeredItem(
                  delay: const Duration(milliseconds: 180),
                  child: _quickActionChip(
                    'Notifications',
                    Icons.notifications,
                    () {
                      context.go(AppRoutes.studentNotifications);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Section header with action
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Continue Learning',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go(AppRoutes.studentBrowse),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Browse'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildContinueLearning(uid),
        const SizedBox(height: 28),

        // Popular courses section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Popular Courses',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: titleColor,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildBrowseCourses(),
        ),
      ],
    );
  }

  Widget _statPill({
    required String label,
    required String value,
    String suffix = '',
  }) {
    final theme = Theme.of(context);
    final onSurfaceMuted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final parsed = int.tryParse(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            parsed == null ? '$value$suffix' : '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          if (parsed != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedCounter(
                  target: parsed,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                if (suffix.isNotEmpty)
                  Text(
                    suffix,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: onSurfaceMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionChip(String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return PressableWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF0E7C86).withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0E7C86), Color(0xFF17A2B8)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueLearning(String uid) {
    final theme = Theme.of(context);
    final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => ShimmerBox(
                width: 220,
                height: 140,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 48,
                    color: theme.dividerColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load data.\nCheck your connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(
            height: 140,
            child: Center(child: Text('No active courses yet')),
          );
        }

        final allEnrollments = snapshot.data!.docs
            .map(
              (doc) => EnrollmentModel.fromMap(
                doc.data() as Map<String, dynamic>,
                fallbackId: doc.id,
              ),
            )
            .toList();

        final active = allEnrollments.where((e) => !e.isCompleted).toList()
          ..sort((a, b) {
            final aDate = a.lastViewedAt ?? DateTime(2000);
            final bDate = b.lastViewedAt ?? DateTime(2000);
            return bDate.compareTo(aDate);
          });
        final display = active.take(3).toList();
        if (display.isEmpty) {
          return const SizedBox(
            height: 140,
            child: Center(child: Text('No active courses yet')),
          );
        }

        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: display.length,
            separatorBuilder: (_, _) =>
                SizedBox(width: Responsive.spacing(context, 12)),
            itemBuilder: (context, idx) {
              final e = display[idx];
              return StaggeredItem(
                delay: Duration(milliseconds: idx * 80),
                child: GestureDetector(
                  onTap: () {
                    GoRouter.of(context).push(
                      AppRoutes.studentCourseDetail,
                      extra: {'courseId': e.courseId},
                    );
                  },
                  child: Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border(
                        left: BorderSide(
                          color: const Color(0xFF6A5AE0),
                          width: 4,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.courseTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          '${(e.progress * 100).toStringAsFixed(0)}% complete',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6A5AE0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: e.progress.clamp(0.0, 1.0),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                          backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF6A5AE0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${e.completedLessons}/${e.totalLessons} lessons',
                          style: TextStyle(fontSize: 11, color: subtitleColor),
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
    final theme = Theme.of(context);
    final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .orderBy('createdAt', descending: true)
          .limit(6)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => ShimmerBox(
                width: 220,
                height: 140,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 140,
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(
            height: 140,
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
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final c = courses[idx];
              return StaggeredItem(
                delay: Duration(milliseconds: idx * 80),
                child: GestureDetector(
                  onTap: () {
                    GoRouter.of(context).push(
                      AppRoutes.studentCourseDetail,
                      extra: {'courseId': c.id},
                    );
                  },
                  child: Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: _isValidImageUrl(c.thumbnailUrl)
                                ? Image.network(
                                    c.thumbnailUrl,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: theme.dividerColor,
                                      child: const Center(
                                        child: Icon(Icons.menu_book, size: 32),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: theme.dividerColor,
                                    child: const Center(
                                      child: Icon(Icons.menu_book, size: 32),
                                    ),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.instructor,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: subtitleColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    c.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
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
