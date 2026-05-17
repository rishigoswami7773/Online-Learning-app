import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import '../../../firebase_options.dart';
import 'admin_widgets.dart';

void _safeBackToAdminHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.adminHome);
  }
}

class AdminManageUsersScreenNew extends StatefulWidget {
  const AdminManageUsersScreenNew({super.key});

  @override
  State<AdminManageUsersScreenNew> createState() =>
      _AdminManageUsersScreenNewState();
}

class _AdminManageUsersScreenNewState extends State<AdminManageUsersScreenNew> {
  final _searchCtrl = TextEditingController();
  String _filterRole = 'all';
  String _filterStatus = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _safeBackToAdminHome(context);
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _safeBackToAdminHome(context);
            },
          ),
          title: const Text('Manage Users'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddUserDialog(),
          backgroundColor: AdminColors.brand,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add),
          label: const Text('Add User'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              adminSearchField(
                controller: _searchCtrl,
                hintText: 'Search users by name or email...',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Filters
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _filterRole,
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All Roles'),
                        ),
                        DropdownMenuItem(
                          value: 'student',
                          child: Text('Students'),
                        ),
                        DropdownMenuItem(
                          value: 'mentor',
                          child: Text('Mentors'),
                        ),
                        DropdownMenuItem(value: 'admin', child: Text('Admins')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _filterRole = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _filterStatus,
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All Status'),
                        ),
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'inactive',
                          child: Text('Inactive'),
                        ),
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pending Approval'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _filterStatus = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Users List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No users found'));
                    }

                    final query = _searchCtrl.text.toLowerCase();
                    var users = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '')
                          .toString()
                          .toLowerCase();
                      final email = (data['email'] ?? '')
                          .toString()
                          .toLowerCase();
                      final role = (data['role'] ?? 'user').toString();
                      final status = (data['status'] ?? 'active').toString();

                      final matchQuery =
                          name.contains(query) || email.contains(query);
                      final matchRole =
                          _filterRole == 'all' || role == _filterRole;
                      final matchStatus =
                          _filterStatus == 'all' || status == _filterStatus;

                      return matchQuery && matchRole && matchStatus;
                    }).toList();

                    if (users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            const Text('No users matching filters'),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, idx) {
                        final doc = users[idx];
                        final data = doc.data() as Map<String, dynamic>;
                        final uid = doc.id;
                        final name = data['name'] ?? 'User';
                        final email = data['email'] ?? 'No email';
                        final role = data['role'] ?? 'user';
                        final status = data['status'] ?? 'active';

                        return adminListCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AdminColors.brandSoft,
                                child: Text(
                                  (name.isNotEmpty)
                                      ? name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: AdminColors.brand,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      email,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton(
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    child: const Text('Edit'),
                                    onTap: () =>
                                        _showEditDialog(context, uid, data),
                                  ),
                                  PopupMenuItem(
                                    child: const Text('Change Role'),
                                    onTap: () =>
                                        _showRoleDialog(context, uid, role),
                                  ),
                                  if (status != 'active')
                                    PopupMenuItem(
                                      child: const Text('Approve'),
                                      onTap: () async {
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(uid)
                                            .update({'status': 'active'});
                                      },
                                    ),
                                  PopupMenuItem(
                                    child: const Text('Delete'),
                                    onTap: () =>
                                        _showDeleteDialog(context, uid),
                                  ),
                                ],
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
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String uid,
    Map<String, dynamic> data,
  ) {
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final emailCtrl = TextEditingController(text: data['email'] ?? '');
    final phoneCtrl = TextEditingController(text: data['phone'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({
                    'name': nameCtrl.text,
                    'email': emailCtrl.text,
                    'phone': phoneCtrl.text,
                  });
              if (ctx.mounted) ctx.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.brand,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRoleDialog(BuildContext context, String uid, String currentRole) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final role in ['student', 'mentor', 'admin'])
              RadioMenuButton<String>(
                value: role,
                groupValue: currentRole,
                onChanged: (v) async {
                  if (v != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({'role': v});
                    if (ctx.mounted) ctx.pop();
                  }
                },
                child: Text(role[0].toUpperCase() + role.substring(1)),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .delete();

              final batch = FirebaseFirestore.instance.batch();

              final enrollments = await FirebaseFirestore.instance
                  .collection('enrollments')
                  .where('studentId', isEqualTo: uid)
                  .get();
              for (final doc in enrollments.docs) {
                batch.delete(doc.reference);
              }

              final notifs = await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('recipientId', isEqualTo: uid)
                  .get();
              for (final doc in notifs.docs) {
                batch.delete(doc.reference);
              }

              final conversations = await FirebaseFirestore.instance
                  .collection('chat_conversations')
                  .where('studentId', isEqualTo: uid)
                  .get();
              for (final doc in conversations.docs) {
                batch.delete(doc.reference);
              }

              await batch.commit();
              if (ctx.mounted) ctx.pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddUserDialog() async {
    final result = await showDialog<_AddUserResult?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AddUserDialog(),
    );
    if (result == null || !mounted) return;

    final title = result.existed ? 'Role Updated' : 'User Created';
    final msg = result.existed
        ? 'Account already existed.\n'
            'Role updated to "${result.role}".\n\n'
            'Email: ${result.email}\nPassword: ${result.password}'
        : 'Account created successfully!\n\n'
            'Email: ${result.email}\n'
            'Password: ${result.password}\n'
            'Role: ${result.role}\n\n'
            'Share these credentials with the user.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SelectableText(msg),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.brand,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ── Add User dialog as a proper StatefulWidget to avoid StatefulBuilder
// context/lifecycle issues in async callbacks ──────────────────────────

Future<_AddUserResult> _createUserDirectly({
  required String email,
  required String name,
  required String role,
  required String password,
}) async {
  FirebaseApp? secondaryApp;
  try {
    final appName = 'admin_create_${DateTime.now().millisecondsSinceEpoch}';
    secondaryApp = await Firebase.initializeApp(
      name: appName,
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    UserCredential credential;
    bool existed = false;
    try {
      credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        credential = await secondaryAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        existed = true;
      } else {
        rethrow;
      }
    }

    final uid = credential.user!.uid;
    await credential.user!.updateDisplayName(name);

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'isVerified': true,
      'status': 'active',
      'isBlocked': false,
      'profileImage': '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return _AddUserResult(
      uid: uid,
      existed: existed,
      email: email,
      role: role,
      password: password,
    );
  } finally {
    if (secondaryApp != null) {
      try {
        await FirebaseAuth.instanceFor(app: secondaryApp).signOut();
      } catch (_) {}
      await secondaryApp.delete();
    }
  }
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog();

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'mentor';
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final name = _nameCtrl.text.trim();
    final pwd = _passwordCtrl.text.trim();

    if (email.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and name are required')),
      );
      return;
    }
    if (pwd.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await _createUserDirectly(
        email: email,
        name: name,
        role: _role,
        password: pwd,
      );
      if (!mounted) return;
      Navigator.pop(context, result);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to create user'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Add New User',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Role *',
                prefixIcon: Icon(Icons.manage_accounts_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'mentor', child: Text('Mentor')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password *',
                hintText: 'Min 6 characters',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AdminColors.brand),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create Account'),
        ),
      ],
    );
  }
}

class _AddUserResult {
  final String uid;
  final bool existed;
  final String password;
  final String email;
  final String role;
  const _AddUserResult({
    required this.uid,
    required this.existed,
    required this.password,
    required this.email,
    required this.role,
  });
}
