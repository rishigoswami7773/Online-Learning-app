import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import 'package:online_learning_app/views/widgets/dashboard_constants.dart';
import 'package:online_learning_app/views/widgets/dashboard_widgets.dart';

import '../../../controllers/student/dashboard_controller.dart';
import '../../../models/student/course_model.dart';
import '../../../models/student/enrollment_model.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  final DashboardController _controller = DashboardController();
  final TextEditingController _searchController = TextEditingController();

  late Future<DashboardData> _dashboardFuture;
  late AnimationController _animationController;
  String _selectedCategory = 'All';

  /// Handle back button press on dashboard
  Future<bool> _onWillPop() async {
    // Show confirmation dialog when back button is pressed
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Exit Application'),
            content: const Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _controller.loadDashboardData();
    _animationController = AnimationController(
      duration: DashboardConstants.durationSlow,
      vsync: this,
    );
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final navigator = Navigator.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.surface, const Color(0xFFEFF7F6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: FutureBuilder<DashboardData>(
            future: _dashboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return _buildLoadingState();
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return _buildErrorState();
              }

              final data = snapshot.data!;
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _dashboardFuture = _controller.loadDashboardData(
                      forceRefresh: true,
                    );
                  });
                  await _dashboardFuture;
                },
                child: _buildDashboard(data),
              );
            },
          ),
        ),
        bottomNavigationBar: _PremiumBottomNavigation(
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) {
              Navigator.of(
                context,
              ).pushReplacementNamed(AppRoutes.studentBrowse);
            } else if (index == 2) {
              Navigator.of(
                context,
              ).pushReplacementNamed(AppRoutes.studentMyCourses);
            } else if (index == 3) {
              Navigator.of(context).pushNamed(AppRoutes.studentProfile);
            } else if (index == 4) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon.')),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Unable to load dashboard'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _dashboardFuture = _controller.loadDashboardData(
                  forceRefresh: true,
                );
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          collapsedHeight: kToolbarHeight,
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: const FlexibleSpaceBar(
            expandedTitleScale: 1,
            background: _DashboardLoadingHeader(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: DashboardConstants.spacingL,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: DashboardConstants.spacingL),
              const _LoadingBar(height: 72),
              const SizedBox(height: DashboardConstants.spacingXL),
              Row(
                children: const [
                  Expanded(child: _LoadingBar(height: 104)),
                  SizedBox(width: DashboardConstants.spacingM),
                  Expanded(child: _LoadingBar(height: 104)),
                  SizedBox(width: DashboardConstants.spacingM),
                  Expanded(child: _LoadingBar(height: 104)),
                ],
              ),
              const SizedBox(height: DashboardConstants.spacing2XL),
              const _LoadingBar(height: 44),
              const SizedBox(height: DashboardConstants.spacingL),
              const _LoadingBar(height: 220),
              const SizedBox(height: DashboardConstants.spacing2XL),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard(DashboardData data) {
    final continueLearning = _filteredEnrollments(data.continueLearning);
    final filteredCourses = _filteredCourses(data.allCourses);
    final filteredIds = filteredCourses.map((e) => e.id).toSet();

    final recommended = data.recommendedCourses
        .where((course) => filteredIds.contains(course.id))
        .toList();
    final trending = data.trendingCourses
        .where((course) => filteredIds.contains(course.id))
        .toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          collapsedHeight: kToolbarHeight,
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            expandedTitleScale: 1,
            background: _buildHeaderSection(data),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: DashboardConstants.spacingL,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: DashboardConstants.spacingL),
              StreakCard(
                streakDays: data.userStats.streakDays,
                message: data.userStats.streakDisplay,
              ),
              const SizedBox(height: DashboardConstants.spacingXL),
              _buildStatsRow(data),
              const SizedBox(height: DashboardConstants.spacing2XL),
              _buildSearchBar(),
              const SizedBox(height: DashboardConstants.spacing2XL),
              if (continueLearning.isNotEmpty) ...[
                SectionHeader(
                  title: 'Continue Learning',
                  icon: Icons.play_circle_outlined,
                  actionText: continueLearning.length > 2 ? 'See All' : null,
                  onActionTap: continueLearning.length > 2
                      ? () => Navigator.of(
                          context,
                        ).pushReplacementNamed(AppRoutes.studentMyCourses)
                      : null,
                ),
                const SizedBox(height: DashboardConstants.spacingL),
                _buildContinueLearning(continueLearning.take(3).toList()),
                const SizedBox(height: DashboardConstants.spacing2XL),
              ] else ...[
                EmptyState(
                  icon: Icons.play_lesson_outlined,
                  title: 'Start Your Learning Journey',
                  message: 'Enroll in a course to begin learning today',
                  buttonLabel: 'Explore Courses',
                  onButtonTap: () => Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.studentBrowse),
                ),
                const SizedBox(height: DashboardConstants.spacing2XL),
              ],
              SectionHeader(
                title: 'Recommended For You',
                icon: Icons.lightbulb_outlined,
              ),
              const SizedBox(height: DashboardConstants.spacingL),
              _buildCourseGrid(recommended, recommendation: true),
              const SizedBox(height: DashboardConstants.spacing2XL),
              SectionHeader(title: 'Trending Now', icon: Icons.trending_up),
              const SizedBox(height: DashboardConstants.spacingL),
              _buildTrending(trending),
              const SizedBox(height: DashboardConstants.spacing2XL),
              _buildQuickActions(),
              const SizedBox(height: DashboardConstants.spacing2XL),
              SectionHeader(
                title: 'Explore Categories',
                icon: Icons.apps_outlined,
              ),
              const SizedBox(height: DashboardConstants.spacingL),
              _buildCategories(data.categories),
              const SizedBox(height: DashboardConstants.spacingXL),
              _buildMotivation(data.motivationalText),
              const SizedBox(height: DashboardConstants.spacing2XL),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(DashboardData data) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DashboardConstants.brandColor,
            DashboardConstants.accentColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DashboardConstants.spacingL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${getGreeting()}, ${data.studentName}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: DashboardConstants.spacingXS),
                      Text(
                        'Ready to learn something new today?',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.studentProfile),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                          DashboardConstants.radiusLarge,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DashboardConstants.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(DashboardData data) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.book_outlined,
            label: 'Enrolled',
            value: data.userStats.totalCoursesEnrolled.toString(),
          ),
        ),
        const SizedBox(width: DashboardConstants.spacingM),
        Expanded(
          child: StatCard(
            icon: Icons.check_circle_outlined,
            label: 'Completed',
            value: data.userStats.totalCoursesCompleted.toString(),
          ),
        ),
        const SizedBox(width: DashboardConstants.spacingM),
        Expanded(
          child: StatCard(
            icon: Icons.timer_outlined,
            label: 'Hours',
            value: formatLearningHours(data.userStats.totalLearningHours),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search courses or categories',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: _searchController.clear,
                icon: const Icon(Icons.close),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DashboardConstants.radiusLarge),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildContinueLearning(List<EnrollmentModel> enrollments) {
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: enrollments.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: DashboardConstants.spacingM),
        itemBuilder: (context, index) {
          final enrollment = enrollments[index];
          return Container(
            width: 280,
            padding: const EdgeInsets.all(DashboardConstants.spacingL),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                DashboardConstants.radiusLarge,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enrollment.courseTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: DashboardConstants.spacingXS),
                Text(enrollment.courseCategory),
                const SizedBox(height: DashboardConstants.spacingL),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: enrollment.progress,
                    minHeight: 8,
                    color: DashboardConstants.brandColor,
                    backgroundColor: DashboardConstants.brandColor.withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
                const SizedBox(height: DashboardConstants.spacingS),
                Text('${enrollment.progressPercent}% completed'),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.studentCourseDetail,
                        arguments: {'enrollment': enrollment.toMap()},
                      );
                    },
                    child: const Text('Resume'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseGrid(
    List<CourseModel> courses, {
    bool recommendation = false,
  }) {
    if (courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(DashboardConstants.spacingL),
        child: Text(
          recommendation
              ? 'No recommendations available yet'
              : 'No courses available',
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: DashboardConstants.spacingL,
        crossAxisSpacing: DashboardConstants.spacingL,
        childAspectRatio: 0.75,
      ),
      itemCount: courses.take(4).length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return CourseCard(
          imageUrl: course.thumbnailUrl,
          title: course.title,
          category: course.category,
          instructor: course.instructor,
          rating: course.rating,
          studentCount: formatStudentCount(100 + (index * 60)),
          tags: recommendation && index == 0 ? const ['Recommended'] : const [],
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.studentCourseDetail,
              arguments: {'course': course.toMap()},
            );
          },
        );
      },
    );
  }

  Widget _buildTrending(List<CourseModel> courses) {
    if (courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(DashboardConstants.spacingL),
        child: Text('No trending courses available'),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: courses.take(4).length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: DashboardConstants.spacingM),
        itemBuilder: (context, index) {
          final course = courses[index];
          return SizedBox(
            width: 160,
            child: CourseCard(
              imageUrl: course.thumbnailUrl,
              title: course.title,
              category: course.category,
              instructor: course.instructor,
              rating: course.rating,
              studentCount: formatStudentCount(500 + (index * 200)),
              tags: index == 0
                  ? const ['Bestseller']
                  : index == 1
                  ? const ['Top Rated']
                  : const ['Trending'],
              onTap: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.studentCourseDetail,
                  arguments: {'course': course.toMap()},
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Quick Actions', icon: Icons.flash_on),
        const SizedBox(height: DashboardConstants.spacingL),
        GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: DashboardConstants.spacingM,
          crossAxisSpacing: DashboardConstants.spacingM,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            QuickActionCard(
              icon: Icons.auto_stories_outlined,
              label: 'My Learning',
              onTap: () => Navigator.of(
                context,
              ).pushReplacementNamed(AppRoutes.studentMyCourses),
              backgroundColor: DashboardConstants.brandColor,
            ),
            QuickActionCard(
              icon: Icons.explore_outlined,
              label: 'Explore',
              onTap: () => Navigator.of(
                context,
              ).pushReplacementNamed(AppRoutes.studentBrowse),
              backgroundColor: DashboardConstants.accentColor,
            ),
            QuickActionCard(
              icon: Icons.card_giftcard_outlined,
              label: 'Certificates',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Certificates coming soon')),
                );
              },
              backgroundColor: const Color(0xFFF59E0B),
            ),
            QuickActionCard(
              icon: Icons.favorite_outline,
              label: 'Wishlist',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.studentWishlist),
              backgroundColor: const Color(0xFFEF4444),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategories(List<String> categories) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: DashboardConstants.spacingM),
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryChip(
            label: category,
            icon: Icons.school_outlined,
            isSelected: _selectedCategory == category,
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildMotivation(String text) {
    return Container(
      padding: const EdgeInsets.all(DashboardConstants.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DashboardConstants.successColor.withValues(alpha: 0.1),
            const Color(0xFFFEF3C7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DashboardConstants.radiusLarge),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 32)),
          const SizedBox(width: DashboardConstants.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Tip',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DashboardConstants.spacingXS),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<CourseModel> _filteredCourses(List<CourseModel> source) {
    final query = _searchController.text.trim().toLowerCase();
    return source.where((course) {
      final matchesCategory =
          _selectedCategory == 'All' || course.category == _selectedCategory;
      if (!matchesCategory) return false;
      if (query.isEmpty) return true;
      return course.title.toLowerCase().contains(query) ||
          course.category.toLowerCase().contains(query);
    }).toList();
  }

  List<EnrollmentModel> _filteredEnrollments(List<EnrollmentModel> source) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return source;
    return source
        .where((item) => item.courseTitle.toLowerCase().contains(query))
        .toList();
  }
}

class _DashboardLoadingHeader extends StatelessWidget {
  const _DashboardLoadingHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DashboardConstants.brandColor,
            DashboardConstants.accentColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: DashboardConstants.spacingL,
            vertical: DashboardConstants.spacingL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _LoadingBar(height: 28, widthFactor: 0.55, light: true),
              SizedBox(height: DashboardConstants.spacingXS),
              _LoadingBar(height: 18, widthFactor: 0.72, light: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({
    required this.height,
    this.widthFactor,
    this.light = false,
  });

  final double height;
  final double? widthFactor;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      height: height,
      width: widthFactor == null ? double.infinity : null,
      decoration: BoxDecoration(
        color: (light ? Colors.white : Colors.grey.shade300).withValues(
          alpha: 0.9,
        ),
        borderRadius: BorderRadius.circular(DashboardConstants.radiusMedium),
      ),
    );

    if (widthFactor == null) {
      return ShimmerLoading(child: bar);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: ShimmerLoading(child: bar),
      ),
    );
  }
}

class _PremiumBottomNavigation extends StatelessWidget {
  const _PremiumBottomNavigation({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        indicatorColor: DashboardConstants.brandColor.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_lesson_outlined),
            selectedIcon: Icon(Icons.play_lesson),
            label: 'My Learning',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}
