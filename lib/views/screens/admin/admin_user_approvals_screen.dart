import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_widgets.dart';

class AdminUserApprovalsScreen extends StatefulWidget {
  const AdminUserApprovalsScreen({super.key});

  @override
  State<AdminUserApprovalsScreen> createState() =>
      _AdminUserApprovalsScreenState();
}

class _AdminUserApprovalsScreenState extends State<AdminUserApprovalsScreen> {
  Future<void> _approveUser(
    DocumentSnapshot<Map<String, dynamic>> userDoc,
  ) async {
    try {
      final data = userDoc.data() ?? <String, dynamic>{};
      final email = (data['email'] as String?) ?? '';
      final name = (data['name'] as String?) ?? 'User';

      await userDoc.reference.update({
        'isVerified': true,
        'status': 'active',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': userDoc.id,
        'title': 'Account approved',
        'body': email.isEmpty
            ? 'Your account has been approved by the admin.'
            : 'Hi $name, your account has been approved.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$name approved successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving user: $e')));
    }
  }

  Future<void> _rejectUser(
    DocumentSnapshot<Map<String, dynamic>> userDoc,
  ) async {
    try {
      final data = userDoc.data() ?? <String, dynamic>{};
      final email = (data['email'] as String?) ?? '';
      final name = (data['name'] as String?) ?? 'User';

      await userDoc.reference.update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': userDoc.id,
        'title': 'Account review completed',
        'body': email.isEmpty
            ? 'Your account request was not approved.'
            : 'Hi $name, your account request was not approved.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$name rejected successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error rejecting user: $e')));
    }
  }

  Widget _pendingHeader(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const PulseDot(color: Colors.orange, size: 8),
          const SizedBox(width: 10),
          Text(
            '$count pending',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageWrapper(
      title: 'User Approvals',
      showBackButton: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('isVerified', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  adminHeroHeader(
                    title: 'User Approvals',
                    subtitle: 'Review new accounts and pending requests',
                  ),
                  SizedBox(height: 16),
                  ShimmerBox(
                    width: double.infinity,
                    height: 120,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Unable to load approvals: ${snapshot.error}'),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 10),
                    const Text('No pending approvals'),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                adminHeroHeader(
                  title: 'User Approvals',
                  subtitle: 'Review new accounts and pending requests',
                ),
                const SizedBox(height: 12),
                _pendingHeader(docs.length),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final name = (data['name'] as String?) ?? 'Unknown user';
                      final email = (data['email'] as String?) ?? '';
                      final role = (data['role'] as String?) ?? 'student';
                      final status = (data['status'] as String?) ?? 'pending';

                      return StaggeredItem(
                        delay: Duration(milliseconds: index * 60),
                        child: adminListCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AdminColors.brandSoft,
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: AdminColors.brand,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          email,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  adminPill(status, Colors.orange),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  adminPill(role, AdminColors.brand),
                                  if (email.isNotEmpty)
                                    adminPill(email, AdminColors.accent),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _approveUser(doc),
                                    icon: const Icon(Icons.verified, size: 16),
                                    label: const Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AdminColors.brand,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: () => _rejectUser(doc),
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('Reject'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
