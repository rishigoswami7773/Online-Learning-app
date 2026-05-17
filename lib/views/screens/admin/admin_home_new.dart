import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../controllers/theme_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/theme_helper.dart';

class AdminHomeScreenNew extends StatefulWidget {
  const AdminHomeScreenNew({super.key});

  @override
  State<AdminHomeScreenNew> createState() => _AdminHomeScreenNewState();
}

class _AdminHomeScreenNewState extends State<AdminHomeScreenNew> {
  late Future<Map<String, dynamic>> _statsFuture;
  bool _maintenanceMode = false;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
    _loadMaintenanceMode();
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final fs = FirebaseFirestore.instance;

    Future<int> countDocs(String collection) async {
      try {
        final snapshot = await fs.collection(collection).get();
        return snapshot.docs.length;
      } catch (e) {
        return 0;
      }
    }

    return {
      'usersCount': await countDocs('users'),
      'coursesCount': await countDocs('courses'),
      'enrollmentsCount': await countDocs('enrollments'),
      'reviewsCount': await countDocs('course_reviews'),
    };
  }

  Future<void> _loadMaintenanceMode() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('system')
          .doc('settings')
          .get();
      if (doc.exists) {
        setState(() {
          _maintenanceMode = doc.data()?['maintenanceMode'] ?? false;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _toggleMaintenance(bool value) async {
    setState(() => _maintenanceMode = value);
    try {
      await FirebaseFirestore.instance.collection('system').doc('settings').set(
        {'maintenanceMode': value},
        SetOptions(merge: true),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Maintenance mode ON' : 'Maintenance mode OFF',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => _maintenanceMode = !value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: context.surfaceColor,
            title: const Text('Exit?'),
            content: const Text('Do you want to exit the app?'),
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
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          elevation: 0,
          actions: [
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController().mode,
              builder: (context, mode, _) => IconButton(
                icon: Icon(
                  mode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode_outlined,
                ),
                onPressed: ThemeController().toggle,
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() => _statsFuture = _loadStats());
            await _statsFuture;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats
                FutureBuilder<Map<String, dynamic>>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Could not load data.\nCheck your connection and try again.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: context.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () =>
                                    setState(() => _statsFuture = _loadStats()),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final stats = snapshot.data!;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildKPICard(
                          'Total Users',
                          stats['usersCount'].toString(),
                          Icons.people,
                          Colors.blue,
                        ),
                        _buildKPICard(
                          'Total Courses',
                          stats['coursesCount'].toString(),
                          Icons.book,
                          Colors.green,
                        ),
                        _buildKPICard(
                          'Total Enrollments',
                          stats['enrollmentsCount'].toString(),
                          Icons.school,
                          Colors.orange,
                        ),
                        _buildKPICard(
                          'Total Reviews',
                          stats['reviewsCount'].toString(),
                          Icons.star,
                          Colors.amber,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Maintenance
                Card(
                  color: context.cardColor,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: context.borderColor, width: 0.8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Maintenance Mode',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _maintenanceMode
                                  ? 'App is in maintenance'
                                  : 'App is running normally',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _maintenanceMode,
                          onChanged: _toggleMaintenance,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          context.push(AppRoutes.adminManageUsers);
                        },
                        icon: const Icon(Icons.people),
                        label: const Text('Manage Users'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () {
                          context.push(AppRoutes.adminManageCourses);
                        },
                        icon: const Icon(Icons.book),
                        label: const Text('Manage Courses'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Recent Users
                Text(
                  'Recent Users',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('createdAt', descending: true)
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Text(
                        'No recent users',
                        style: TextStyle(color: context.textSecondary),
                      );
                    }

                    final users = snapshot.data!.docs;
                    return Column(
                      children: List.generate(users.length, (idx) {
                        final data = users[idx].data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: context.cardColor,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: context.borderColor,
                              width: 0.8,
                            ),
                          ),
                          child: ListTile(
                            title: Text(data['name'] ?? 'User'),
                            subtitle: Text(data['email'] ?? 'No email'),
                            trailing: Chip(label: Text(data['role'] ?? 'user')),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return Card(
      color: context.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.borderColor, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
