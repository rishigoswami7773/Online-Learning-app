import 'package:flutter/material.dart';
import 'admin_widgets.dart';

class AdminManageUsersScreen extends StatelessWidget {
  const AdminManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = List.generate(20, (i) => {'name': 'User $i', 'email': 'user$i@example.com'});

    return AdminPageWrapper(
      title: 'Manage Users',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: users.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final u = users[index];
            return ListTile(
              leading: CircleAvatar(child: Text(u['name']![5])),
              title: Text(u['name']!),
              subtitle: Text(u['email']!),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => UserDetailScreen(name: u['name']!, email: u['email']!)));
                },
              ),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => UserDetailScreen(name: u['name']!, email: u['email']!)));
              },
            );
          },
        ),
      ),
    );
  }
}

class UserDetailScreen extends StatelessWidget {
  final String name;
  final String email;
  const UserDetailScreen({super.key, required this.name, required this.email});
  @override
  Widget build(BuildContext context) {
    return AdminPageWrapper(
      title: 'User detail',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 36, child: const Icon(Icons.person)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: Theme.of(context).textTheme.headlineSmall),
              Text(email),
            ]),
          ]),
          const SizedBox(height: 20),
          Card(child: ListTile(title: const Text('Enrolled courses'), subtitle: const Text('Course A, Course B'))),
          const SizedBox(height: 10),
          ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.block), label: const Text('Disable user'))
        ]),
      ),
    );
  }
}
