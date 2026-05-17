import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/mentor/mentor_notifications_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/uid_resolver.dart';

const Color _mentorTeal = Color(0xFF0E7C86);

void _safeBackToMentorDashboard(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.mentorDashboard);
  }
}

class MentorNotificationsPage extends StatefulWidget {
  const MentorNotificationsPage({super.key});

  @override
  State<MentorNotificationsPage> createState() =>
      _MentorNotificationsPageState();
}

class _MentorNotificationsPageState extends State<MentorNotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = UidResolver.uid;
      if (uid == null && mounted) {
        context.go(AppRoutes.login);
      }
    });
  }

  final _controller = MentorNotificationsController();

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'enrollment':
        return Icons.person_add_alt_1_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      case 'system':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'enrollment':
        return Colors.blue;
      case 'review':
        return Colors.amber;
      case 'achievement':
        return Colors.green;
      case 'system':
        return Colors.grey;
      default:
        return _mentorTeal;
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    if (!UidResolver.isLoggedIn) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _safeBackToMentorDashboard(context);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: _mentorTeal,
          elevation: 1,
          title: const Text(
            'Notifications',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _mentorTeal),
            onPressed: () => _safeBackToMentorDashboard(context),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _controller.notificationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Unable to load notifications: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData || (snapshot.data?.docs ?? []).isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No data yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data!.docs
                .cast<QueryDocumentSnapshot<Map<String, dynamic>>>()
                .toList();
            docs.sort((a, b) {
              final aDate =
                  (a.data()['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bDate =
                  (b.data()['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final title = (data['title'] as String?) ?? 'Notification';
                final body = (data['body'] as String?) ?? '';
                final type = (data['type'] as String?) ?? 'system';
                final isRead =
                    (data['isRead'] as bool?) ??
                    (data['read'] as bool?) ??
                    false;
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                final color = _colorForType(type);

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    if (!isRead) {
                      await _controller.markRead(doc.id);
                    }
                  },
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(_iconForType(type), color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isRead
                                              ? FontWeight.w600
                                              : FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: _mentorTeal,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(body, style: const TextStyle(height: 1.4)),
                                const SizedBox(height: 8),
                                Text(
                                  createdAt == null
                                      ? 'Just now'
                                      : _timeAgo(createdAt),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
