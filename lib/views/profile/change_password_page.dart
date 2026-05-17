import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_routes.dart';

void _safeBackToProfile(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    // Fallback to student profile; the router will redirect based on role
    context.go(AppRoutes.studentProfile);
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPwd = TextEditingController();
  final _confirm = TextEditingController();

  bool _submitting = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _current.dispose();
    _newPwd.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _doChangePassword(
    String currentPassword,
    String newPassword,
  ) async {
    User? fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null || fbUser.email == null) {
      return {
        'success': false,
        'message': 'Session expired. Please log out and log in again.',
      };
    }

    try {
      // Refresh token
      await fbUser.reload();
      fbUser = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    if (fbUser == null || fbUser.email == null) {
      return {
        'success': false,
        'message': 'Session expired. Please log out and log in again.',
      };
    }

    // Check if Google-only account (no email/password provider)
    final providers = fbUser.providerData.map((p) => p.providerId).toList();
    final isGoogleOnly =
        providers.isNotEmpty && !providers.contains('password');
    if (isGoogleOnly) {
      return {
        'success': false,
        'message':
            'Your account uses Google Sign-In. Change your password through your Google account settings.',
      };
    }

    // Reauthenticate and update
    try {
      final cred = EmailAuthProvider.credential(
        email: fbUser.email!,
        password: currentPassword,
      );
      await fbUser
          .reauthenticateWithCredential(cred)
          .timeout(const Duration(seconds: 15));
      await fbUser
          .updatePassword(newPassword)
          .timeout(const Duration(seconds: 15));
      return {'success': true, 'message': 'Password updated successfully.'};
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return {
            'success': false,
            'message': 'Current password is incorrect.',
          };
        case 'requires-recent-login':
          return {
            'success': false,
            'message':
                'Session expired. Please log out and log in again, then retry.',
          };
        case 'weak-password':
          return {
            'success': false,
            'message': 'New password is too weak. Use at least 6 characters.',
          };
        default:
          return {
            'success': false,
            'message': e.message ?? 'Password update failed.',
          };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_newPwd.text != _confirm.text) {
      _showSnack('Passwords do not match.', success: false);
      return;
    }

    setState(() => _submitting = true);
    final res = await _doChangePassword(_current.text, _newPwd.text);
    if (!mounted) return;
    setState(() => _submitting = false);

    final ok = res['success'] == true;
    _showSnack(
      (res['message'] ?? (ok ? 'Password updated.' : 'Failed.')).toString(),
      success: ok,
    );
    if (ok) _safeBackToProfile(context);
  }

  void _showSnack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _safeBackToProfile(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Change Password'),
          leading: BackButton(onPressed: () => _safeBackToProfile(context)),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 44,
                            color: Color(0xFF0E7C86),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Change Password',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // Current password
                          TextFormField(
                            controller: _current,
                            obscureText: !_showCurrent,
                            decoration: InputDecoration(
                              labelText: 'Current Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showCurrent
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _showCurrent = !_showCurrent,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Current password is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          // New password
                          TextFormField(
                            controller: _newPwd,
                            obscureText: !_showNew,
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: const Icon(Icons.lock_open_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showNew
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () =>
                                    setState(() => _showNew = !_showNew),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'At least 6 characters'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          // Confirm password
                          TextFormField(
                            controller: _confirm,
                            obscureText: !_showConfirm,
                            decoration: InputDecoration(
                              labelText: 'Confirm New Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _showConfirm = !_showConfirm,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Please confirm your new password'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0E7C86),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Update Password',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => _safeBackToProfile(context),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
