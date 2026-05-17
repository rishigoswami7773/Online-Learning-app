import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/theme_controller.dart';
import '../../../routes/app_routes.dart';
import '../admin/admin_manage_courses_new.dart';
import '../admin/admin_manage_users_new.dart';
import 'admin_payments_screen.dart';
import 'admin_widgets.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  int _selectedIndex = 0;

  bool _maintenanceMode = false;
  bool _kpiLoading = true;
  String? _kpiError;
  int _totalUsers = 0;
  int _students = 0;
  int _mentors = 0;
  int _totalCourses = 0;
  int _enrollments = 0;
  int _pendingUsers = 0;
  int _pendingCourses = 0;

  @override
  void initState() {
    super.initState();
    // Wait for auth to be ready before loading data
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _loadMaintenanceMode();
      _loadKpis();
    } else {
      FirebaseAuth.instance.authStateChanges().first.then((user) {
        if (user != null && mounted) {
          _loadMaintenanceMode();
          _loadKpis();
        }
      });
    }
  }

  Future<void> _loadKpis() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    setState(() => _kpiLoading = true);
    try {
      final results = await Future.wait([
        _fs.collection('users').count().get(),
        _fs
            .collection('users')
            .where('role', isEqualTo: 'student')
            .count()
            .get(),
        _fs
            .collection('users')
            .where('role', isEqualTo: 'mentor')
            .count()
            .get(),
        _fs.collection('courses').count().get(),
        _fs.collection('enrollments').count().get(),
        _fs
            .collection('users')
            .where('status', isEqualTo: 'pending')
            .count()
            .get(),
        _fs
            .collection('courses')
            .where('status', isEqualTo: 'pending')
            .count()
            .get(),
      ]);

      if (!mounted) return;
      setState(() {
        _totalUsers = results[0].count ?? 0;
        _students = results[1].count ?? 0;
        _mentors = results[2].count ?? 0;
        _totalCourses = results[3].count ?? 0;
        _enrollments = results[4].count ?? 0;
        _pendingUsers = results[5].count ?? 0;
        _pendingCourses = results[6].count ?? 0;
        _kpiLoading = false;
        _kpiError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _kpiLoading = false;
        _kpiError = e.toString();
      });
    }
  }

  Future<void> _loadMaintenanceMode() async {
    try {
      final snap = await _fs.doc('settings/platform').get();
      if (!mounted) return;
      final mode = (snap.data() ?? {})['maintenanceMode'] as bool? ?? false;
      setState(() => _maintenanceMode = mode);
    } catch (_) {}
  }

  Future<void> _toggleMaintenance(bool value) async {
    setState(() => _maintenanceMode = value);
    try {
      await _fs.doc('settings/platform').set({
        'maintenanceMode': value,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, Admin 👋';
    if (hour < 18) return 'Good afternoon, Admin 👋';
    return 'Good evening, Admin 👋';
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    final date = timestamp.toDate().toLocal();
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: theme.cardColor,
        child: SizedBox(
          height: 120,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _alertBadge(String label, int count, Color color, VoidCallback onTap) {
    if (count == 0) return const SizedBox.shrink();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.16),
              color.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ShakeWidget(
                  duration: const Duration(milliseconds: 500),
                  shakeCount: 3,
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: color,
                    size: 18,
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: PulseDot(color: color, size: 8),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count $label',
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: color),
          ],
        ),
      ),
    );
  }

  Widget _dashboardBody() {
    return RefreshIndicator(
      onRefresh: _loadKpis,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          adminHeroHeader(
            title: _getGreeting(),
            subtitle: 'Today is ${DateTime.now().toString().split(' ')[0]}',
            actions: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _alertBadge(
            'users pending approval',
            _pendingUsers,
            Colors.orange,
            () => context.go(AppRoutes.adminApprovals),
          ),
          _alertBadge(
            'courses awaiting review',
            _pendingCourses,
            Colors.deepOrange,
            () => context.go(AppRoutes.adminCourses),
          ),
          adminSectionHeader('Platform Overview'),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _kpiError != null
                ? Column(
                    key: const ValueKey('kpi-error'),
                    children: [
                      SizedBox(
                        height: 200,
                        child: Center(
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
                                  'Error loading platform stats: $_kpiError',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _loadKpis,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : _kpiLoading
                ? GridView.count(
                    key: const ValueKey('kpi-loading'),
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: List.generate(
                      4,
                      (index) => ShimmerBox(
                        width: double.infinity,
                        height: 120,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  )
                : GridView.count(
                    key: const ValueKey('kpi-ready'),
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      StaggeredItem(
                        delay: const Duration(milliseconds: 0),
                        child: _buildStatCard(
                          'Total Users',
                          _totalUsers.toString(),
                          Icons.people_alt,
                          AdminColors.brand,
                          onTap: () => context.push(AppRoutes.adminUsers),
                        ),
                      ),
                      StaggeredItem(
                        delay: const Duration(milliseconds: 80),
                        child: _buildStatCard(
                          'Students',
                          _students.toString(),
                          Icons.school,
                          AdminColors.accent,
                          onTap: () => context.push(AppRoutes.adminUsers),
                        ),
                      ),
                      StaggeredItem(
                        delay: const Duration(milliseconds: 160),
                        child: _buildStatCard(
                          'Mentors',
                          _mentors.toString(),
                          Icons.person_pin,
                          Colors.teal,
                          onTap: () => context.push(AppRoutes.adminMentorPanel),
                        ),
                      ),
                      StaggeredItem(
                        delay: const Duration(milliseconds: 240),
                        child: _buildStatCard(
                          'Courses',
                          _totalCourses.toString(),
                          Icons.menu_book,
                          AdminColors.brand,
                          onTap: () => context.push(AppRoutes.adminCourses),
                        ),
                      ),
                      StaggeredItem(
                        delay: const Duration(milliseconds: 320),
                        child: _buildStatCard(
                          'Enrollments',
                          _enrollments.toString(),
                          Icons.how_to_reg,
                          const Color(0xFF6F42C1),
                          onTap: () => context.push(AppRoutes.adminEnrollments),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          adminSectionHeader('Manage'),
          Column(
            children: [
              StaggeredItem(
                delay: const Duration(milliseconds: 0),
                child: _NavCard(
                  icon: Icons.people_outline,
                  title: 'Users & Accounts',
                  subtitle: 'Block, approve, assign roles',
                  onTap: () => context.go(AppRoutes.adminUsers),
                  borderColor: Colors.blue,
                  index: 0,
                ),
              ),
              const SizedBox(height: 8),
              StaggeredItem(
                delay: const Duration(milliseconds: 50),
                child: _NavCard(
                  icon: Icons.menu_book_outlined,
                  title: 'Courses',
                  subtitle: 'Approve, publish, or remove content',
                  onTap: () => context.go(AppRoutes.adminCourses),
                  borderColor: AdminColors.brand,
                  index: 1,
                ),
              ),
              const SizedBox(height: 8),
              StaggeredItem(
                delay: const Duration(milliseconds: 100),
                child: _NavCard(
                  icon: Icons.analytics_outlined,
                  title: 'Analytics',
                  subtitle: 'Platform-wide statistics',
                  onTap: () => context.go(AppRoutes.adminAnalytics),
                  borderColor: Colors.purple,
                  index: 2,
                ),
              ),
              const SizedBox(height: 8),
              StaggeredItem(
                delay: const Duration(milliseconds: 150),
                child: _NavCard(
                  icon: Icons.history,
                  title: 'Activity Log',
                  subtitle: 'View all admin and user actions',
                  onTap: () => context.go(AppRoutes.adminActivity),
                  borderColor: Colors.orange,
                  index: 3,
                ),
              ),
              const SizedBox(height: 8),
              StaggeredItem(
                delay: const Duration(milliseconds: 200),
                child: _NavCard(
                  icon: Icons.category_outlined,
                  title: 'Categories',
                  subtitle: 'Manage course categories',
                  onTap: () => context.go(AppRoutes.adminManageCategories),
                  borderColor: Colors.green,
                  index: 4,
                ),
              ),
              const SizedBox(height: 8),
              StaggeredItem(
                delay: const Duration(milliseconds: 250),
                child: _NavCard(
                  icon: Icons.star_outline,
                  title: 'Reviews',
                  subtitle: 'Moderate course reviews',
                  onTap: () => context.go(AppRoutes.adminManageReviews),
                  borderColor: Colors.amber,
                  index: 5,
                ),
              ),
              const SizedBox(height: 8),
              StaggeredItem(
                delay: const Duration(milliseconds: 300),
                child: _NavCard(
                  icon: Icons.notifications_active_outlined,
                  title: 'Send Notification',
                  subtitle: 'Broadcast message to students or mentors',
                  onTap: () => context.go(AppRoutes.adminSendNotification),
                  borderColor: Colors.deepPurple,
                  index: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _maintenanceMode
                  ? Colors.orange.withValues(alpha: 0.08)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _maintenanceMode
                    ? Colors.orange.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ShakeWidget(
                        duration: const Duration(milliseconds: 500),
                        shakeCount: 3,
                        child: const Icon(
                          Icons.build_outlined,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    const Positioned(
                      right: -2,
                      top: -2,
                      child: PulseDot(color: Colors.red, size: 8),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maintenance Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Disables access for non-admin users',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _maintenanceMode,
                  activeThumbColor: AdminColors.brand,
                  activeTrackColor: AdminColors.brand.withValues(alpha: 0.35),
                  onChanged: _toggleMaintenance,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          adminSectionHeader('Recent Enrollments'),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _fs.collection('enrollments').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              docs.sort((a, b) {
                final aDate =
                    (a.data()['enrolledAt'] as Timestamp?)?.toDate() ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                final bDate =
                    (b.data()['enrolledAt'] as Timestamp?)?.toDate() ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                return bDate.compareTo(aDate);
              });

              final limited = docs.take(5).toList();
              if (limited.isEmpty) {
                return Text(
                  'No recent enrollments.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                );
              }

              return Column(
                children: [
                  ...limited.asMap().entries.map((entry) {
                    final index = entry.key;
                    final doc = entry.value;
                    final data = doc.data();
                    final studentId = (data['studentId'] as String?) ?? '';
                    final fallbackName =
                        (data['studentName'] as String?) ?? 'Student';
                    final course = (data['courseTitle'] as String?) ?? 'Course';
                    final timestamp = data['enrolledAt'] as Timestamp?;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: StaggeredItem(
                        delay: Duration(milliseconds: index * 60),
                        child: adminListCard(
                          child:
                              FutureBuilder<
                                DocumentSnapshot<Map<String, dynamic>>?
                              >(
                                future: studentId.isNotEmpty
                                    ? _fs
                                          .collection('users')
                                          .doc(studentId)
                                          .get()
                                    : Future<
                                        DocumentSnapshot<Map<String, dynamic>>?
                                      >.value(null),
                                builder: (context, userSnap) {
                                  final resolvedName = userSnap.data
                                      ?.data()?['name']
                                      ?.toString();
                                  final student =
                                      (resolvedName != null &&
                                          resolvedName.isNotEmpty)
                                      ? resolvedName
                                      : fallbackName;
                                  return Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              AdminColors.brand,
                                              AdminColors.accent,
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            student.isNotEmpty
                                                ? student[0].toUpperCase()
                                                : 'S',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                            Text(
                                              course,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        _formatDate(timestamp),
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                        ),
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.adminUsers),
                      child: const Text('View All'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dashboardTab() {
    return Stack(
      children: [
        _dashboardBody(),
        Positioned(
          top: 12,
          right: 12,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.person_outline),
                color: Theme.of(context).colorScheme.onSurface,
                onPressed: () => context.go(AppRoutes.adminProfile),
                tooltip: 'Profile',
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onSelected: (value) async {
                  if (value == 'logout') {
                    await AuthController().logout();
                    if (!mounted) return;
                    context.go(AppRoutes.login);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'logout', child: Text('Sign Out')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
      children: [
        // Admin profile header card
        Builder(
          builder: (context) {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid == null || uid.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0E7C86), Color(0xFF17A2B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get(),
              builder: (context, snap) {
                final data = snap.data?.data() ?? {};
                final name = (data['name'] ?? 'Admin').toString();
                final email =
                    (data['email'] ??
                            FirebaseAuth.instance.currentUser?.email ??
                            '')
                        .toString();
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0E7C86), Color(0xFF17A2B8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white24,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Administrator',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: 24),

        // Account section
        _sectionLabel('Account', context),
        _settingsTile(
          icon: Icons.person_outline,
          title: 'My Profile',
          subtitle: 'View and edit your admin profile',
          onTap: () => context.go(AppRoutes.adminProfile),
        ),
        const SizedBox(height: 8),
        _settingsTile(
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update your login password',
          onTap: () => context.go(AppRoutes.changePassword),
        ),

        const SizedBox(height: 20),

        // App section
        _sectionLabel('App', context),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController().mode,
          builder: (context, mode, _) => _settingsTile(
            icon: mode == ThemeMode.dark
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
            title: 'Dark Mode',
            subtitle: mode == ThemeMode.dark
                ? 'Dark theme active'
                : 'Light theme active',
            trailing: Switch.adaptive(
              value: mode == ThemeMode.dark,
              activeThumbColor: AdminColors.brand,
              onChanged: (_) => ThemeController().toggle(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _settingsTile(
          icon: Icons.build_outlined,
          title: 'Maintenance Mode',
          subtitle: _maintenanceMode
              ? '⚠ Currently ON — app is in maintenance'
              : 'Currently OFF — app is live',
          trailing: Switch.adaptive(
            value: _maintenanceMode,
            activeThumbColor: AdminColors.brand,
            onChanged: (v) async {
              setState(() => _maintenanceMode = v);
              await FirebaseFirestore.instance
                  .collection('settings')
                  .doc('maintenance')
                  .set({'enabled': v});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      v ? 'Maintenance mode ON' : 'Maintenance mode OFF',
                    ),
                  ),
                );
              }
            },
          ),
        ),

        const SizedBox(height: 20),

        // Danger zone
        _sectionLabel('Account Actions', context),
        _settingsTile(
          icon: Icons.logout,
          title: 'Sign Out',
          subtitle: 'Log out of the admin panel',
          color: Colors.red,
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Sign Out?'),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await AuthController().logout();
              if (!mounted) return;
              context.go(AppRoutes.login);
            }
          },
        ),

        const SizedBox(height: 32),

        // App version footer
        Center(
          child: Text(
            'Learnify Admin v1.0.0',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '© 2025 Learnify. All rights reserved.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
          ),
        ),
      ],
    );
  }

  // Section label helper
  Widget _sectionLabel(String label, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Settings tile helper — update existing _settingsTile() to add
  // badge param:
  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
    String? badge,
  }) {
    return Builder(
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (color ?? AdminColors.brand).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color ?? AdminColors.brand, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          trailing:
              trailing ??
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = [
      _dashboardTab(),
      const AdminManageUsersScreenNew(),
      const AdminManageCoursesScreenNew(),
      const AdminPaymentsScreen(),
      _settingsTab(),
    ];

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
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: IndexedStack(index: _selectedIndex, children: pages),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AdminColors.brand,
          unselectedItemColor: theme.colorScheme.onSurface.withValues(
            alpha: 0.6,
          ),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 12,
          backgroundColor: theme.colorScheme.surface,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Courses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payments_outlined),
              activeIcon: Icon(Icons.payments),
              label: 'Payments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? borderColor;
  final int index;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.borderColor,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: const AlwaysStoppedAnimation(Offset.zero),
      child: adminQuickActionCard(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        borderColor: borderColor,
      ),
    );
  }
}
