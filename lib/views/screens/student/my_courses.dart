import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:online_learning_app/models/student/enrollment_model.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import 'package:online_learning_app/views/widgets/dashboard_constants.dart';
import 'package:online_learning_app/services/certificate_service.dart';
import '../../../utils/animations.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage>
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final appBarBg =
        theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor;
    final titleColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    const Color studentTeal = Color(0xFF0E7C86);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.studentDashboard);
            }
          },
        ),
        title: Text(
          'My Courses',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: appBarBg,
            child: TabBar(
              controller: _tabController,
              indicator: UnderlineTabIndicator(
                borderSide: const BorderSide(color: studentTeal, width: 3),
                insets: const EdgeInsets.symmetric(horizontal: 16),
              ),
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 0),
              labelColor: studentTeal,
              unselectedLabelColor: subtitleColor,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'In Progress'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEnrollmentTab(completedOnly: false),
          _buildEnrollmentTab(completedOnly: true),
        ],
      ),
    );
  }

  Widget _buildEnrollmentTab({required bool completedOnly}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return Center(
        child: Text(
          'Please sign in to view your courses.',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => setState(() {}),
                    label: const Text('Retry'),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          );
        }

        final enrollments =
            snapshot.data?.docs
                .map((doc) {
                  try {
                    return EnrollmentModel.fromFirestore(doc);
                  } catch (_) {
                    return null;
                  }
                })
                .whereType<EnrollmentModel>()
                .where((enrollment) {
                  return completedOnly
                      ? enrollment.isCompleted
                      : !enrollment.isCompleted;
                })
                .toList() ??
            <EnrollmentModel>[];
        enrollments.sort((a, b) {
          final aDate = a.enrolledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.enrolledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

        if (enrollments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  completedOnly
                      ? Icons.verified_user_rounded
                      : Icons.menu_book_rounded,
                  size: 64,
                  color: Theme.of(context).dividerColor,
                ),
                const SizedBox(height: 16),
                Text(
                  completedOnly
                      ? 'No Completed Courses'
                      : 'No In Progress Courses',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    completedOnly
                        ? 'Complete a course to see it here.'
                        : 'Start learning from your enrolled courses.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (completedOnly) {
                      _tabController.animateTo(0);
                    } else {
                      context.go(AppRoutes.studentBrowse);
                    }
                  },
                  icon: Icon(completedOnly ? Icons.arrow_back : Icons.explore),
                  label: Text(
                    completedOnly ? 'View In Progress' : 'Browse Courses',
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: enrollments.length,
          itemBuilder: (context, index) {
            final enrollment = enrollments[index];
            return StaggeredItem(
              delay: Duration(milliseconds: index * 80),
              child: _CourseCard(
                enrollment: enrollment,
                showCompletedBadge: completedOnly || enrollment.isCompleted,
                onTapCourse: () => context.push(
                  AppRoutes.studentCourseDetail,
                  extra: {
                    'courseId': enrollment.courseId,
                    'courseThumbnail': enrollment.courseThumbnail,
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.enrollment,
    required this.showCompletedBadge,
    required this.onTapCourse,
  });

  final EnrollmentModel enrollment;
  final bool showCompletedBadge;
  final VoidCallback onTapCourse;

  @override
  Widget build(BuildContext context) {
    final isCompleted = showCompletedBadge && enrollment.isCompleted;
    final actionLabel = enrollment.progressPercent > 0
        ? 'Continue Learning'
        : 'Start Learning';

    return Card(
      margin: EdgeInsets.only(bottom: DashboardConstants.spacingL),
      child: Padding(
        padding: const EdgeInsets.all(DashboardConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enrollment.courseTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: DashboardConstants.spacingXS),
                      Text(
                        enrollment.courseCategory,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DashboardConstants.spacingS,
                      vertical: DashboardConstants.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: DashboardConstants.successColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DashboardConstants.spacingL),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${enrollment.completedLessons}/${enrollment.totalLessons} lessons',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${enrollment.progressPercent}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: DashboardConstants.spacingS),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: enrollment.progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: DashboardConstants.neutralLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  DashboardConstants.brandColor,
                ),
              ),
            ),
            if (isCompleted) ...[
              const SizedBox(height: DashboardConstants.spacingL),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => CertificateService.generateAndDownload(
                    context: context,
                    courseTitle: enrollment.courseTitle,
                    courseCategory: enrollment.courseCategory,
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text('Download Certificate'),
                ),
              ),
            ] else ...[
              const SizedBox(height: DashboardConstants.spacingL),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTapCourse,
                  child: Text(actionLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
