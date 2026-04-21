import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import 'package:online_learning_app/controllers/student/enrollment_controller.dart';
import 'package:online_learning_app/models/student/enrollment_model.dart';
import 'package:online_learning_app/views/widgets/dashboard_constants.dart';
import 'package:online_learning_app/views/widgets/dashboard_widgets.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EnrollmentController _enrollmentController = EnrollmentController();

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildInProgressTab(), _buildCompletedTab()],
      ),
    );
  }

  Widget _buildInProgressTab() {
    return FutureBuilder<List<EnrollmentModel>>(
      future: _enrollmentController.getInProgressCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final inProgressCourses = snapshot.data ?? [];

        if (inProgressCourses.isEmpty) {
          return EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'No In Progress Courses',
            message: 'Start learning by enrolling in a course',
            buttonLabel: 'Browse Courses',
            onButtonTap: () {
              Navigator.of(context).pushNamed(AppRoutes.studentBrowse);
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(DashboardConstants.spacingL),
          itemCount: inProgressCourses.length,
          itemBuilder: (context, index) {
            final enrollment = inProgressCourses[index];
            final progress = enrollment.progress;
            final completedLessons = enrollment.completedLessons;
            final totalLessons = enrollment.totalLessons;

            return Card(
              margin: EdgeInsets.only(bottom: DashboardConstants.spacingL),
              child: Padding(
                padding: const EdgeInsets.all(DashboardConstants.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enrollment.courseTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: DashboardConstants.spacingS),
                    Text(
                      enrollment.courseCategory,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: DashboardConstants.spacingL),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completedLessons/$totalLessons lessons',
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
                        value: progress,
                        minHeight: 8,
                        backgroundColor: DashboardConstants.neutralLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          DashboardConstants.brandColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: DashboardConstants.spacingL),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.studentCourseDetail,
                            arguments: enrollment.id,
                          );
                        },
                        child: const Text('Continue Learning'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    return FutureBuilder<List<EnrollmentModel>>(
      future: _enrollmentController.getCompletedCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final completedCourses = snapshot.data ?? [];

        if (completedCourses.isEmpty) {
          return EmptyState(
            icon: Icons.verified_outlined,
            title: 'No Completed Courses',
            message: 'Complete a course to view your certificate',
            buttonLabel: 'Continue Learning',
            onButtonTap: () {
              _tabController.animateTo(0);
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(DashboardConstants.spacingL),
          itemCount: completedCourses.length,
          itemBuilder: (context, index) {
            final enrollment = completedCourses[index];

            return Card(
              margin: EdgeInsets.only(bottom: DashboardConstants.spacingL),
              child: Padding(
                padding: const EdgeInsets.all(DashboardConstants.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                enrollment.courseTitle,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(
                                height: DashboardConstants.spacingXS,
                              ),
                              Text(
                                enrollment.courseCategory,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: DashboardConstants.spacingS,
                            vertical: DashboardConstants.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: DashboardConstants.successColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '✓ Completed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DashboardConstants.spacingL),
                    Container(
                      padding: const EdgeInsets.all(
                        DashboardConstants.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: DashboardConstants.neutralLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: DashboardConstants.brandColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Certificate of Completion',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: DashboardConstants.spacingXS),
                          Text(
                            'Issued: ${enrollment.completedDate?.toString().split(" ")[0] ?? "N/A"}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DashboardConstants.spacingL),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.studentCourseDetail,
                            arguments: enrollment.id,
                          );
                        },
                        child: const Text('View Certificate'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
