import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../firebase_options.dart';
import 'admin_widgets.dart';

const Color _adminBlue = AdminColors.brand;

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen>
    with SingleTickerProviderStateMixin {
  final _usersRef = FirebaseFirestore.instance.collection('users');
  final _searchCtrl = TextEditingController();
  late final TabController _tabs;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allUsers = [];
  String _query = '';
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabs.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _filtered {
    return _allUsers.where((doc) {
      final d = doc.data();
      final name = (d['name'] ?? '').toString().toLowerCase();
      final email = (d['email'] ?? '').toString().toLowerCase();
      final role = (d['role'] ?? 'student').toString().toLowerCase();
      final matchQ =
          _query.isEmpty || name.contains(_query) || email.contains(_query);
      final matchR = _roleFilter == 'all' || role == _roleFilter;
      return matchQ && matchR;
    }).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _pendingUsers =>
      _allUsers.where((d) => d.data()['status'] == 'pending').toList();

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'mentor':
        return AdminColors.accent;
      case 'admin':
        return AdminColors.brand;
      default:
        return AdminColors.textSecondary;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'blocked':
        return Colors.red;
      default:
        return AdminColors.brand;
    }
  }

  Widget _pill(String label, Color color) {
    return adminPill(label, color);
  }

  Future<void> _setStatus(String docId, String status) async {
    try {
      final isBlocked = status == 'blocked';
      await _usersRef.doc(docId).update({
        'status': status,
        'isBlocked': isBlocked,
      });
      if (!mounted) return;
      final msg = isBlocked ? 'User blocked' : 'User unblocked / approved';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _setRole(String docId, String currentRole) async {
    final roles = ['student', 'mentor', 'admin'];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Change Role'),
        children: roles
            .map(
              (r) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, r),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: _roleColor(r)),
                    const SizedBox(width: 8),
                    Text(
                      r,
                      style: TextStyle(
                        fontWeight: r == currentRole
                            ? FontWeight.w800
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null || selected == currentRole) return;
    try {
      await _usersRef.doc(docId).update({'role': selected});
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Role changed to $selected')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Permanently delete "${doc.data()['email']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await doc.reference.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _userCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final name = (d['name'] ?? 'No name').toString();
    final email = (d['email'] ?? '').toString();
    final role = (d['role'] ?? 'student').toString();
    final status = (d['status'] ?? 'active').toString();
    final isBlocked = status == 'blocked';
    final isPending = status == 'pending';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return adminListCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AdminColors.brandSoft,
                child: Text(
                  initial,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      email,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _pill(role, _roleColor(role)),
                  const SizedBox(height: 4),
                  _pill(status, _statusColor(status)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isBlocked)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _setStatus(doc.id, 'active'),
                    icon: const Icon(Icons.lock_open, size: 14),
                    label: const Text(
                      'Unblock',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.brand,
                      side: const BorderSide(color: AdminColors.brand),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _setStatus(doc.id, 'blocked'),
                    icon: const Icon(Icons.block, size: 14),
                    label: const Text('Block', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              if (isPending)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _setStatus(doc.id, 'active'),
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text(
                      'Approve',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _setRole(doc.id, role),
                    icon: const Icon(Icons.manage_accounts, size: 14),
                    label: const Text('Role', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _adminBlue,
                      side: BorderSide(color: _adminBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _delete(doc),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                ),
                child: const Icon(Icons.delete_outline, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Creates a Firebase Auth account using a secondary app instance so the
  /// admin session is never interrupted, then writes the Firestore user doc.
  Future<_AddUserResult> _createUserDirectly({
    required String email,
    required String name,
    required String role,
    required String password,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // Use a unique name to avoid conflicts with concurrent calls
      final appName = 'admin_create_${DateTime.now().millisecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Try creating the new account on the secondary app
      UserCredential credential;
      bool existed = false;
      try {
        credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Account exists — sign in to get UID, then update role
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

      // Update display name
      await credential.user!.updateDisplayName(name);

      // Write Firestore user document
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

      return _AddUserResult(uid: uid, existed: existed, password: password);
    } finally {
      if (secondaryApp != null) {
        try {
          await FirebaseAuth.instanceFor(app: secondaryApp).signOut();
        } catch (_) {}
        await secondaryApp.delete();
      }
    }
  }

  Future<void> _showAddUserDialog(BuildContext context) async {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'mentor';
    bool isLoading = false;
    bool obscurePwd = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Add New User',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role *',
                    prefixIcon: Icon(Icons.manage_accounts_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'student',
                      child: Text('Student'),
                    ),
                    DropdownMenuItem(
                      value: 'mentor',
                      child: Text('Mentor'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Admin'),
                    ),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedRole = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscurePwd,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    hintText: 'Min 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePwd
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setDialogState(() => obscurePwd = !obscurePwd),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AdminColors.brand,
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      final email =
                          emailCtrl.text.trim().toLowerCase();
                      final name = nameCtrl.text.trim();
                      final pwd = passwordCtrl.text.trim();
                      final role = selectedRole;

                      if (email.isEmpty || name.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Email and name are required'),
                          ),
                        );
                        return;
                      }
                      if (pwd.length < 6) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password must be at least 6 characters',
                            ),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final result = await _createUserDirectly(
                          email: email,
                          name: name,
                          role: role,
                          password: pwd,
                        );

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);

                        final msg = result.existed
                            ? 'Account already existed.\n'
                                'Role updated to "$role".\n\n'
                                'Email: $email\nPassword: $pwd'
                            : 'Account created successfully!\n\n'
                                'Email: $email\n'
                                'Password: $pwd\n'
                                'Role: $role\n\n'
                                'Share these credentials with the user.';

                        if (!mounted) return;
                        _showResultDialog(
                          context,
                          result.existed ? 'Role Updated' : 'User Created',
                          msg,
                        );
                      } on FirebaseAuthException catch (e) {
                        if (!ctx.mounted) return;
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.message ?? 'Failed to create user',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } catch (e) {
                        if (!ctx.mounted) return;
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: isLoading
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
        ),
      ),
    );

    emailCtrl.dispose();
    nameCtrl.dispose();
    passwordCtrl.dispose();
  }

  void _showResultDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SelectableText(message),
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

  @override
  Widget build(BuildContext context) {
    return AdminPageWrapper(
      title: 'Manage Users',
      showBackButton: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context),
        backgroundColor: AdminColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: adminHeroHeader(
              title: 'Manage Users',
              subtitle: 'Search, filter, approve, and assign roles',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                adminSearchField(
                  controller: _searchCtrl,
                  hintText: 'Search by name or email...',
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final role in ['all', 'student', 'mentor', 'admin'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(role == 'all' ? 'All' : role),
                            selected: _roleFilter == role,
                            selectedColor: AdminColors.brandSoft,
                            labelStyle: TextStyle(
                              color: _roleFilter == role
                                  ? AdminColors.brand
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) =>
                                setState(() => _roleFilter = role),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _usersRef
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: 5,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, _) => ShimmerBox(
                      width: double.infinity,
                      height: 110,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  );
                }
                if (snap.hasError) {
                  return _UsersListFallback(
                    usersRef: _usersRef,
                    filtered: _filtered,
                    pendingUsers: _pendingUsers,
                    onAllUsers: (u) {
                      _allUsers = u;
                    },
                    userCard: _userCard,
                    pill: _pill,
                  );
                }
                _allUsers = snap.data?.docs ?? [];
                final filtered = _filtered;
                final pending = _pendingUsers;

                return Column(
                  children: [
                    if (pending.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const PulseDot(color: Colors.red, size: 8),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${pending.length} user(s) pending approval',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${filtered.length} users',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.manage_accounts_outlined,
                                    size: 56,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text('No users found.'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => StaggeredItem(
                                delay: Duration(milliseconds: i * 40),
                                child: _userCard(filtered[i]),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Fallback widget for when Firestore index is missing
class _UsersListFallback extends StatelessWidget {
  final CollectionReference<Map<String, dynamic>> usersRef;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> pendingUsers;
  final void Function(List<QueryDocumentSnapshot<Map<String, dynamic>>>)
  onAllUsers;
  final Widget Function(QueryDocumentSnapshot<Map<String, dynamic>>) userCard;
  final Widget Function(String, Color) pill;

  const _UsersListFallback({
    required this.usersRef,
    required this.filtered,
    required this.pendingUsers,
    required this.onAllUsers,
    required this.userCard,
    required this.pill,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: usersRef.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        onAllUsers(docs);
        if (filtered.isEmpty) {
          return const Center(
            child: Text(
              'No users found.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          itemCount: filtered.length,
          itemBuilder: (_, i) => StaggeredItem(
            delay: Duration(milliseconds: i * 40),
            child: userCard(filtered[i]),
          ),
        );
      },
    );
  }
}

class _AddUserResult {
  final String uid;
  final bool existed;
  final String password;
  const _AddUserResult({
    required this.uid,
    required this.existed,
    required this.password,
  });
}
