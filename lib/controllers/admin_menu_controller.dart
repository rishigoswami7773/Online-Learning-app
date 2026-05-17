import 'package:flutter/material.dart';

/// Admin Menu Item
class AdminMenuItem {
  final String label;
  final IconData icon;
  final String route;
  final String? tooltip;
  final bool requiresSpecialAccess;

  const AdminMenuItem({
    required this.label,
    required this.icon,
    required this.route,
    this.tooltip,
    this.requiresSpecialAccess = false,
  });
}

/// Controller to manage admin panel menu items and navigation
class AdminMenuController {
  static final AdminMenuController _instance = AdminMenuController._internal();

  factory AdminMenuController() {
    return _instance;
  }

  AdminMenuController._internal();

  /// All available admin menu items
  static const List<AdminMenuItem> adminMenuItems = [
    AdminMenuItem(
      label: 'Dashboard',
      icon: Icons.dashboard,
      route: '/admin_dashboard',
      tooltip: 'View admin dashboard',
    ),
    AdminMenuItem(
      label: 'Users',
      icon: Icons.people,
      route: '/admin_users',
      tooltip: 'Manage all users',
    ),
    AdminMenuItem(
      label: 'Approvals',
      icon: Icons.pending_actions,
      route: '/admin_approvals',
      tooltip: 'Approve pending users',
    ),
    AdminMenuItem(
      label: 'Staff Invites',
      icon: Icons.person_add,
      route: '/admin_staff_invites',
      tooltip: 'Manage staff invitations',
    ),
    AdminMenuItem(
      label: 'Courses',
      icon: Icons.menu_book,
      route: '/admin_courses',
      tooltip: 'Manage courses',
    ),
    AdminMenuItem(
      label: 'Content',
      icon: Icons.video_library,
      route: '/admin_upload',
      tooltip: 'Upload and manage content',
    ),
    AdminMenuItem(
      label: 'Analytics',
      icon: Icons.bar_chart,
      route: '/admin_analytics',
      tooltip: 'View analytics and reports',
    ),
    AdminMenuItem(
      label: 'Reviews',
      icon: Icons.rate_review,
      route: '/admin_manage_reviews',
      tooltip: 'Manage course reviews',
    ),
    AdminMenuItem(
      label: 'Notifications',
      icon: Icons.notifications,
      route: '/admin',
      tooltip: 'Manage notifications',
    ),
    AdminMenuItem(
      label: 'Settings',
      icon: Icons.settings,
      route: '/admin_settings',
      tooltip: 'System settings',
    ),
  ];

  /// Get menu items for current admin level
  List<AdminMenuItem> getMenuItems(String adminLevel) {
    // Super admin has access to all items
    if (adminLevel == 'superadmin') {
      return adminMenuItems;
    }

    // Regular admin might have limited access
    if (adminLevel == 'admin') {
      return adminMenuItems.where((item) => !item.requiresSpecialAccess).toList();
    }

    return [];
  }

  /// Get menu item by route
  AdminMenuItem? getMenuItemByRoute(String route) {
    try {
      return adminMenuItems.firstWhere((item) => item.route == route);
    } catch (e) {
      return null;
    }
  }

  /// Get menu index by route for highlighting
  int getMenuIndexByRoute(String route) {
    return adminMenuItems.indexWhere((item) => item.route == route);
  }
}
