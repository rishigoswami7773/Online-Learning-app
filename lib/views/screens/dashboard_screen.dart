import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final String role;
  const DashboardScreen({super.key, required this.role});

  List<Widget> _buildCards(BuildContext context) {
    if (role == 'Student') {
      return [
        _infoCard(Icons.book, 'Enrolled Courses', '3 courses'),
        _infoCard(Icons.schedule, 'Upcoming', '1 live session'),
        _infoCard(Icons.grade, 'Progress', '42% complete'),
      ];
    } else if (role == 'Mentor') {
      return [
        _infoCard(Icons.people, 'My Students', '12 active'),
        _infoCard(Icons.live_tv, 'Live Sessions', '2 scheduled'),
        _infoCard(Icons.upload_file, 'Assignments', '5 to grade'),
      ];
    } else {
      return [
        _infoCard(Icons.settings, 'Platform', 'All systems nominal'),
        _infoCard(Icons.report, 'Reports', '2 new reports'),
        _infoCard(Icons.admin_panel_settings, 'Manage Users', 'Edit roles'),
      ];
    }
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$role Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              // Logout -> back to login
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => Navigator.of(context).widget),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Welcome, $role!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemBuilder: (ctx, idx) => _buildCards(context)[idx],
                  separatorBuilder: (ctx, index) => const SizedBox(height: 12),
                  itemCount: _buildCards(context).length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
