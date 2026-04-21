import 'package:flutter/material.dart';
import 'notifications_detail.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const primary = Color(0xff6A5AE0);

  @override
  Widget build(BuildContext context) {

    final notifications = [
      {
        "title": "New course available",
        "body": "A new Flutter Development course has been added. Start learning today!",
        "time": "2 min ago",
        "icon": Icons.school
      },
      {
        "title": "Assignment graded",
        "body": "Your UI/UX assignment has been graded. Check your score now.",
        "time": "1 hour ago",
        "icon": Icons.assignment_turned_in
      },
      {
        "title": "Live class reminder",
        "body": "Your Flutter live class starts at 6:00 PM today.",
        "time": "3 hours ago",
        "icon": Icons.video_call
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: primary,
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {

          final n = notifications[index];

          return _notificationCard(
            context,
            icon: n["icon"] as IconData,
            title: n["title"] as String,
            body: n["body"] as String,
            time: n["time"] as String,
          );
        },
      ),
    );
  }

  Widget _notificationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required String time,
  }) {
    return GestureDetector(
      onTap: () {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotificationDetailPage(
              title: title,
              body: body,
            ),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),

          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),

        child: Row(
          children: [

            /// icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primary),
            ),

            const SizedBox(width: 12),

            /// text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    time,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey),
                  ),
                ],
              ),
            ),

            /// unread indicator
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            )
          ],
        ),
      ),
    );
  }
}