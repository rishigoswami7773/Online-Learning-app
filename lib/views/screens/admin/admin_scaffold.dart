import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_widgets.dart';
import '../../../utils/theme_helper.dart';
import 'admin_home_screen.dart';
import 'admin_manage_users_screen.dart';
import 'admin_user_approvals_screen.dart';
import 'admin_mentor_invites_screen.dart';
import 'admin_manage_courses_screen.dart';
import 'admin_content_upload_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_settings_screen.dart';

class AdminScaffold extends StatefulWidget {
  const AdminScaffold({super.key});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  int _selectedIndex = 0;

  final _pages = [
    const AdminHomeScreen(),
    const AdminManageUsersScreen(),
    const AdminUserApprovalsScreen(),
    const AdminMentorInvitesScreen(),
    const AdminManageCoursesScreen(),
    const AdminContentUploadScreen(),
    const AdminAnalyticsScreen(),
    const AdminSettingsScreen(),
  ];

  final _labels = [
    'Dashboard',
    'Users',
    'Approvals',
    'Mentor Invites',
    'Courses',
    'Upload',
    'Analytics',
    'Settings',
  ];

  final _icons = [
    Icons.dashboard,
    Icons.people,
    Icons.pending_actions,
    Icons.person_add,
    Icons.menu_book,
    Icons.cloud_upload,
    Icons.bar_chart,
    Icons.settings,
  ];

