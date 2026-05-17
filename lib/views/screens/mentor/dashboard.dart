import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/mentor/mentor_courses_controller.dart';
import '../../../controllers/mentor/mentor_dashboard_controller.dart';
import 'enrolled_students.dart';
import 'mentor_profile.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/uid_resolver.dart';
import '../../../utils/animations.dart';

const Color _mentorTeal = Color(0xFF0E7C86);

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  int _selectedIndex = 0;

  // Controllers for data wiring
  late final MentorDashboardController _dashCtrl;
  late final MentorCoursesController _coursesCtrl;

  @override
  void initState() {
    super.initState();
    _dashCtrl = MentorDashboardController();
    _coursesCtrl = MentorCoursesController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (UidResolver.uid == null && mounted) {
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _dashCtrl.dispose();
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
    final uid = UidResolver.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return;
        }
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
          toolbarHeight: 72,
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: _mentorTeal.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 2),
                  ),
                ],
                gradient: LinearGradient(
                  colors: [_mentorTeal, _mentorTeal.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          title: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(UidResolver.uid)
                .get(),
            builder: (context, snap) {
              final name = (snap.data?.data()?['name'] as String?) ?? 'Mentor';
              final initials = name.isNotEmpty
                  ? name
                        .trim()
                        .split(RegExp(r'\s+'))
                        .map((s) => s[0])
                        .take(2)
                        .join()
                        .toUpperCase()
                  : 'M';
              return Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _mentorTeal,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Good morning 👋',
                        style: TextStyle(fontSize: 11, color: subtitleColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(uid)
                  .collection('items')
                  .snapshots(),
              builder: (context, snap) {
                final unread = (snap.data?.docs ?? []).where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['isRead'] as bool? ??
                          data['read'] as bool? ??
                          false) ==
                      false;
                }).length;
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _mentorTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: _mentorTeal,
                          size: 24,
                        ),
                        onPressed: () =>
                            context.go(AppRoutes.mentorNotifications),
                      ),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        body: _buildBody(uid),
        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton.extended(
                backgroundColor: _mentorTeal,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'New Course',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () => context.push(AppRoutes.mentorCreate),
              )
            : null,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) {
              setState(() => _selectedIndex = i);
            },
            backgroundColor: theme.colorScheme.surface,
            indicatorColor: _mentorTeal.withValues(alpha: 0.12),
            height: 68,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'My Courses',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people_rounded),
                label: 'Students',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Earnings',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(String uid) {
    switch (_selectedIndex) {
      case 0:
        return _OverviewTab(
          dashCtrl: _dashCtrl,
          coursesCtrl: _coursesCtrl,
          uid: uid,
        );
      case 1:
        return _CoursesTab(coursesCtrl: _coursesCtrl, uid: uid);
      case 2:
        return EnrolledStudentsPage(
          onBack: () => setState(() => _selectedIndex = 0),
        );
      case 3:
        return _EarningsTab(uid: uid);
      case 4:
        return MentorProfilePage(
          onBack: () => setState(() => _selectedIndex = 0),
        );
      default:
        return _OverviewTab(
          dashCtrl: _dashCtrl,
          coursesCtrl: _coursesCtrl,
          uid: uid,
        );
    }
  }
}

/// Overview/Dashboard Tab — Premium Design with Controller Streams
class _OverviewTab extends StatelessWidget {
  final MentorDashboardController dashCtrl;
  final MentorCoursesController coursesCtrl;
  final String uid;

