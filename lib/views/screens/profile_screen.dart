import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:online_learning_app/controllers/theme_controller.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import 'package:online_learning_app/controllers/app_auth_controller.dart';
import 'package:online_learning_app/controllers/auth_controller.dart';
import 'package:online_learning_app/theme/app_theme.dart';
import '../../utils/theme_helper.dart';

import '../../controllers/profile_controller.dart';
import '../../models/user_model.dart';
import '../../services/payment_service.dart';

void _safeBackToStudentDashboard(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.studentDashboard);
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ImageProvider? _avatarProvider(String path) {
    final normalized = path.trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return NetworkImage(normalized);
    }
    final file = File(normalized);
    if (!file.existsSync()) {
      return null;
    }
    return FileImage(file);
  }

  final _appAuth = AppAuthController();
  final _profileController = ProfileController();
  bool _isLoggingOut = false;
  bool _isDeleting = false;
  bool _isUploadingAvatar = false;

  String _asText(dynamic value, {String fallback = '-'}) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  DateTime? _toDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }

  String _formatDate(DateTime? value, {String fallback = '-'}) {
    if (value == null) {
      return fallback;
    }
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  Future<void> _openEditProfile({
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic>? studentProfile,
  }) async {
    context.push(
      AppRoutes.editProfile,
      extra: {'userProfile': userProfile, 'studentProfile': studentProfile},
    );
  }

  Future<void> _pickAndUpdateProfilePicture() async {
    if (_isUploadingAvatar) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.first.path;
      if (filePath == null || filePath.isEmpty) return;

      setState(() => _isUploadingAvatar = true);
      await _profileController.uploadProfileImageFromPath(filePath: filePath);

      final auth = AppAuthController();
      final current = auth.currentUser.value;
      if (current != null) {
        auth.currentUser.value = AppUser(
          uid: current.uid,
          email: current.email,
          name: current.name,
          role: current.role,
          profileImage: filePath,
          password: current.password,
        );
      }

      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update picture: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() => _isLoggingOut = true);

    await AuthController().logout();
    if (!mounted) return;
    setState(() => _isLoggingOut = false);
    if (context.mounted) context.go(AppRoutes.login);
  }

  Future<void> _confirmDeleteAccount() async {
    if (_isDeleting) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.surfaceColor,
        title: const Text('Delete account?'),
        content: const Text(
          'This action permanently deletes your account and profile data.',
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => dialogContext.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    setState(() => _isDeleting = true);
    try {
      final appUser = _appAuth.currentUser.value;
      if (appUser != null && appUser.uid.toString().startsWith('demo-')) {
        await AuthController().logout();
        if (!mounted) return;
        setState(() => _isDeleting = false);
        if (context.mounted) context.go(AppRoutes.login);
        return;
      }

      await _profileController.deleteUserAccount();
      await AuthController().logout();
      if (!mounted) return;
      setState(() => _isDeleting = false);
      if (context.mounted) context.go(AppRoutes.login);
    } catch (e) {
      setState(() => _isDeleting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  List<String> _courseList({
    required Map<String, dynamic> profile,
    required Map<String, dynamic>? studentProfile,
  }) {
    final raw =
        profile['selectedCourses'] ?? studentProfile?['courses'] ?? const [];
    if (raw is! List) {
      return <String>[];
    }
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Widget _buildProfileBody({
    required Map<String, dynamic> profile,
    required Map<String, dynamic>? studentProfile,
  }) {
    final name = _asText(profile['name'], fallback: 'Unknown');
    final email = _asText(profile['email'], fallback: 'Unknown');
    final phone = _asText(profile['phone']);
    final role = _asText(profile['role'], fallback: 'student');
    final profileImage = _asText(profile['profileImage'], fallback: '');

    final preferences = Map<String, dynamic>.from(
      studentProfile?['preferences'] as Map? ?? const <String, dynamic>{},
    );
    final location = Map<String, dynamic>.from(
      preferences['location'] as Map? ?? const <String, dynamic>{},
    );
    final dob = _toDate(profile['dob']) ?? _toDate(studentProfile?['dob']);
    final gender = _asText(
      profile['gender'],
      fallback: _asText(studentProfile?['gender']),
    );

    final city = _asText(profile['city'], fallback: _asText(location['city']));
    final state = _asText(
      profile['state'],
      fallback: _asText(location['state']),
    );
    final country = _asText(
      profile['country'],
      fallback: _asText(location['country']),
    );

    final educationLevel = _asText(studentProfile?['educationLevel']);
    final classYear = _asText(studentProfile?['classYear']);
    final stream = _asText(studentProfile?['stream']);

    final languagePreference = _asText(
      profile['languagePreference'],
      fallback: _asText(preferences['languagePreference']),
    );
    final learningGoals = _asText(
      profile['learningGoals'],
      fallback: _asText(
        studentProfile?['learningGoals'],
        fallback: _asText(preferences['learningGoal']),
      ),
    );
    final selectedCourses = _courseList(
      profile: profile,
      studentProfile: studentProfile,
    );
    final createdAt = _toDate(profile['createdAt']);
    final uid = _appAuth.currentUser.value?.uid ?? '';

    return CustomScrollView(
      slivers: [
        // Hero Profile Header
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.brand, AppColors.brandDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(0),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: context.surfaceColor,
                      backgroundImage: _avatarProvider(profileImage),
                      child: profileImage.isEmpty
                          ? Text(
                              name.isEmpty
                                  ? 'U'
                                  : name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brand,
                              ),
                            )
                          : null,
                    ),
                    GestureDetector(
                      onTap: _isUploadingAvatar ? null : _pickAndUpdateProfilePicture,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          shape: BoxShape.circle,
                        ),
                        child: _isUploadingAvatar
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(
                                Icons.edit,
                                size: 16,
                                color: AppColors.brand,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Stats Row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStatsRow(uid),
          ),
        ),

        // Info Sections
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCollapsibleSection(
                  icon: Icons.person_outline,
                  title: 'Personal Details',
                  children: [
                    _buildInfoTile('Phone', phone),
                    _buildInfoTile('Date of Birth', _formatDate(dob)),
                    _buildInfoTile('Gender', gender),
                    _buildInfoTile('City', city),
                    _buildInfoTile('State', state),
                    _buildInfoTile('Country', country),
                  ],
                ),
                const SizedBox(height: 12),
                if (role.toLowerCase() == 'student')
                  Column(
                    children: [
                      _buildCollapsibleSection(
                        icon: Icons.school_rounded,
                        title: 'Academic Details',
                        children: [
                          _buildInfoTile('Education Level', educationLevel),
                          _buildInfoTile('Class / Year', classYear),
                          _buildInfoTile('Stream / Field', stream),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                _buildCollapsibleSection(
                  icon: Icons.tune,
                  title: 'Preferences',
                  children: [
                    _buildInfoTile('Language', languagePreference),
                    _buildInfoTile('Learning Goals', learningGoals),
                    if (selectedCourses.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Selected Courses',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: selectedCourses
                            .map(
                              (course) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.brandSoft,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  course,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.brand,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
                _buildCollapsibleSection(
                  icon: Icons.info_outline,
                  title: 'Account Info',
                  children: [
                    _buildInfoTile('Role', role.toLowerCase()),
                    _buildInfoTile('Account Created', _formatDate(createdAt)),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // Settings & Actions Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: context.cardColor,
              child: Column(
                children: [
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeController().mode,
                    builder: (context, mode, _) => SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      secondary: Icon(
                        mode == ThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: AppColors.brand,
                      ),
                      title: const Text('Dark Mode'),
                      value: mode == ThemeMode.dark,
                      onChanged: (_) => ThemeController().toggle(),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildActionListTile(
                    icon: Icons.edit_rounded,
                    label: 'Edit Profile',
                    onTap: () => _openEditProfile(
                      userProfile: profile,
                      studentProfile: studentProfile,
                    ),
                    color: AppColors.brand,
                  ),
                  const Divider(height: 1),
                  _buildActionListTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Change Password',
                    onTap: () => context.push(AppRoutes.changePassword),
                    color: AppColors.brand,
                  ),
                  const Divider(height: 1),
                  _buildActionListTile(
                    icon: Icons.logout_rounded,
                    label: _isLoggingOut ? 'Logging out...' : 'Logout',
                    onTap: _isLoggingOut ? null : _logout,
                    color: Colors.orange,
                  ),
                  const Divider(height: 1),
                  _buildActionListTile(
                    icon: Icons.delete_forever_outlined,
                    label: _isDeleting ? 'Deleting...' : 'Delete Account',
                    onTap: _isDeleting ? null : _confirmDeleteAccount,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: StreamBuilder<QuerySnapshot>(
            stream: PaymentService.getPaymentHistory(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'My Purchases',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (docs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: context.borderColor,
                            width: 0.8,
                          ),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 40,
                              color: Color(0xFF52616B),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No purchases yet',
                              style: TextStyle(color: Color(0xFF52616B)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final paidAt = (d['paidAt'] as Timestamp?)?.toDate();
                      final dateStr = paidAt != null
                          ? '${paidAt.day.toString().padLeft(2, '0')}/'
                                '${paidAt.month.toString().padLeft(2, '0')}/'
                                '${paidAt.year}'
                          : 'Processing...';
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: context.cardShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.receipt_rounded,
                                  color: Colors.green,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d['courseName'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: context.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${(d['amount'] as num?)?.toStringAsFixed(0) ?? ''}',
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        color: context.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Paid',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ),
      ],
    );
  }

  Widget _buildStatsRow(String uid) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: uid)
          .get(),
      builder: (context, snapshot) {
        int enrolled = 0;
        int completed = 0;

        if (snapshot.hasData) {
          enrolled = snapshot.data!.docs
              .where((doc) => ((doc.data() as Map<String, dynamic>?)?['status'] ?? '') != 'completed')
              .length;
          completed = snapshot.data!.docs
              .where((doc) => ((doc.data() as Map<String, dynamic>?)?['status'] ?? '') == 'completed')
              .length;
        }

        return Row(
          children: [
            Expanded(child: _buildStatCard('Enrolled', '$enrolled')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Completed', '$completed')),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.brandSoftColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor, width: 0.8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: context.cardColor,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.borderColor, width: 0.8),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        iconColor: context.textSecondary,
        collapsedIconColor: context.textSecondary,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.brandSoftColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Icon(icon, color: AppColors.brand, size: 20)),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: context.textPrimary,
          ),
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionListTile({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Icon(icon, color: color, size: 20)),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: onTap == null ? context.textSecondary : context.textPrimary,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: context.textSecondary),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _safeBackToStudentDashboard(context);
      },
      child: ValueListenableBuilder(
        valueListenable: _appAuth.currentUser,
        builder: (context, value, child) {
          final appUser = value as dynamic;
          if (appUser == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Profile')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('You need to login to view profile.'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          context.go(AppRoutes.login);
                        },
                        child: const Text('Go to Login'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final isDemo = (appUser.uid ?? '').toString().startsWith('demo-');

          return Scaffold(
            body: isDemo
                ? _buildProfileBody(
                    profile: (appUser as dynamic).toMap(),
                    studentProfile: null,
                  )
                : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _profileController.getUserProfile(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.active &&
                          snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Failed to load profile: ${snapshot.error}',
                          ),
                        );
                      }

                      final profile = snapshot.data?.data();
                      if (profile == null) {
                        return const Center(
                          child: Text(
                            'Profile not found. Please complete setup.',
                          ),
                        );
                      }

                      final role = _asText(
                        profile['role'],
                        fallback: 'student',
                      ).toLowerCase();
                      if (role != 'student') {
                        return _buildProfileBody(
                          profile: profile,
                          studentProfile: null,
                        );
                      }

                      return StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>
                      >(
                        stream: _profileController.getStudentProfile(),
                        builder: (context, studentSnapshot) {
                          if (studentSnapshot.connectionState !=
                                  ConnectionState.active &&
                              studentSnapshot.connectionState !=
                                  ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          return _buildProfileBody(
                            profile: profile,
                            studentProfile: studentSnapshot.data?.data(),
                          );
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