  void _openIndex(int i) => setState(() => _selectedIndex = i);

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Student Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .orderBy('createdAt', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = (snapshot.data?.docs ?? []).where((doc) {
                    final data = doc.data();
                    final targetRole = data['targetRole']?.toString();
                    return targetRole == null ||
                        targetRole.isEmpty ||
                        targetRole == 'admin';
                  }).toList();

                  if (docs.isNotEmpty) {
                    return ListView.builder(
                      controller: controller,
                      itemCount: docs.length,
                      itemBuilder: (context, idx) {
                        final data = docs[idx].data();
                        final title =
                            data['title']?.toString().isNotEmpty == true
                            ? data['title'].toString()
                            : (data['message']?.toString() ?? 'Notification');
                        final subtitle = data['message']?.toString() ?? '';
                        final ts =
                            (data['createdAt'] as Timestamp?)?.toDate() ??
                            (data['timestamp'] as Timestamp?)?.toDate();
                        final date = ts != null
                            ? '${ts.day}/${ts.month}/${ts.year}'
                            : '';

                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.notifications_none),
                          ),
                          title: Text(title),
                          subtitle: Text(
                            [
                              if (subtitle.isNotEmpty) subtitle,
                              if (date.isNotEmpty) date,
                            ].join('\n'),
                          ),
                        );
                      },
                    );
                  }

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('user_notifications')
                        .orderBy('createdAt', descending: true)
                        .limit(20)
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      final userDocs = userSnapshot.data?.docs ?? [];
                      if (userDocs.isNotEmpty) {
                        return ListView.builder(
                          controller: controller,
                          itemCount: userDocs.length,
                          itemBuilder: (context, idx) {
                            final data = userDocs[idx].data();
                            final title =
                                data['title']?.toString().isNotEmpty == true
                                ? data['title'].toString()
                                : (data['message']?.toString() ??
                                      'Notification');
                            final subtitle = data['message']?.toString() ?? '';
                            final ts =
                                (data['createdAt'] as Timestamp?)?.toDate() ??
                                (data['timestamp'] as Timestamp?)?.toDate();
                            final date = ts != null
                                ? '${ts.day}/${ts.month}/${ts.year}'
                                : '';

                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.notifications_none),
                              ),
                              title: Text(title),
                              subtitle: Text(
                                [
                                  if (subtitle.isNotEmpty) subtitle,
                                  if (date.isNotEmpty) date,
                                ].join('\n'),
                              ),
                            );
                          },
                        );
                      }

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('enrollments')
                            .orderBy('enrolledAt', descending: true)
                            .limit(10)
                            .snapshots(),
                        builder: (context, enrollSnapshot) {
                          if (!enrollSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final enrollDocs = enrollSnapshot.data!.docs;
                          if (enrollDocs.isEmpty) {
                            return const Center(
                              child: Text('No notifications'),
                            );
                          }

                          return ListView.builder(
                            controller: controller,
                            itemCount: enrollDocs.length,
                            itemBuilder: (context, idx) {
                              final data = enrollDocs[idx].data();
                              final student =
                                  data['studentName'] as String? ?? 'A student';
                              final course =
                                  data['courseTitle'] as String? ?? 'a course';
                              final ts = (data['enrolledAt'] as Timestamp?)
                                  ?.toDate();
                              final date = ts != null
                                  ? '${ts.day}/${ts.month}/${ts.year}'
                                  : '';

                              return ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(
                                  'New enrollment: $student enrolled in $course',
                                ),
                                subtitle: Text(date),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final user = FirebaseAuth.instance.currentUser;
        final displayName = user?.displayName ?? user?.email ?? 'Admin';
        final avatarText = displayName.trim().isEmpty
            ? 'A'
            : displayName
                  .trim()
                  .split(RegExp(r'\s+'))
                  .map((s) => s[0])
                  .take(2)
                  .join()
                  .toUpperCase();
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          // On narrow screens show AppBar and a bottom navigation like the student panel.
          appBar: isWide
              ? null
              : AppBar(
                  backgroundColor: Theme.of(context).cardColor,
                  foregroundColor: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color,
                  surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  centerTitle: false,
                  titleTextStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                  title: Text(_labels[_selectedIndex]),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AdminColors.brand,
                            AdminColors.brand.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('enrollments')
                          .where(
                            'enrolledAt',
                            isGreaterThanOrEqualTo: Timestamp.fromDate(
                              DateTime.now().subtract(const Duration(days: 7)),
                            ),
                          )
                          .snapshots(),
                      builder: (context, snapshot) {
                        final hasRecentEnrollments =
                            (snapshot.data?.docs.length ?? 0) > 0;
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                              ),
                              tooltip: 'Notifications',
                              onPressed: () => _showNotifications(context),
                            ),
                            if (hasRecentEnrollments)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      tooltip: 'Search',
                      onPressed: () {
                        showSearch(
                          context: context,
                          delegate: AdminSearchDelegate(),
                        );
                      },
                    ),
                  ],
                ),
          // Use a bottom NavigationBar for mobile/tablet to mirror student UX.
          bottomNavigationBar: isWide
              ? null
              : Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: context.borderColor, width: 1),
                    ),
                  ),
                  child: NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (int idx) => _openIndex(idx),
                    backgroundColor: context.surfaceColor,
                    indicatorColor: AdminColors.brandSoft,
                    height: 68,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: List.generate(_labels.length, (i) {
                      return NavigationDestination(
                        icon: Tooltip(
                          message: _labels[i],
                          child: Icon(
                            _icons[i],
                            color: i == _selectedIndex
                                ? AdminColors.brand
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        label: _labels[i],
                      );
                    }),
                  ),
                ),
          body: Row(
            children: [
              if (isWide)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      right: BorderSide(color: Color(0xFFE8EEF1), width: 1),
                    ),
                  ),
                  child: NavigationRail(
                    selectedIndex: _selectedIndex,
                    extended: constraints.maxWidth >= 1200,
                    minExtendedWidth: 220,
                    onDestinationSelected: _openIndex,
                    backgroundColor: Theme.of(context).cardColor,
                    minWidth: 72,
                    leading: Padding(
                      padding: const EdgeInsets.only(
                        top: 18.0,
                        left: 8,
                        right: 8,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AdminColors.brand,
                                  AdminColors.brandDark,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (constraints.maxWidth >= 1200)
                            Text(
                              'Admin',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    trailing: Padding(
                      padding: const EdgeInsets.only(
                        bottom: 16.0,
                        left: 10,
                        right: 10,
                      ),
                      child: Tooltip(
                        message: displayName,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AdminColors.brand,
                              child: Text(
                                avatarText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (constraints.maxWidth >= 1200) ...[
                              const SizedBox(height: 8),
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    selectedIconTheme: const IconThemeData(
                      color: AdminColors.brand,
                    ),
                    unselectedIconTheme: IconThemeData(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    selectedLabelTextStyle: const TextStyle(
                      color: AdminColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    indicatorColor: AdminColors.brandSoft,
                    destinations: List.generate(_labels.length, (i) {
                      return NavigationRailDestination(
                        icon: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: i == _selectedIndex
                                ? AdminColors.brand.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: i == _selectedIndex
                                ? const Border(
                                    left: BorderSide(
                                      color: AdminColors.brand,
                                      width: 4,
                                    ),
                                  )
                                : null,
                          ),
                          child: Icon(
                            _icons[i],
                            color: i == _selectedIndex
                                ? AdminColors.brand
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        label: Text(_labels[i]),
                      );
                    }),
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _pages[_selectedIndex],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AdminSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Search for "${query.isEmpty ? 'courses, users, staff...' : query}"',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = [
      'Courses',
      'Users',
      'Staff',
      'Approvals',
      'Analytics',
      'Reports',
    ].where((s) => s.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return adminListCard(
          child: InkWell(
            onTap: () {
              query = suggestions[index];
              showResults(context);
            },
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                const Icon(Icons.search, color: AdminColors.brand),
                const SizedBox(width: 12),
                Text(
                  suggestions[index],
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
