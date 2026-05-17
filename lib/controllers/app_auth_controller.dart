import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

/// Lightweight app-level auth wrapper that coexists with the project's existing
/// AuthController. It exposes `currentUser` as a `ValueNotifier<AppUser?>` so UI
/// can listen easily. Uses Firebase when available and provides demo accounts.
class AppAuthController {
  // Singleton
  static final AppAuthController _shared = AppAuthController._private();
  factory AppAuthController() => _shared;

  AppAuthController._private({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance {
    _init();
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Demo credentials for development/testing
  static const demoAdminEmail = 'admin@test.com';
  static const demoAdminPassword = '123456';
  static const demoMentorEmail = 'mentor@test.com';
  static const demoMentorPassword = '123456';

  // FIX: Track demo UIDs used so changePassword can detect them reliably.
  static const _demoUids = {'test-admin-uid', 'test-mentor-uid'};

  final ValueNotifier<AppUser?> currentUser = ValueNotifier<AppUser?>(null);
  final ValueNotifier<bool> isLoadingRole = ValueNotifier<bool>(false);

  void _init() {
    // Listen to Firebase auth state and keep notifier in sync.
    _auth.authStateChanges().listen((fbUser) {
      if (fbUser == null) {
        currentUser.value = null;
        isLoadingRole.value = false;
      } else {
        // Set a minimal user immediately so redirect can proceed.
        // Then asynchronously fetch the real role from Firestore.
        currentUser.value = AppUser(
          uid: fbUser.uid,
          email: fbUser.email ?? '',
          name: fbUser.displayName ?? 'User',
          role: 'student', // temporary placeholder
        );
        isLoadingRole.value = true;

        // Async fetch real role from Firestore.
        _firestore
            .collection('users')
            .doc(fbUser.uid)
            .get()
            .then((doc) {
              if (doc.exists) {
                final data = doc.data() ?? {};
                final appUser = AppUser.fromMap(fbUser.uid, data);
                currentUser.value = appUser;
              }
              // If doc doesn't exist, keep the placeholder (this shouldn't happen
              // for normal users, but demo accounts may not have docs on cold start).
            })
            .catchError((e) {
              debugPrint('Error fetching user role: $e');
              // Keep the placeholder user on error
            })
            .whenComplete(() {
              isLoadingRole.value = false;
            });
      }
    });
  }

  bool get isLoggedIn => currentUser.value != null;

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();

    // Hardcoded Test Accounts - Always succeed with '123456'
    if (password == '123456') {
      if (normalized == demoAdminEmail || normalized == demoMentorEmail) {
        final role = normalized == demoAdminEmail ? 'admin' : 'mentor';
        final name = normalized == demoAdminEmail ? 'Admin' : 'Mentor';

        try {
          // Step 1: Try to sign in with Firebase Auth
          final cred = await _auth
              .signInWithEmailAndPassword(email: normalized, password: password)
              .timeout(const Duration(seconds: 12));

          final fbUser = cred.user;
          if (fbUser == null) {
            return {'success': false, 'message': 'Authentication failed.'};
          }

          // Step 2: Ensure Firestore user doc exists (find or create)
          final existing = await _firestore
              .collection('users')
              .where('email', isEqualTo: normalized)
              .limit(1)
              .get();

          if (existing.docs.isEmpty) {
            // Create Firestore doc for this demo user
            await _firestore.collection('users').doc(fbUser.uid).set({
              'uid': fbUser.uid,
              'email': normalized,
              'name': name,
              'role': role,
              'isVerified': true,
              'status': 'active',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }

          // Step 3: Fetch or create Firestore user and return
          final doc = await _firestore
              .collection('users')
              .doc(fbUser.uid)
              .get();
          final data = doc.data() ?? {};
          final appUser = AppUser.fromMap(fbUser.uid, data);
          currentUser.value = appUser;

          final String route;
          if (appUser.role == 'admin') {
            route = '/admin_dashboard';
          } else if (appUser.role == 'mentor') {
            route = '/mentor_dashboard';
          } else {
            route = '/student_dashboard';
          }

          return {'success': true, 'nextRoute': route, 'user': appUser};
        } on FirebaseAuthException catch (e) {
          // If user doesn't exist, try to create it
          if (e.code == 'user-not-found') {
            try {
              final cred = await _auth
                  .createUserWithEmailAndPassword(
                    email: normalized,
                    password: password,
                  )
                  .timeout(const Duration(seconds: 12));

              final fbUser = cred.user;
              if (fbUser == null) {
                return {'success': false, 'message': 'Failed to create user.'};
              }

              // Create Firestore doc for this new demo user
              await _firestore.collection('users').doc(fbUser.uid).set({
                'uid': fbUser.uid,
                'email': normalized,
                'name': name,
                'role': role,
                'isVerified': true,
                'status': 'active',
                'createdAt': FieldValue.serverTimestamp(),
              });

              final doc = await _firestore
                  .collection('users')
                  .doc(fbUser.uid)
                  .get();
              final data = doc.data() ?? {};
              final appUser = AppUser.fromMap(fbUser.uid, data);
              currentUser.value = appUser;

              final String route;
              if (appUser.role == 'admin') {
                route = '/admin_dashboard';
              } else if (appUser.role == 'mentor') {
                route = '/mentor_dashboard';
              } else {
                route = '/student_dashboard';
              }

              return {'success': true, 'nextRoute': route, 'user': appUser};
            } catch (createErr) {
              // Fall through to normal sign-in path
              debugPrint('Demo account creation failed: $createErr');
            }
          }
          return {'success': false, 'message': e.message ?? 'Login failed'};
        } catch (e) {
          return {'success': false, 'message': 'Error: $e'};
        }
      }
    }

    try {
      final cred = await _auth
          .signInWithEmailAndPassword(email: normalized, password: password)
          .timeout(const Duration(seconds: 12));

      final fbUser = cred.user;
      if (fbUser == null) {
        return {'success': false, 'message': 'Authentication failed.'};
      }

      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      final data = doc.data() ?? {};
      final appUser = AppUser.fromMap(fbUser.uid, data);
      currentUser.value = appUser;

      final String route;
      if (appUser.role == 'admin') {
        route = '/admin_dashboard';
      } else if (appUser.role == 'mentor') {
        route = '/mentor_dashboard';
      } else {
        route = '/student_dashboard';
      }

      return {'success': true, 'nextRoute': route, 'user': appUser};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> signOut() async {
    try {
      currentUser.value = null;
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      await _auth.signOut().timeout(const Duration(seconds: 6));
      return {'success': true};
    } catch (e) {
      currentUser.value = null;
      return {'success': false, 'message': 'Sign out failed: $e'};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    User? fbUser = _auth.currentUser;
    try {
      if (fbUser != null) {
        await fbUser.reload();
        fbUser = _auth.currentUser;
        await fbUser?.getIdToken(true);
      }
    } catch (_) {}

    if (fbUser == null || fbUser.email == null) {
      return {
        'success': false,
        'message': 'Session expired. Please log out and log in again.',
      };
    }

    // FIX: Also check email-based demo accounts (not just 'demo-' uid prefix).
    // Demo accounts created via the dummy login path use 'test-admin-uid' /
    // 'test-mentor-uid', not 'demo-' prefixed uids.
    final isDemoAccount =
        fbUser.uid.startsWith('demo-') ||
        _demoUids.contains(fbUser.uid) ||
        fbUser.email == demoAdminEmail ||
        fbUser.email == demoMentorEmail;

    if (isDemoAccount) {
      return {
        'success': false,
        'message':
            'Demo accounts cannot change password. Please use a real account.',
      };
    }

    final providers = fbUser.providerData.map((p) => p.providerId).toList();
    if (!providers.contains('password')) {
      return {
        'success': false,
        'message':
            'Your account uses Google Sign-In. Change your password through your Google account.',
      };
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: fbUser.email!,
        password: currentPassword,
      );
      await fbUser
          .reauthenticateWithCredential(cred)
          .timeout(const Duration(seconds: 10));
      await fbUser
          .updatePassword(newPassword)
          .timeout(const Duration(seconds: 10));
      return {'success': true, 'message': 'Password updated.'};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        return {'success': false, 'message': 'Current password is incorrect.'};
      }
      if (e.code == 'requires-recent-login') {
        return {
          'success': false,
          'message': 'Session expired. Please log out and log in again.',
        };
      }
      if (e.code == 'weak-password') {
        return {
          'success': false,
          'message': 'New password is too weak (minimum 6 characters).',
        };
      }
      return {
        'success': false,
        'message': e.message ?? 'Password update failed.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> updates,
  }) async {
    final appUser = currentUser.value;
    if (appUser == null) {
      return {'success': false, 'message': 'No authenticated user.'};
    }

    try {
      if (appUser.uid.startsWith('demo-')) {
        final merged = AppUser(
          uid: appUser.uid,
          email: updates['email'] ?? appUser.email,
          name: updates['name'] ?? appUser.name,
          role: updates['role'] ?? appUser.role,
          profileImage: updates['profileImage'] ?? appUser.profileImage,
        );
        currentUser.value = merged;
        return {'success': true, 'user': merged};
      }

      await _firestore
          .collection('users')
          .doc(appUser.uid)
          .set(updates, SetOptions(merge: true))
          .timeout(const Duration(seconds: 8));
      final doc = await _firestore
          .collection('users')
          .doc(appUser.uid)
          .get()
          .timeout(const Duration(seconds: 6));
      final fresh = AppUser.fromMap(appUser.uid, doc.data() ?? {});
      currentUser.value = fresh;
      return {'success': true, 'user': fresh};
    } catch (e) {
      return {'success': false, 'message': 'Update failed: $e'};
    }
  }
}