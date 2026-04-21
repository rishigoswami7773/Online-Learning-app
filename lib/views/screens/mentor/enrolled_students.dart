import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';

class EnrolledStudentsPage extends StatefulWidget {
  const EnrolledStudentsPage({super.key});

  @override
  State<EnrolledStudentsPage> createState() => _EnrolledStudentsPageState();
}

class _EnrolledStudentsPageState extends State<EnrolledStudentsPage> {
  final List<Map<String, String>> students = [
    {'name': 'Alice Johnson', 'email': 'alice@example.com'},
    {'name': 'Bob Smith', 'email': 'bob@example.com'},
    {'name': 'Charlie Ray', 'email': 'charlie@example.com'},
  ];

  String query = '';

  void _showProfile(Map<String, String> s) {
    showModalBottomSheet(
        context: context,
        builder: (_) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        children: [
                          CircleAvatar(
                              radius: 28,
                              backgroundImage:
                                  NetworkImage('https://i.pravatar.cc/150?img=9')),
                          const SizedBox(width: 12),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['name']!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text(s['email']!)
                              ])
                        ]),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(AppRoutes.studentProfile,
                              arguments: {
                                'name': s['name'],
                                'email': s['email']
                              });
                        },
                        icon: const Icon(Icons.message),
                        label: const Text('Message')),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('View progress (demo)')));
                        },
                        icon: const Icon(Icons.bar_chart),
                        label: const Text('Progress')),
                    const SizedBox(height: 12),
                  ]),
            ));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = students
        .where((s) => s['name']!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Enrolled Students')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search students',
                        border: OutlineInputBorder()),
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                    itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'active', child: Text('Active')),
                          PopupMenuItem(
                              value: 'inactive', child: Text('Inactive'))
                        ],
                    onSelected: (_) => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filter applied (demo)'))))
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, idx) {
                  final s = filtered[idx];
                  return ListTile(
                    leading: CircleAvatar(
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=${idx + 10}')),
                    title: Text(s['name']!),
                    subtitle: Row(
                      children: [
                        Text(s['email']!),
                        const SizedBox(width: 8),
                        Chip(
                            label: Text('Active'),
                            backgroundColor: Colors.green.shade50)
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.chat),
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.studentProfile,
                            arguments: {'name': s['name'], 'email': s['email']});
                      },
                    ),
                    onTap: () => _showProfile(s),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
