import 'package:flutter/material.dart';

class MentorRatingsPage extends StatelessWidget {
  const MentorRatingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final courses = [
      {'title': 'Flutter Advanced', 'rating': '4.6', 'reviews': '24'},
      {'title': 'UI/UX Masterclass', 'rating': '4.4', 'reviews': '11'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Ratings & Reviews')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: courses.length,
          itemBuilder: (_, idx) {
            final c = courses[idx];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.menu_book, color: Colors.white)),
                title: Text(c['title']!),
                subtitle: Row(children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 6),
                  Text('${c['rating']} (${c['reviews']} reviews)')
                ]),
                trailing: TextButton(
                  onPressed: () {
                    // open review list (demo)
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('${c['title']} Reviews'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            ListTile(
                                leading: CircleAvatar(child: Icon(Icons.person)),
                                title: Text('Great course!'),
                                subtitle: Text('Very helpful.')),
                            ListTile(
                                leading: CircleAvatar(child: Icon(Icons.person)),
                                title: Text('Could improve'),
                                subtitle: Text('More examples needed.')),
                          ],
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'))
                        ],
                      ),
                    );
                  },
                  child: const Text('View'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
