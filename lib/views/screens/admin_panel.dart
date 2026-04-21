import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';

import '../../controllers/auth_controller.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthController().logoutUser();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  Widget _infoCard(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.deepPurple.shade50,
              child: Icon(icon, color: Colors.deepPurple),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _infoCard(Icons.settings, 'Platform', 'All systems nominal'),
      _infoCard(Icons.report, 'Reports', '2 new reports'),
      _infoCard(Icons.admin_panel_settings, 'Manage Users', 'Edit roles'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome, Admin!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.manageCourses),
                icon: const Icon(Icons.list),
                label: const Text('Manage Courses'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.manageUsers),
                icon: const Icon(Icons.people),
                label: const Text('Manage Users'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.profile,
                  arguments: {
                    'role': 'Admin',
                    'name': 'Admin',
                    'email': 'admin@platform.com',
                  },
                ),
                icon: const Icon(Icons.person),
                label: const Text('Profile'),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemBuilder: (_, idx) => cards[idx],
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemCount: cards.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
