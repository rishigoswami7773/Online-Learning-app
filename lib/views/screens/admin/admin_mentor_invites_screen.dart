import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'admin_widgets.dart';

class AdminMentorInvitesScreen extends StatefulWidget {
  const AdminMentorInvitesScreen({super.key});

  @override
  State<AdminMentorInvitesScreen> createState() =>
      _AdminMentorInvitesScreenState();
}

class _AdminMentorInvitesScreenState extends State<AdminMentorInvitesScreen> {
  final _emailCtrl = TextEditingController();
  final _expiryHoursCtrl = TextEditingController(text: '24');
  bool _isGenerating = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _expiryHoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateInvite() async {
    if (_emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    final hours = int.tryParse(_expiryHoursCtrl.text);
    if (hours == null || hours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid expiry hours')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Generate unique invite ID
      final inviteId = DateTime.now().millisecondsSinceEpoch.toString();

      // Calculate expiry date
      final expiresAt = DateTime.now().add(Duration(hours: hours));

      // Create invite document
      await FirebaseFirestore.instance.collection('invites').doc(inviteId).set({
        'email': _emailCtrl.text.trim(),
        'role': 'mentor',
        'inviteId': inviteId,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'used': false,
        'createdBy': 'admin', // You might want to track which admin created it
      });

      // Generate invite URL
      final inviteUrl =
          'https://yourapp.com/register?role=mentor&inviteId=$inviteId';

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Mentor Invite Generated'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${_emailCtrl.text.trim()}'),
                const SizedBox(height: 8),
                const Text(
                  'Invite Link:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                SelectableText(inviteUrl),
                const SizedBox(height: 8),
                Text('Expires: ${expiresAt.toString()}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: inviteUrl));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invite link copied to clipboard'),
                      ),
                    );
                  }
                },
                child: const Text('Copy Link'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        _emailCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating invite: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageWrapper(
      title: 'Mentor Invites',
      showBackButton: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            adminHeroHeader(
              title: 'Mentor Invites',
              subtitle: 'Generate temporary invites for new mentors',
            ),
            const SizedBox(height: 16),
            adminListCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate Mentor Invite',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Mentor Email Address',
                      hintText: 'Enter the email of the person to invite',
                      prefixIcon: Icon(
                        Icons.email,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(color: Color(0xFFD9E2EC)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(
                          color: AdminColors.brand,
                          width: 1.3,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _expiryHoursCtrl,
                    decoration: InputDecoration(
                      labelText: 'Expiry Hours',
                      hintText: 'How many hours until the invite expires',
                      prefixIcon: Icon(
                        Icons.timer,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(color: Color(0xFFD9E2EC)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(
                          color: AdminColors.brand,
                          width: 1.3,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: adminPrimaryButton(
                      onPressed: _isGenerating ? null : _generateInvite,
                      isLoading: _isGenerating,
                      child: const Text('Generate Invite'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            adminSectionHeader('Active Invites'),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('invites')
                    .where('role', isEqualTo: 'mentor')
                    .where('used', isEqualTo: false)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final invites = snapshot.data?.docs ?? [];

                  if (invites.isEmpty) {
                    return const Center(
                      child: Text('No active mentor invites'),
                    );
                  }

                  return ListView.builder(
                    itemCount: invites.length,
                    itemBuilder: (context, index) {
                      final inviteDoc = invites[index];
                      final inviteData =
                          inviteDoc.data() as Map<String, dynamic>;
                      final expiresAt = inviteData['expiresAt'] as Timestamp?;
                      final isExpired =
                          expiresAt != null &&
                          expiresAt.toDate().isBefore(DateTime.now());

                      return adminListCard(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    (isExpired ? Colors.red : AdminColors.brand)
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isExpired ? Icons.timer_off : Icons.link,
                                color: isExpired
                                    ? Colors.red
                                    : AdminColors.brand,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inviteData['email'] ?? 'Unknown email',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Created: ${_formatTimestamp(inviteData['createdAt'])}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    isExpired
                                        ? 'Expired'
                                        : 'Expires: ${_formatTimestamp(expiresAt)}',
                                    style: TextStyle(
                                      color: isExpired
                                          ? Colors.red
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteInvite(inviteDoc.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return 'Unknown';
  }

  Future<void> _deleteInvite(String inviteId) async {
    try {
      await FirebaseFirestore.instance
          .collection('invites')
          .doc(inviteId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invite deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting invite: $e')));
      }
    }
  }
}
