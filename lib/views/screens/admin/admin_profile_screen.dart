import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/app_auth_controller.dart';
import '../../../controllers/theme_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/uid_resolver.dart';
import '../../../utils/theme_helper.dart';

const Color _mentorTeal = Color(0xFF0E7C86);

void _safeBackToAdminDashboard(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.adminHome);
  }
}

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = UidResolver.uid;
      if (uid == null && mounted) {
        context.go(AppRoutes.login);
      }
    });
  }

  int _reloadToken = 0;

  Future<DocumentSnapshot<Map<String, dynamic>>> _loadProfile(
    String uid,
  ) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    final snap = await ref.get().timeout(const Duration(seconds: 10));
    if (!snap.exists) {
      await ref.set({
        'uid': uid,
        'email': AppAuthController().currentUser.value?.email ?? '',
        'name': AppAuthController().currentUser.value?.name ?? '',
        'bio': '',
        'role': 'mentor',
        'isVerified': true,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.get().timeout(const Duration(seconds: 10));
    }
    return snap;
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'M';
    if (parts.length == 1) {
      return parts.first.isEmpty ? 'M' : parts.first[0].toUpperCase();
    }
    final first = parts.first.isEmpty ? 'M' : parts.first[0].toUpperCase();
    final last = parts.last.isEmpty ? 'M' : parts.last[0].toUpperCase();
    return '$first$last';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  Future<void> _editProfile(Map<String, dynamic> currentData) async {
    final nameController = TextEditingController(
      text: (currentData['name'] as String?) ?? '',
    );
    final bioController = TextEditingController(
      text: (currentData['bio'] as String?) ?? '',
    );
    final expertiseController = TextEditingController(
      text: (currentData['expertise'] as String?) ?? '',
    );

    final sheetBg = context.surfaceColor;
    final titleColor = context.textPrimary;

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 16),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: titleColor),
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: expertiseController,
                        decoration: const InputDecoration(
                          labelText: 'Expertise',
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          prefixIcon: Icon(Icons.info_outline),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _mentorTeal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.of(sheetContext).pop(true),
                          child: const Text('Save Changes'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldSave != true) return;
    if (!mounted) return;

    final uid = UidResolver.uid;
    if (uid == null) {
      context.go(AppRoutes.login);
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': nameController.text.trim(),
      'bio': bioController.text.trim(),
      'expertise': expertiseController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    setState(() => _reloadToken++);
  }

  @override
  Widget build(BuildContext context) {
    final uid = UidResolver.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _safeBackToAdminDashboard(context);
      },
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        key: ValueKey(_reloadToken),
        future: _loadProfile(uid).timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw TimeoutException('Could not load data'),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: _ProfileErrorState(
                message: snapshot.error is TimeoutException
                    ? 'Profile load timed out. Please try again.'
                    : 'Unable to load profile: ${snapshot.error}',
                onRetry: () => setState(() => _reloadToken++),
              ),
            );
          }

          final data = snapshot.data?.data() ?? <String, dynamic>{};
          final name = (data['name'] as String?)?.trim().isNotEmpty == true
              ? (data['name'] as String).trim()
              : (AppAuthController().currentUser.value?.name ?? 'Mentor');
          final email = (data['email'] as String?)?.trim().isNotEmpty == true
              ? (data['email'] as String).trim()
              : (AppAuthController().currentUser.value?.email ?? '');
          final bio = (data['bio'] as String?)?.trim() ?? '';
          final expertise = (data['expertise'] as String?)?.trim() ?? '';
          final isVerified = (data['isVerified'] as bool?) ?? false;
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

          // Theme-aware colors
          final scaffoldBg = context.bgColor;
          final cardBg = context.cardColor;
          final titleColor = context.textPrimary;
          final subtitleColor = context.textSecondary;
          final dividerColor = context.dividerColor;
          final cardBorder = context.borderColor;

          return Scaffold(
            backgroundColor: scaffoldBg,
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: _mentorTeal,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_mentorTeal, Color(0xFF0B5D66)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: Colors.white24,
                              child: Text(
                                _initials(name),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                '✦ Mentor',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      _safeBackToAdminDashboard(context);
                    },
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // About Section
                          _ProfileCard(
                            bg: cardBg,
                            border: cardBorder,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  bio.isEmpty ? 'No bio added yet.' : bio,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: subtitleColor,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () => _editProfile(data),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit Profile'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _mentorTeal,
                                    side: const BorderSide(color: _mentorTeal),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Expertise & Details Section
                          _ProfileCard(
                            bg: cardBg,
                            border: cardBorder,
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Expertise & Details',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: titleColor,
                                      ),
                                    ),
                                  ),
                                ),
                                _ProfileListTile(
                                  icon: Icons.email_outlined,
                                  label: 'Email',
                                  value: email,
                                  titleColor: titleColor,
                                  subtitleColor: subtitleColor,
                                ),
                                Divider(color: dividerColor, height: 1),
                                _ProfileListTile(
                                  icon: Icons.work_outline,
                                  label: 'Expertise',
                                  value: expertise.isEmpty
                                      ? 'Not specified'
                                      : expertise,
                                  titleColor: titleColor,
                                  subtitleColor: subtitleColor,
                                ),
                                Divider(color: dividerColor, height: 1),
                                _ProfileListTile(
                                  icon: Icons.calendar_today_outlined,
                                  label: 'Joined',
                                  value: 'Joined ${_formatDate(createdAt)}',
                                  titleColor: titleColor,
                                  subtitleColor: subtitleColor,
                                ),
                                if (isVerified) ...[
                                  Divider(color: dividerColor, height: 1),
                                  _ProfileListTile(
                                    icon: Icons.verified_outlined,
                                    label: 'Status',
                                    value: 'Verified Mentor',
                                    titleColor: _mentorTeal,
                                    subtitleColor: subtitleColor,
                                    valueColor: _mentorTeal,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Quick Actions
                          Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            children: [
                              _QuickActionCard(
                                icon: Icons.menu_book_rounded,
                                label: 'My Courses',
                                cardBg: cardBg,
                                cardBorder: cardBorder,
                                titleColor: titleColor,
                                onTap: () =>
                                    context.push(AppRoutes.mentorManageCourses),
                              ),
                              _QuickActionCard(
                                icon: Icons.upload_file_rounded,
                                label: 'Upload Content',
                                cardBg: cardBg,
                                cardBorder: cardBorder,
                                titleColor: titleColor,
                                onTap: () =>
                                    context.push(AppRoutes.mentorUpload),
                              ),
                              _QuickActionCard(
                                icon: Icons.people_rounded,
                                label: 'Enrolled Students',
                                cardBg: cardBg,
                                cardBorder: cardBorder,
                                titleColor: titleColor,
                                onTap: () =>
                                    context.push(AppRoutes.mentorStudents),
                              ),
                              _QuickActionCard(
                                icon: Icons.star_rounded,
                                label: 'Ratings & Reviews',
                                cardBg: cardBg,
                                cardBorder: cardBorder,
                                titleColor: titleColor,
                                onTap: () =>
                                    context.push(AppRoutes.mentorRatings),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Account Section
                          _ProfileCard(
                            bg: cardBg,
                            border: cardBorder,
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: titleColor,
                                      ),
                                    ),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.lock_outline,
                                    color: _mentorTeal,
                                  ),
                                  title: Text(
                                    'Change Password',
                                    style: TextStyle(color: titleColor),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: subtitleColor,
                                  ),
                                  onTap: () =>
                                      context.push(AppRoutes.changePassword),
                                ),
                                Divider(color: dividerColor, height: 1),
                                ValueListenableBuilder<ThemeMode>(
                                  valueListenable: ThemeController().mode,
                                  builder: (context, mode, _) {
                                    final isDark = mode == ThemeMode.dark;
                                    return ListTile(
                                      leading: Icon(
                                        isDark
                                            ? Icons.dark_mode
                                            : Icons.light_mode_outlined,
                                        color: _mentorTeal,
                                      ),
                                      title: Text(
                                        'Dark Mode',
                                        style: TextStyle(color: titleColor),
                                      ),
                                      trailing: Switch(
                                        value: isDark,
                                        activeThumbColor: _mentorTeal,
                                        onChanged: (_) =>
                                            ThemeController().toggle(),
                                      ),
                                    );
                                  },
                                ),
                                Divider(color: dividerColor, height: 1),
                                ListTile(
                                  leading: const Icon(
                                    Icons.logout,
                                    color: Colors.red,
                                  ),
                                  title: const Text(
                                    'Sign Out',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.red,
                                  ),
                                  onTap: () async {
                                    await AppAuthController().signOut();
                                    if (context.mounted) {
                                      context.go(AppRoutes.login);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Reusable card widget
class _ProfileCard extends StatelessWidget {
  final Widget child;
  final Color bg;
  final Color border;
  final EdgeInsets? padding;
  const _ProfileCard({
    required this.child,
    required this.bg,
    required this.border,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

// Reusable list tile
class _ProfileListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color titleColor;
  final Color subtitleColor;
  final Color? valueColor;
  const _ProfileListTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.titleColor,
    required this.subtitleColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: _mentorTeal),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: subtitleColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: valueColor ?? titleColor,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color cardBg;
  final Color cardBorder;
  final Color titleColor;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.cardBg,
    required this.cardBorder,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _mentorTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _mentorTeal, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
