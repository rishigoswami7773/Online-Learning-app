import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  final List<Map<String, String>> users = const [
    {'name': 'Alice', 'email': 'alice@student.com', 'role': 'Student'},
    {'name': 'Bob', 'email': 'bob@student.com', 'role': 'Student'},
    {'name': 'Celine', 'email': 'celine@mentor.com', 'role': 'Mentor'},
    {'name': 'Admin', 'email': 'admin@platform.com', 'role': 'Admin'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.admin);
            }
          },
        ),
        title: const Text('Manage Users'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: users.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, idx) {
          final u = users[idx];
          return ListTile(
            title: Text(u['name']!),
            subtitle: Text('${u['email']} • ${u['role']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Edit ${u['name']} - feature coming soon',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Delete ${u['name']} - feature coming soon',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
