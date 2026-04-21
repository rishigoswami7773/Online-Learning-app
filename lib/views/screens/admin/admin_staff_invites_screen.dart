import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'admin_widgets.dart';

class AdminStaffInvitesScreen extends StatefulWidget {
  const AdminStaffInvitesScreen({super.key});

  @override
  State<AdminStaffInvitesScreen> createState() =>
      _AdminStaffInvitesScreenState();
}

class _AdminStaffInvitesScreenState extends State<AdminStaffInvitesScreen> {
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
        'role': 'staff',
        'inviteId': inviteId,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'used': false,
        'createdBy': 'admin', // You might want to track which admin created it
      });

      // Generate invite URL
      final inviteUrl =
          'https://yourapp.com/register?role=staff&inviteId=$inviteId';

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Staff Invite Generated'),
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
      title: 'Staff Invites',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generate Staff Invite',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Staff Email Address',
                        hintText: 'Enter the email of the person to invite',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _expiryHoursCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Hours',
                        hintText: 'How many hours until the invite expires',
                        prefixIcon: Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isGenerating ? null : _generateInvite,
                        child: _isGenerating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Generate Invite'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Active Invites',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('invites')
                    .where('role', isEqualTo: 'staff')
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
                    return const Center(child: Text('No active staff invites'));
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

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            isExpired ? Icons.timer_off : Icons.link,
                            color: isExpired ? Colors.red : Colors.blue,
                          ),
                          title: Text(inviteData['email'] ?? 'Unknown email'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Created: ${_formatTimestamp(inviteData['createdAt'])}',
                              ),
                              Text(
                                isExpired
                                    ? 'Expired'
                                    : 'Expires: ${_formatTimestamp(expiresAt)}',
                                style: TextStyle(
                                  color: isExpired
                                      ? Colors.red
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteInvite(inviteDoc.id),
                          ),
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
