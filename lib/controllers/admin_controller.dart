import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Lightweight controller used by the Admin shell to verify role and expose
/// a simple ValueNotifier for UI code. This keeps role-check logic in one
/// place for future expansion (permissions, caching, server-side checks).
class AdminController {
  AdminController._();
  static final AdminController instance = AdminController._();

  final ValueNotifier<bool?> isAdmin = ValueNotifier<bool?>(null);
  final ValueNotifier<String?> role = ValueNotifier<String?>(null);

  /// Checks the currently signed-in Firebase user and verifies their role
  /// by reading the `users/{uid}` document. Returns true if role == 'admin'.
  Future<bool> checkAdminAccess() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        isAdmin.value = false;
        role.value = null;
        return false;
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        isAdmin.value = false;
        role.value = null;
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final r = (data['role'] ?? '').toString().trim().toLowerCase();
      role.value = r;
      final ok = r == 'admin';
      isAdmin.value = ok;
      return ok;
    } catch (e) {
      // On any error treat as non-admin to be safe.
      isAdmin.value = false;
      role.value = null;
      if (kDebugMode) debugPrint('AdminController.checkAdminAccess error: $e');
      return false;
    }
  }
}
