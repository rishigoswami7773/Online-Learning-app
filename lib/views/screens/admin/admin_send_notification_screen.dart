import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_widgets.dart';

/// Admin screen to send push notifications to all students or a specific user.
class AdminSendNotificationScreen extends StatefulWidget {
  const AdminSendNotificationScreen({super.key});

  @override
  State<AdminSendNotificationScreen> createState() =>
      _AdminSendNotificationScreenState();
}

class _AdminSendNotificationScreenState
    extends State<AdminSendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  // Target options
  String _target = 'all'; // 'all', 'students', 'mentors', 'specific'
  final _specificEmailCtrl = TextEditingController();

  bool _sending = false;
  String? _lastResult;
  bool _lastSuccess = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _specificEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _sending = true;
      _lastResult = null;
    });

    try {
      final fs = FirebaseFirestore.instance;
      final title = _titleCtrl.text.trim();
      final body = _bodyCtrl.text.trim();
      final now = FieldValue.serverTimestamp();

      final notifData = {
        'title': title,
        'body': body,
        'type': 'admin',
        'isRead': false,
        'createdAt': now,
      };

      // Fetch target user UIDs
      List<String> targetUids = [];

      if (_target == 'specific') {
        // Find user by email
        final email = _specificEmailCtrl.text.trim().toLowerCase();
        final snap = await fs
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (snap.docs.isEmpty) {
          if (mounted) {
            setState(() {
              _sending = false;
              _lastResult = 'No user found with email: $email';
              _lastSuccess = false;
            });
          }
          return;
        }
        targetUids = [snap.docs.first.id];
      } else {
        // Fetch all users matching role
        Query<Map<String, dynamic>> query = fs.collection('users');
        if (_target == 'students') {
          query = query.where('role', isEqualTo: 'student');
        } else if (_target == 'mentors') {
          query = query.where('role', isEqualTo: 'mentor');
        }
        // 'all' => no filter
        final snap = await query.get();
        targetUids = snap.docs.map((d) => d.id).toList();
      }

      if (targetUids.isEmpty) {
        if (mounted) {
          setState(() {
            _sending = false;
            _lastResult = 'No users found for this target group.';
            _lastSuccess = false;
          });
        }
        return;
      }

      // Write to each user's notifications subcollection
      // notifications/{uid}/items/{auto-id}
      // Use batches of 500 (Firestore batch limit)
      int sent = 0;
      for (int i = 0; i < targetUids.length; i += 400) {
        final batch = fs.batch();
        final chunk = targetUids.skip(i).take(400).toList();
        for (final uid in chunk) {
          final ref = fs
              .collection('notifications')
              .doc(uid)
              .collection('items')
              .doc();
          batch.set(ref, notifData);
        }
        await batch.commit();
        sent += chunk.length;
      }

      if (mounted) {
        setState(() {
          _sending = false;
          _lastResult = '✅ Notification sent to $sent user${sent == 1 ? '' : 's'}!';
          _lastSuccess = true;
          _titleCtrl.clear();
          _bodyCtrl.clear();
          _specificEmailCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _lastResult = '❌ Failed to send: $e';
          _lastSuccess = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notification', style: AdminTextStyles.appBarTitle),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AdminColors.brand.withValues(alpha: 0.12),
                      AdminColors.accent.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AdminColors.brand.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AdminColors.brand.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: AdminColors.brand,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Send in-app notifications directly to students or mentors. They will see it immediately in their Notifications tab.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Target audience card
              _buildCard(
                context: context,
                title: 'Target Audience',
                icon: Icons.people_outline,
                child: Column(
                  children: [
                    _targetOption(context, 'all', 'All Users', Icons.public),
                    _targetOption(context, 'students', 'Students Only', Icons.school_outlined),
                    _targetOption(context, 'mentors', 'Mentors Only', Icons.person_pin_outlined),
                    _targetOption(context, 'specific', 'Specific User (by email)', Icons.person_search_outlined),
                    if (_target == 'specific') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _specificEmailCtrl,
                        decoration: InputDecoration(
                          labelText: 'User Email',
                          prefixIcon: const Icon(Icons.email_outlined, color: AdminColors.brand),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AdminColors.brand, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (_target == 'specific')
                            ? (v) => (v ?? '').trim().isEmpty
                                ? 'Enter user email'
                                : null
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notification content card
              _buildCard(
                context: context,
                title: 'Notification Content',
                icon: Icons.edit_note_outlined,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Title *',
                        hintText: 'e.g. Platform Update, New Course Added...',
                        prefixIcon: const Icon(Icons.title, color: AdminColors.brand),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AdminColors.brand, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a title' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _bodyCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Message *',
                        hintText: 'Write your notification message here...',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.message_outlined, color: AdminColors.brand),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AdminColors.brand, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a message' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Result banner
              if (_lastResult != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _lastSuccess
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _lastSuccess
                          ? Colors.green.withValues(alpha: 0.4)
                          : Colors.red.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _lastSuccess ? Icons.check_circle_outline : Icons.error_outline,
                        color: _lastSuccess ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _lastResult!,
                          style: TextStyle(
                            color: _lastSuccess ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Send button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _sending ? 'Sending...' : 'Send Notification',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminColors.brand,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Recent notifications sent by admin
              Text(
                'Recently Sent',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _RecentNotifsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _targetOption(BuildContext context, String value, String label, IconData icon) {
    final selected = _target == value;
    return InkWell(
      onTap: () => setState(() => _target = value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AdminColors.brand : Colors.grey.shade400,
                  width: 2,
                ),
                color: selected ? AdminColors.brand : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: selected ? AdminColors.brand : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AdminColors.brand : Theme.of(context).colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AdminColors.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AdminColors.brand, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Shows the last 10 admin notifications sent (sampled from one user's inbox)
class _RecentNotifsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // We look at a recent notifications sent to the first 'admin'-role user
    // to show a sample of recently sent notifications
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get(),
      builder: (context, adminSnap) {
        if (!adminSnap.hasData || adminSnap.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final adminUid = adminSnap.data!.docs.first.id;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .doc(adminUid)
              .collection('items')
              .orderBy('createdAt', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 24),
                  child: Text(
                    'No notifications sent yet.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              );
            }
            return Column(
              children: snap.data!.docs.map((doc) {
                final d = doc.data();
                final ts = (d['createdAt'] as Timestamp?)?.toDate();
                final timeStr = ts != null
                    ? '${ts.day}/${ts.month}/${ts.year} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}'
                    : '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AdminColors.brand.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: AdminColors.brand,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (d['title'] as String?) ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (d['body'] as String?) ?? '',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
