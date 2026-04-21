import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';

import '../../controllers/auth_controller.dart';

class MentorPanel extends StatelessWidget {
  const MentorPanel({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthController().logoutUser();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    Widget actionCard(IconData icon, String title, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .03),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: primary.withValues(alpha: .12),
                child: Icon(icon, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentor Panel'),
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?img=12',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome, Celine!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Here are quick actions and your overview',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.mentorCreate),
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Summary tiles
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .03),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        children: const [
                          Text(
                            '4',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text('Courses', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .03),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        children: const [
                          Text(
                            '120',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Students',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .03),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        children: const [
                          Text(
                            '35',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text('Reviews', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView.separated(
                  itemCount: 4,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    if (idx == 0) {
                      return actionCard(
                        Icons.list,
                        'Manage Courses',
                        () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.mentorManageCourses),
                      );
                    }
                    if (idx == 1) {
                      return actionCard(
                        Icons.upload_file,
                        'Upload Content',
                        () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.mentorUpload),
                      );
                    }
                    if (idx == 2) {
                      return actionCard(
                        Icons.people_alt,
                        'Enrolled Students',
                        () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.mentorStudents),
                      );
                    }
                    return actionCard(
                      Icons.star,
                      'Ratings & Reviews',
                      () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.mentorRatings),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
