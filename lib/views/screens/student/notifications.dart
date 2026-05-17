import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../controllers/app_auth_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/animations.dart';

void _safeBackToStudentDashboard(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.studentDashboard);
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const primary = Color(0xFF0E7C86);

  @override
  Widget build(BuildContext context) {
    final uid = AppAuthController().currentUser.value?.uid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _safeBackToStudentDashboard(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => _safeBackToStudentDashboard(context),
          ),
          title: const Text("Notifications"),
          scrolledUnderElevation: 0,
        ),
        body: uid == null
            ? const Center(child: Text('Please log in to view notifications.'))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .doc(uid)
                    .collection('items')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 56),
                          const SizedBox(height: 12),
                          Text(
                            'Unable to load notifications: ${snapshot.error}',
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text('No notifications yet'),
                          SizedBox(height: 6),
                          Text(
                            'We will show updates here when something new arrives.',
                          ),
                        ],
                      ),
                    );
                  }

                  final notifications = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notificationDoc = notifications[index];
                      final notification = notificationDoc.data();

                      return _notificationCard(
                        context,
                        uid: uid,
                        notificationId: notificationDoc.id,
                        isRead: notification['isRead'] == true,
                        icon: _iconForType(notification['type'] as String?),
                        title: notification['title'] as String,
                        body: notification['body'] as String,
                        time: _timeAgo(notification['createdAt'] as Timestamp?),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'assignment':
        return Icons.assignment_turned_in;
      case 'live':
        return Icons.video_call;
      case 'course':
      default:
        return Icons.school;
    }
  }

  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }

    final createdAt = timestamp.toDate();
    final difference = DateTime.now().difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }

    return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
  }

  Widget _notificationCard(
    BuildContext context, {
    required String uid,
    required String notificationId,
    required bool isRead,
    required IconData icon,
    required String title,
    required String body,
    required String time,
  }) {
    return GestureDetector(
      onTap: () async {
        if (notificationId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(uid)
              .collection('items')
              .doc(notificationId)
              .update({'isRead': true});
        }
        if (context.mounted) {
          context.push(
            AppRoutes.studentNotifications,
            extra: {'title': title, 'body': body},
          );
        }
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color: icon == Icons.video_call
                  ? Colors.orange
                  : icon == Icons.assignment_turned_in
                  ? Colors.green
                  : Colors.blue,
              width: 3,
            ),
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            /// unread indicator
            if (!isRead) const PulseDot(size: 8),
          ],
        ),
      ),
    );
  }
}
