import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_widgets.dart';

class AdminMentorPanelScreen extends StatefulWidget {
  const AdminMentorPanelScreen({super.key});

  @override
  State<AdminMentorPanelScreen> createState() => _AdminMentorPanelScreenState();
}

class _AdminMentorPanelScreenState extends State<AdminMentorPanelScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterRole = 'all';

  // Trigger rebuild of FutureBuilder when data changes
  int _refreshKey = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Load mentors from BOTH the `users` collection (role=mentor/Mentor/admin/Admin)
  /// and the `mentors` collection, then merge/deduplicate by email.
  Future<List<Map<String, dynamic>>> _loadMentors() async {
    // Roles to query based on filter
    List<String> roleValues;
    if (_filterRole == 'all') {
      roleValues = ['mentor', 'Mentor', 'admin', 'Admin'];
    } else {
      final cap = _filterRole[0].toUpperCase() + _filterRole.substring(1);
      roleValues = [_filterRole, cap];
    }

    final Map<String, Map<String, dynamic>> byEmail = {};

    QuerySnapshot<Map<String, dynamic>>? usersSnap;
    QuerySnapshot<Map<String, dynamic>>? mentorsSnap;

    try {
      usersSnap = await _firestore
          .collection('users')
          .where('role', whereIn: roleValues)
          .get();
    } catch (_) {
      usersSnap = null;
    }

    try {
      mentorsSnap = await _firestore.collection('mentors').get();
    } catch (_) {
      mentorsSnap = null;
    }

    // Insert users first (preferred source)
    if (usersSnap != null) {
      for (final doc in usersSnap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['_docId'] = doc.id;
        data['_source'] = 'users';
        final email = (data['email'] ?? doc.id).toString().toLowerCase();
        byEmail[email] = data;
      }
    }

    // Merge mentors collection (add only if not already present by email)
    if (mentorsSnap != null) {
      for (final doc in mentorsSnap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['_docId'] = doc.id;
        data['_source'] = 'mentors';
        final email = (data['email'] ?? doc.id).toString().toLowerCase();
        // If filter is 'all' or matches role, include from mentors collection too
        final role = (data['role'] ?? 'mentor').toString().toLowerCase();
        if (_filterRole != 'all' && role != _filterRole.toLowerCase()) continue;
        if (!byEmail.containsKey(email)) {
          byEmail[email] = data;
        }
      }
    }

    // Apply search filter
    final query = _searchQuery.toLowerCase();
    return byEmail.values.where((data) {
      if (query.isEmpty) return true;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final dept = (data['department'] ?? '').toString().toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          dept.contains(query);
    }).toList()..sort((a, b) {
      final aName = (a['name'] ?? '').toString();
      final bName = (b['name'] ?? '').toString();
      return aName.compareTo(bName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageWrapper(
      title: 'Mentor Management',
      showBackButton: true,
      actions: [
        FilledButton.icon(
          onPressed: () => _showAddMentorDialog(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Mentor'),
        ),
        const SizedBox(width: 8),
      ],
      child: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or department…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.toLowerCase()),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRoleFilter('all', 'All'),
                      _buildRoleFilter('mentor', 'Mentor'),
                      _buildRoleFilter('admin', 'Admin'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              // _refreshKey changes trigger a fresh Future
              key: ValueKey(_refreshKey),
              future: _loadMentors(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final mentors = snapshot.data ?? [];

                if (mentors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text('No mentors found'),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => _showAddMentorDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Mentor'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() => _refreshKey++),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: mentors.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final data = mentors[index];
                      final docId = data['_docId'] as String? ?? '';
                      final source = data['_source'] as String? ?? 'users';
                      final ref = _firestore.collection(source).doc(docId);
                      return _buildMentorCard(context, ref, data);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilter(String value, String label) {
    final isSelected = _filterRole == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() {
          _filterRole = value;
          _refreshKey++;
        }),
      ),
    );
  }

  Widget _buildMentorCard(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> data,
  ) {
    final name = (data['name'] ?? 'Unknown').toString();
    final email = (data['email'] ?? '').toString();
    final role = (data['role'] ?? 'mentor').toString();
    final dept = (data['department'] ?? 'N/A').toString();
    final designation = (data['designation'] ?? 'N/A').toString();
    final photo = (data['photoURL'] ?? data['profileImage'] ?? '').toString();
    final isBlocked = data['isBlocked'] == true;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?'; // null-safe

    final roleColor = _getRoleColor(role);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
          backgroundColor: roleColor.withAlpha(50),
          child: photo.isEmpty ? Text(initial) : null,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              '$dept • $designation',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        trailing: isBlocked
            ? Chip(
                label: const Text('Blocked'),
                backgroundColor: Colors.red.withAlpha(50),
                labelStyle: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Chip(
                label: Text(role.toUpperCase()),
                backgroundColor: roleColor.withAlpha(50),
                labelStyle: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
        onTap: () => _showMentorDetailsDialog(context, ref, data),
        onLongPress: () => _showMentorOptionsMenu(context, ref, data),
      ),
    );
  }

  void _showMentorDetailsDialog(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mentor Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', (data['name'] ?? '-').toString()),
              _buildDetailRow('Email', (data['email'] ?? '-').toString()),
              _buildDetailRow('Phone', (data['phone'] ?? '-').toString()),
              _buildDetailRow('Role', (data['role'] ?? '-').toString()),
              _buildDetailRow(
                'Department',
                (data['department'] ?? '-').toString(),
              ),
              _buildDetailRow(
                'Designation',
                (data['designation'] ?? '-').toString(),
              ),
              _buildDetailRow('Gender', (data['gender'] ?? '-').toString()),
              _buildDetailRow(
                'Employment Type',
                (data['employmentType'] ?? '-').toString(),
              ),
              _buildDetailRow(
                'Status',
                (data['isBlocked'] == true) ? 'Blocked' : 'Active',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showEditMentorDialog(context, ref, data);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  void _showEditMentorDialog(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> data,
  ) {
    final nameCtr = TextEditingController(
      text: (data['name'] ?? '').toString(),
    );
    final emailCtr = TextEditingController(
      text: (data['email'] ?? '').toString(),
    );
    final phoneCtr = TextEditingController(
      text: (data['phone'] ?? '').toString(),
    );
    final deptCtr = TextEditingController(
      text: (data['department'] ?? '').toString(),
    );
    final desgCtr = TextEditingController(
      text: (data['designation'] ?? '').toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Mentor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtr,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailCtr,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: phoneCtr,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: deptCtr,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              TextField(
                controller: desgCtr,
                decoration: const InputDecoration(labelText: 'Designation'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref.update({
                  'name': nameCtr.text.trim(),
                  'email': emailCtr.text.trim(),
                  'phone': phoneCtr.text.trim(),
                  'department': deptCtr.text.trim(),
                  'designation': desgCtr.text.trim(),
                });
                if (!context.mounted) return;
                Navigator.pop(ctx);
                setState(() => _refreshKey++);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Mentor updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMentorOptionsMenu(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> data,
  ) {
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditMentorDialog(context, ref, data);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.block,
                color: (data['isBlocked'] == true) ? Colors.green : Colors.red,
              ),
              title: Text((data['isBlocked'] == true) ? 'Unblock' : 'Block'),
              onTap: () async {
                try {
                  await ref.update({'isBlocked': !(data['isBlocked'] == true)});
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  setState(() => _refreshKey++);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        (data['isBlocked'] == true)
                            ? '✅ Mentor unblocked'
                            : '✅ Mentor blocked',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirmation(context, ref, data);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> data,
  ) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Mentor?'),
        content: Text(
          'Are you sure you want to delete ${(data['name'] ?? 'this mentor')}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref.delete();
                if (!context.mounted) return;
                Navigator.pop(ctx);
                setState(() => _refreshKey++);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Mentor deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddMentorDialog(BuildContext context) {
    final nameCtr = TextEditingController();
    final emailCtr = TextEditingController();
    final phoneCtr = TextEditingController();
    final deptCtr = TextEditingController();
    final desgCtr = TextEditingController();
    String selectedRole = 'mentor';

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Add New Mentor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtr,
                  decoration: const InputDecoration(labelText: 'Full Name *'),
                ),
                TextField(
                  controller: emailCtr,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email *'),
                ),
                TextField(
                  controller: phoneCtr,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                TextField(
                  controller: deptCtr,
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
                TextField(
                  controller: desgCtr,
                  decoration: const InputDecoration(labelText: 'Designation'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: ['mentor', 'admin']
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setDlgState(() => selectedRole = val ?? 'mentor'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtr.text.trim().isEmpty ||
                    emailCtr.text.trim().isEmpty) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name and Email are required'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                try {
                  final docRef = _firestore.collection('users').doc();
                  await docRef.set({
                    'userId': docRef.id,
                    'name': nameCtr.text.trim(),
                    'email': emailCtr.text.trim(),
                    'phone': phoneCtr.text.trim(),
                    'department': deptCtr.text.trim(),
                    'designation': desgCtr.text.trim(),
                    'role': selectedRole,
                    'createdAt': FieldValue.serverTimestamp(),
                    'isBlocked': false,
                    'profileImage': '',
                    'bio': '',
                    'isVerified': true,
                  });

                  // Also write to mentors collection
                  await _firestore.collection('mentors').doc(docRef.id).set({
                    'userId': docRef.id,
                    'name': nameCtr.text.trim(),
                    'email': emailCtr.text.trim(),
                    'phone': phoneCtr.text.trim(),
                    'department': deptCtr.text.trim(),
                    'designation': desgCtr.text.trim(),
                    'role': selectedRole,
                    'createdAt': FieldValue.serverTimestamp(),
                    'isBlocked': false,
                    'photoURL': '',
                    'bio': '',
                  });

                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  setState(() => _refreshKey++);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Mentor added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'mentor':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