  const _OverviewTab({
    required this.dashCtrl,
    required this.coursesCtrl,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Hero Banner
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_mentorTeal, Color(0xFF17A2B8), Color(0xFF20C997)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _mentorTeal.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get(),
              builder: (context, snap) {
                final name =
                    (snap.data?.data()?['name'] as String?) ?? 'Mentor';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.trending_up_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            '📈 On Track',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $name 👋',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Manage your courses and learners',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 28),

          // Quick Stats Section with Streams - Horizontal Chips
          Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Courses count stream
                StreamBuilder<int>(
                  stream: dashCtrl.coursesCountStream(),
                  builder: (context, snap) => StaggeredItem(
                    child: _StatChip(
                      label: 'My Courses',
                      value: '${snap.data ?? 0}',
                      icon: Icons.menu_book_rounded,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Enrollments count stream
                StreamBuilder<int>(
                  stream: dashCtrl.enrollmentsCountStream(),
                  builder: (context, snap) => StaggeredItem(
                    delay: const Duration(milliseconds: 60),
                    child: _StatChip(
                      label: 'Students',
                      value: '${snap.data ?? 0}',
                      icon: Icons.people_rounded,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Average rating stream
                StreamBuilder<double>(
                  stream: dashCtrl.averageRatingStream(),
                  builder: (context, snap) => StaggeredItem(
                    delay: const Duration(milliseconds: 120),
                    child: _StatChip(
                      label: 'Avg Rating',
                      value: (snap.data ?? 0.0).toStringAsFixed(1),
                      icon: Icons.star_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Recent Courses Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Courses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go(AppRoutes.mentorCreate),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('New'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Course List Stream
          StreamBuilder<QuerySnapshot>(
            stream: coursesCtrl.myCoursesStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Column(
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ShimmerBox(
                        width: double.infinity,
                        height: 130,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                );
              }

              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _mentorTeal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.menu_book_outlined,
                            size: 40,
                            color: _mentorTeal.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No courses yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF102A43),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create your first course to get started',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF52616B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Show up to 3 recent courses
              final recentDocs = docs.take(3).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, _) => const SizedBox(height: 12),
                itemCount: recentDocs.length,
                itemBuilder: (context, i) {
                  final doc = recentDocs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final courseId = doc.id;
                  return StaggeredItem(
                    delay: Duration(milliseconds: i * 60),
                    child: _CourseListTile(
                      courseId: courseId,
                      data: data,
                      coursesCtrl: coursesCtrl,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Course List Tile
class _CourseListTile extends StatefulWidget {
  final String courseId;
  final Map<String, dynamic> data;
  final MentorCoursesController coursesCtrl;

  const _CourseListTile({
    required this.courseId,
    required this.data,
    required this.coursesCtrl,
  });

  @override
  State<_CourseListTile> createState() => _CourseListTileState();
}

class _CourseListTileState extends State<_CourseListTile> {
  bool _isHovered = false;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.data['title'] as String?) ?? 'Untitled';
    final status = (widget.data['status'] as String?) ?? 'draft';
    final isPublished = (widget.data['isPublished'] as bool?) ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(
            AppRoutes.mentorCreate,
            extra: {'id': widget.courseId, ...widget.data},
          ),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isHovered
                    ? _mentorTeal.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: _mentorTeal.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _mentorTeal.withValues(alpha: 0.8),
                        const Color(0xFF17A2B8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _getStatusColor(status),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Track button
                IconButton(
                  icon: const Icon(
                    Icons.bar_chart_rounded,
                    color: _mentorTeal,
                    size: 22,
                  ),
                  tooltip: 'Track Progress',
                  onPressed: () => context.push(
                    AppRoutes.mentorStudentProgress,
                    extra: {'courseId': widget.courseId},
                  ),
                ),
                // Publish toggle
                SizedBox(
                  width: 50,
                  child: Switch(
                    value: isPublished,
                    onChanged: (val) async {
                      await widget.coursesCtrl.togglePublish(
                        widget.courseId,
                        val,
                      );
                    },
                    activeThumbColor: _mentorTeal,
                  ),
                ),
                // Delete button
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Course'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await widget.coursesCtrl.deleteCourse(widget.courseId);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// My Courses Tab — Lists all mentor courses with search
class _CoursesTab extends StatefulWidget {
  final MentorCoursesController coursesCtrl;
  final String uid;

  const _CoursesTab({required this.coursesCtrl, required this.uid});

  @override
  State<_CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<_CoursesTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Courses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.mentorCreate),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Course'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search courses...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _mentorTeal,
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() {
                          _searchQuery = '';
                        }),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Courses List with Search
          StreamBuilder<QuerySnapshot>(
            stream: widget.coursesCtrl.myCoursesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final filtered = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = (data['title'] as String? ?? '').toLowerCase();
                return title.contains(_searchQuery.toLowerCase());
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _mentorTeal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.menu_book_outlined,
                            size: 40,
                            color: _mentorTeal.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No courses found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first course to get started',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, _) => const SizedBox(height: 12),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final doc = filtered[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final courseId = doc.id;
                  return _CourseListTile(
                    courseId: courseId,
                    data: data,
                    coursesCtrl: widget.coursesCtrl,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Stat Chip Widget - Horizontal card with icon, value, and label
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final parsedValue = int.tryParse(value);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _mentorTeal.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_mentorTeal, Color(0xFF17A2B8)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (parsedValue == null)
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _mentorTeal,
                  ),
                )
              else
                AnimatedCounter(
                  target: parsedValue,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _mentorTeal,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningsTab extends StatefulWidget {
  final String uid;
  const _EarningsTab({required this.uid});

  @override
  State<_EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<_EarningsTab> {
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;
  String? _error;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _listenPayments();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _listenPayments() {
    // Step 1: Get mentor's course IDs, then query payments
    final fs = FirebaseFirestore.instance;
    _sub = fs
        .collection('courses')
        .where('mentorId', isEqualTo: widget.uid)
        .snapshots()
        .listen((courseSnap) async {
          final courseIds = courseSnap.docs.map((d) => d.id).toList();
          if (courseIds.isEmpty) {
            if (mounted) setState(() { _payments = []; _loading = false; });
            return;
          }
          try {
            // Chunk courseIds (Firestore whereIn max 30)
            final allPayments = <Map<String, dynamic>>[];
            for (int i = 0; i < courseIds.length; i += 30) {
              final chunk = courseIds.skip(i).take(30).toList();
              final paySnap = await fs
                  .collection('payments')
                  .where('courseId', whereIn: chunk)
                  .get();
              for (final doc in paySnap.docs) {
                allPayments.add({'id': doc.id, ...doc.data()});
              }
            }
            // Sort newest first
            allPayments.sort((a, b) {
              final aTs = a['paidAt'] as Timestamp?;
              final bTs = b['paidAt'] as Timestamp?;
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs);
            });
            if (mounted) {
              setState(() { _payments = allPayments; _loading = false; _error = null; });
            }
          } catch (e) {
            if (mounted) setState(() { _error = e.toString(); _loading = false; });
          }
        }, onError: (e) {
          if (mounted) setState(() { _error = e.toString(); _loading = false; });
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                'Could not load earnings.\nCheck your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() { _loading = true; _error = null; });
                  _sub?.cancel();
                  _listenPayments();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final total = _payments.fold<double>(
      0.0,
      (runningTotal, d) => runningTotal + ((d['amount'] as num?)?.toDouble() ?? 0.0),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total earnings card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0E7C86), Color(0xFF17A2B8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0E7C86).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Earnings',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.payments_outlined, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${_payments.length} payment${_payments.length == 1 ? '' : 's'} received',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text(
          'Payment History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        if (_payments.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.payments_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  'No payments yet',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Payments will appear here once students enroll.',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._payments.map((d) {
            final paidAt = (d['paidAt'] as Timestamp?)?.toDate();
            final dateStr = paidAt != null
                ? '${paidAt.day.toString().padLeft(2, '0')}/'
                      '${paidAt.month.toString().padLeft(2, '0')}/'
                      '${paidAt.year}'
                : 'Processing...';
            final courseName = d['courseName'] ?? d['courseTitle'] ?? d['courseId'] ?? 'Course';
            final studentName = d['studentName'] ?? d['userName'] ?? 'Student';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 4),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F6F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: Color(0xFF0E7C86),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courseName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          studentName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${(d['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                    style: const TextStyle(
                      color: Color(0xFF0E7C86),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

