import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/student/enrollment_model.dart';
import '../../../routes/app_routes.dart';
import '../../../services/certificate_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/theme_helper.dart';

class MyCoursesPageNew extends StatefulWidget {
  const MyCoursesPageNew({super.key});

  @override
  State<MyCoursesPageNew> createState() => _MyCoursesPageNewState();
}

class _MyCoursesPageNewState extends State<MyCoursesPageNew>
    with TickerProviderStateMixin {
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please login first')));
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Courses',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.brand,
          centerTitle: false,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.play_circle_outline), text: 'In Progress'),
              Tab(icon: Icon(Icons.verified_outlined), text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTabContent(uid, completedOnly: false),
            _buildTabContent(uid, completedOnly: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String uid, {required bool completedOnly}) {
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
            child: Text('Unable to load courses: ${snapshot.error}'),
          );
        }

        final enrollments =
            snapshot.data?.docs.map(EnrollmentModel.fromFirestore).where((
              enrollment,
            ) {
              return completedOnly
                  ? enrollment.isCompleted
                  : !enrollment.isCompleted;
            }).toList() ??
            <EnrollmentModel>[];

        enrollments.sort((a, b) {
          final aDate = a.enrolledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.enrolledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

        if (enrollments.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  completedOnly
                      ? Icons.verified_outlined
                      : Icons.school_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  completedOnly
                      ? 'No completed courses yet'
                      : 'No courses in progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  completedOnly
                      ? 'Keep learning to earn certificates!'
                      : 'Browse courses and start learning!',
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                ),
                const SizedBox(height: 20),
                if (!completedOnly)
                  ElevatedButton(
                    onPressed: () =>
                        GoRouter.of(context).push(AppRoutes.studentBrowse),
                    child: const Text('Browse Courses'),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: enrollments.length,
          itemBuilder: (context, idx) {
            final e = enrollments[idx];
            return completedOnly
                ? _buildCompletedCard(context, e)
                : _buildInProgressCard(context, e);
          },
        );
      },
    );
  }

  Widget _buildInProgressCard(BuildContext context, EnrollmentModel e) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with thumbnail & title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: e.courseThumbnail.isNotEmpty
                        ? Image.network(
                            e.courseThumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: AppColors.brandSoft,
                              child: const Icon(
                                Icons.menu_book,
                                color: AppColors.brand,
                                size: 24,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.brandSoft,
                            child: const Icon(
                              Icons.menu_book,
                              color: AppColors.brand,
                              size: 24,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title and category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.courseTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.courseCategory,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lessons info
            Text(
              '${e.completedLessons}/${e.totalLessons} lessons • last studied today',
              style: TextStyle(fontSize: 11, color: context.textSecondary),
            ),
            const SizedBox(height: 8),

            // Progress row
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: e.progress.clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.brand,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${e.progressPercent}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.brand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: () {
                  context.push(
                    AppRoutes.studentCourseDetail,
                    extra: {'courseId': e.courseId},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Continue Learning →',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context, EnrollmentModel e) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completed badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.courseTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.courseCategory,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Completed date
            Text(
              'Completed on ${_formatDate(e.completedDate)}',
              style: TextStyle(fontSize: 11, color: context.textSecondary),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => CertificateService.generateAndDownload(
                      context: context,
                      courseTitle: e.courseTitle,
                      courseCategory: e.courseCategory,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.brand,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'View Certificate',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      context.push(
                        AppRoutes.studentCourseDetail,
                        extra: {'courseId': e.courseId},
                      );
                    },
                    child: const Text(
                      'Review Course',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
