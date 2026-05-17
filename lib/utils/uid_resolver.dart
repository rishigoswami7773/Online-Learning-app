import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/app_auth_controller.dart';

class UidResolver {
  /// Returns the current user's uid from Firebase Auth if available,
  /// otherwise falls back to AppAuthController (dummy login).
  /// Returns null if no user is logged in at all.
  static String? get uid {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid != null) return firebaseUid;
    return AppAuthController().currentUser.value?.uid;
  }

  /// Returns true if any user is logged in (Firebase or dummy)
  static bool get isLoggedIn {
    return uid != null;
  }

  /// Returns the current user's role
  static String get role {
    return AppAuthController().currentUser.value?.role ?? 'student';
  }
}
