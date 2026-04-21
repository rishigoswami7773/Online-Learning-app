import 'package:flutter/material.dart';
import 'admin_home_screen.dart';
import 'admin_manage_users_screen.dart';
import 'admin_user_approvals_screen.dart';
import 'admin_staff_invites_screen.dart';
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
    const AdminStaffInvitesScreen(),
    const AdminManageCoursesScreen(),
    const AdminContentUploadScreen(),
    const AdminAnalyticsScreen(),
    const AdminSettingsScreen(),
  ];

  final _labels = [
    'Dashboard',
    'Users',
    'Approvals',
    'Staff Invites',
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: isWide
              ? null
              : AppBar(
                  title: Text(_labels[_selectedIndex]),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {},
                    ),
                  ],
                ),
          drawer: isWide
              ? null
              : Drawer(
                  child: SafeArea(
                    child: Column(
                      children: [
                        const ListTile(
                          leading: CircleAvatar(
                            child: Icon(Icons.admin_panel_settings),
                          ),
                          title: Text('Admin'),
                          subtitle: Text('Online Learning'),
                        ),
                        const Divider(),
                        ...List.generate(_labels.length, (i) {
                          return ListTile(
                            leading: Icon(_icons[i]),
                            title: Text(_labels[i]),
                            selected: i == _selectedIndex,
                            onTap: () {
                              Navigator.pop(context);
                              _openIndex(i);
                            },
                          );
                        }),
                        const Spacer(),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Sign out'),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
          body: Row(
            children: [
              if (isWide)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  extended: constraints.maxWidth >= 1200,
                  onDestinationSelected: _openIndex,
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: const [
                        CircleAvatar(
                          radius: 22,
                          child: Icon(Icons.admin_panel_settings),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                  destinations: List.generate(_labels.length, (i) {
                    return NavigationRailDestination(
                      icon: Icon(_icons[i]),
                      label: Text(_labels[i]),
                    );
                  }),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
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
