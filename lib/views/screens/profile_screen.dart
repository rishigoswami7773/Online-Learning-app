import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import 'edit_profile_screen.dart';

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

  final _authController = AuthController();
  final _profileController = ProfileController();
  bool _isLoggingOut = false;
  bool _isDeleting = false;

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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          userProfile: userProfile,
          studentProfile: studentProfile ?? const <String, dynamic>{},
        ),
      ),
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() => _isLoggingOut = true);

    final result = await _authController.logoutUser();
    if (!mounted) {
      return;
    }

    setState(() => _isLoggingOut = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed to logout.')),
      );
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  Future<void> _confirmDeleteAccount() async {
    if (_isDeleting) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This action permanently deletes your account and profile data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    setState(() => _isDeleting = true);
    final result = await _authController.deleteAccount();

    if (!mounted) {
      return;
    }

    setState(() => _isDeleting = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Could not delete account.')),
      );
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  Widget _infoTile({required String label, required String value}) {
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _collapsibleSection({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        children: [child],
      ),
    );
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

    return SingleChildScrollView(
      child: Column(
        children: [
          _sectionCard(
            title: 'Profile Header',
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: _avatarProvider(profileImage),
                  child: profileImage.isEmpty
                      ? Text(
                          name.isEmpty ? 'U' : name.substring(0, 1),
                          style: const TextStyle(fontSize: 22),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(email),
                      const SizedBox(height: 6),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(role.toLowerCase()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _collapsibleSection(
            title: 'Personal Details',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoTile(label: 'Phone Number', value: phone),
                _infoTile(label: 'Date of Birth', value: _formatDate(dob)),
                _infoTile(label: 'Gender', value: gender),
                _infoTile(label: 'City', value: city),
                _infoTile(label: 'State', value: state),
                _infoTile(label: 'Country', value: country),
              ],
            ),
          ),
          if (role.toLowerCase() == 'student')
            _collapsibleSection(
              title: 'Academic Details',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _infoTile(label: 'Education Level', value: educationLevel),
                  _infoTile(label: 'Class / Year', value: classYear),
                  _infoTile(label: 'Stream / Field', value: stream),
                ],
              ),
            ),
          _collapsibleSection(
            title: 'Preferences',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoTile(
                      label: 'Language Preference',
                      value: languagePreference,
                    ),
                    _infoTile(label: 'Learning Goals', value: learningGoals),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Selected Courses',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                if (selectedCourses.isEmpty)
                  Text('-', style: Theme.of(context).textTheme.bodyMedium)
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: selectedCourses
                        .map(
                          (course) => Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(course),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
          _collapsibleSection(
            title: 'Account Info',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoTile(label: 'Role', value: role.toLowerCase()),
                _infoTile(
                  label: 'Account Created Date',
                  value: _formatDate(createdAt),
                ),
              ],
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _openEditProfile(
                      userProfile: profile,
                      studentProfile: studentProfile,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.changePassword),
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Change Password'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isLoggingOut ? null : _logout,
                    icon: _isLoggingOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout),
                    label: Text(_isLoggingOut ? 'Logging out...' : 'Logout'),
                  ),
                  TextButton.icon(
                    onPressed: _isDeleting ? null : _confirmDeleteAccount,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_forever_outlined),
                    label: Text(
                      _isDeleting ? 'Deleting account...' : 'Delete Account',
                    ),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _profileController.currentUser;
    if (user == null) {
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
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.login),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _profileController.getUserProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.active &&
                    snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Failed to load profile: ${snapshot.error}'),
                  );
                }

                final profile = snapshot.data?.data();
                if (profile == null) {
                  return const Center(
                    child: Text('Profile not found. Please complete setup.'),
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

                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _profileController.getStudentProfile(),
                  builder: (context, studentSnapshot) {
                    if (studentSnapshot.connectionState !=
                            ConnectionState.active &&
                        studentSnapshot.connectionState !=
                            ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return _buildProfileBody(
                      profile: profile,
                      studentProfile: studentSnapshot.data?.data(),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
