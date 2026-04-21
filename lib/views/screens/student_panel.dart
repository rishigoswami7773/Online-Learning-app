import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';

import '../../controllers/auth_controller.dart';

class StudentPanel extends StatelessWidget {
  const StudentPanel({super.key});

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
      _infoCard(Icons.book, 'Enrolled Courses', '3 courses'),
      _infoCard(Icons.schedule, 'Upcoming', '1 live session'),
      _infoCard(Icons.grade, 'Progress', '42% complete'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Decorative background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEDE7F6), Color(0xFFF3E5F5)],
                  ),
                ),
              ),
            ),
            // Content
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Welcome, Student!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.courses),
                    icon: const Icon(Icons.book),
                    label: const Text('Browse Courses'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.search),
                    icon: const Icon(Icons.search),
                    label: const Text('Search Courses'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppRoutes.profile,
                      arguments: {
                        'role': 'Student',
                        'name': 'Alice',
                        'email': 'alice@student.com',
                      },
                    ),
                    icon: const Icon(Icons.person),
                    label: const Text('Profile'),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: List.generate(
                      cards.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: cards[i],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
