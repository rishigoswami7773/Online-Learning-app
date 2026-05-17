import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'dart:math';

import 'profile_controller.dart';
import 'student_controller.dart';
import 'app_auth_controller.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';

class LoginResult {
  LoginResult({this.success = false, this.nextRoute, this.message, this.role});

  final bool success;
  final String? nextRoute;
  final String? message;
  final String? role;
}

class OtpResult {
  OtpResult({
    this.success = false,
    this.message,
    this.debugOtp,
    this.verificationToken,
  });

  final bool success;
  final String? message;
  final String? debugOtp;
  final String? verificationToken;
}

class RegistrationResult {
  RegistrationResult({this.success = false, this.message, this.nextRoute});

  final bool success;
  final String? message;
  final String? nextRoute;
}

class AuthActionResult {
  AuthActionResult({this.success = false, this.message});

  final bool success;
  final String? message;
}

class AuthController {
  static const String mentorEmail = 'mentor@test.com';
  static const String mentorPassword = '123456';
  static const String adminEmail = 'admin@test.com';
  static const String adminPassword = '123456';

  static String? _activeDummyRole;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final StudentController _studentController;
  final ProfileController _profileController;

  AuthController({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    StudentController? studentController,
    ProfileController? profileController,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _studentController = studentController ?? StudentController(),
       _profileController = profileController ?? ProfileController();

  static String? get activeDummyRole => _activeDummyRole;

  String _otpDocId(String email) => email.trim().toLowerCase();

  Future<void> _fixMentorDataSilently(String realUid, String email) async {
    // Only run for mentor accounts
    if (!email.contains('mentor')) return;

    final batch = _firestore.batch();
    int updates = 0;

    // Fix courses
    final courses = await _firestore
        .collection('courses')
        .where('mentorId', isGreaterThanOrEqualTo: 'mentor_')
        .where('mentorId', isLessThan: 'mentor`')
        .get();
    for (final doc in courses.docs) {
      batch.update(doc.reference, {'mentorId': realUid});
      updates++;
    }

    // Fix notifications recipientId
    final notifs = await _firestore
        .collection('notifications')
        .where('recipientId', isGreaterThanOrEqualTo: 'mentor_')
        .where('recipientId', isLessThan: 'mentor`')
        .get();
    for (final doc in notifs.docs) {
      batch.update(doc.reference, {'recipientId': realUid});
      updates++;
    }

    // Fix reviews mentorId
    final reviews = await _firestore
        .collection('course_reviews')
        .where('mentorId', isGreaterThanOrEqualTo: 'mentor_')
        .where('mentorId', isLessThan: 'mentor`')
        .get();
    for (final doc in reviews.docs) {
      batch.update(doc.reference, {'mentorId': realUid});
      updates++;
    }

    // Fix conversations mentorId
    final convos = await _firestore
        .collection('chat_conversations')
        .where('mentorId', isGreaterThanOrEqualTo: 'mentor_')
        .where('mentorId', isLessThan: 'mentor`')
        .get();
    for (final doc in convos.docs) {
      batch.update(doc.reference, {'mentorId': realUid});
      updates++;
    }

    // Fix enrollments mentorId if field exists
    final enrollments = await _firestore
        .collection('enrollments')
        .where('mentorId', isGreaterThanOrEqualTo: 'mentor_')
        .where('mentorId', isLessThan: 'mentor`')
        .get();
    for (final doc in enrollments.docs) {
      batch.update(doc.reference, {'mentorId': realUid});
      updates++;
    }

    if (updates > 0) await batch.commit();

    // Migrate old placeholder user doc to real uid doc
    final oldMentorDocs = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'mentor')
        .get();
    for (final doc in oldMentorDocs.docs) {
      if (doc.id.startsWith('mentor_')) {
        await _firestore
            .collection('users')
            .doc(realUid)
            .set(doc.data(), SetOptions(merge: true));
        await doc.reference.delete();
      }
    }
  }

  Future<void> _fixStudentDataSilently(String realUid, String email) async {
    if (!email.contains('student')) return;
    final batch = _firestore.batch();
    int updates = 0;

    final enrollments = await _firestore
        .collection('enrollments')
        .where('studentId', isGreaterThanOrEqualTo: 'student_')
        .where('studentId', isLessThan: 'student`')
        .get();
    for (final doc in enrollments.docs) {
      batch.update(doc.reference, {'studentId': realUid});
      updates++;
    }

    final notifs = await _firestore
        .collection('notifications')
        .where('recipientId', isGreaterThanOrEqualTo: 'student_')
        .where('recipientId', isLessThan: 'student`')
        .get();
    for (final doc in notifs.docs) {
      batch.update(doc.reference, {'recipientId': realUid});
      updates++;
    }

    final convos = await _firestore
        .collection('chat_conversations')
        .where('studentId', isGreaterThanOrEqualTo: 'student_')
        .where('studentId', isLessThan: 'student`')
        .get();
    for (final doc in convos.docs) {
      batch.update(doc.reference, {'studentId': realUid});
      updates++;
    }

    if (updates > 0) await batch.commit();

    // Migrate old placeholder user docs
    final oldStudentDocs = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();
    for (final doc in oldStudentDocs.docs) {
      if (doc.id.startsWith('student_')) {
        await _firestore
            .collection('users')
            .doc(realUid)
            .set(doc.data(), SetOptions(merge: true));
        await doc.reference.delete();
      }
    }
  }

  Future<OtpResult> sendOtp({
    required String email,
    required String phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = phone.trim();

    if (normalizedEmail.isEmpty || normalizedPhone.isEmpty) {
      return OtpResult(success: false, message: 'Email and phone are required');
    }

    final otp = (Random().nextInt(900000) + 100000).toString();
    final expiresAt = Timestamp.fromDate(
      DateTime.now().add(const Duration(minutes: 5)),
    );

    await _firestore
        .collection('otp_verifications')
        .doc(_otpDocId(normalizedEmail))
        .set({
          'email': normalizedEmail,
          'phone': normalizedPhone,
          'otp': otp,
          'isVerified': false,
          'isConsumed': false,
          'expiresAt': expiresAt,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    return OtpResult(
      success: true,
      message: 'OTP sent successfully. It expires in 5 minutes.',
      // Development-only fallback until SMS/Email gateway is integrated.
      debugOtp: otp,
      verificationToken: _otpDocId(normalizedEmail),
    );
  }

  Future<OtpResult> verifyOTP({
    required String email,
    required String otp,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final enteredOtp = otp.trim();

    if (normalizedEmail.isEmpty || enteredOtp.isEmpty) {
      return OtpResult(success: false, message: 'Email and OTP are required');
    }

    final doc = await _firestore
        .collection('otp_verifications')
        .doc(_otpDocId(normalizedEmail))
        .get();

    if (!doc.exists) {
      return OtpResult(
        success: false,
        message: 'No OTP request found. Please send OTP first.',
      );
    }

    final data = doc.data()!;
    final dbOtp = (data['otp'] ?? '').toString();
    final isConsumed = data['isConsumed'] == true;
    final expiresAt = data['expiresAt'] as Timestamp?;

    if (isConsumed) {
      return OtpResult(
        success: false,
        message: 'OTP already used. Request a new OTP.',
      );
    }

    if (expiresAt == null || expiresAt.toDate().isBefore(DateTime.now())) {
      return OtpResult(
        success: false,
        message: 'OTP expired. Please request a new OTP.',
      );
    }

    if (dbOtp != enteredOtp) {
      return OtpResult(success: false, message: 'Invalid OTP');
    }

    await doc.reference.update({
      'isVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'verifiedAt': FieldValue.serverTimestamp(),
    });

    return OtpResult(success: true, message: 'OTP verified successfully');
  }

  Future<RegistrationResult> registerStudent(
    Map<String, dynamic> payload,
  ) async {
    UserCredential? credential;
    try {
      final email = (payload['email'] as String? ?? '').trim().toLowerCase();
      final password = payload['password'] as String? ?? '';

      if (email.isEmpty || password.isEmpty) {
        return RegistrationResult(
          success: false,
          message: 'Email and password are required.',
        );
      }

      final otpDoc = await _firestore
          .collection('otp_verifications')
          .doc(_otpDocId(email))
          .get();

      final otpVerified = otpDoc.exists && otpDoc.data()?['isVerified'] == true;
      final otpConsumed = otpDoc.exists && otpDoc.data()?['isConsumed'] == true;
      // Skip OTP check when no OTP document exists (direct registration flow)
      if (otpDoc.exists && (!otpVerified || otpConsumed)) {
        return RegistrationResult(
          success: false,
          message: 'Please verify OTP before creating your account.',
        );
      }

      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return RegistrationResult(
          success: false,
          message: 'Could not create account.',
        );
      }

      final profilePhotoPath = (payload['profilePhotoPath'] as String? ?? '')
          .trim();
      String profileImageUrl = '';
      if (profilePhotoPath.isNotEmpty) {
        final sourceFile = File(profilePhotoPath);
        if (sourceFile.existsSync()) {
          profileImageUrl = profilePhotoPath;
        }
      }

      // Check if admin pre-assigned a role for this email (e.g., mentor)
      String assignedRole = 'student';
      try {
        final preRegDoc = await _firestore
            .collection('pre_registered_roles')
            .doc(email)
            .get();
        if (preRegDoc.exists) {
          assignedRole =
              (preRegDoc.data()?['role'] ?? 'student').toString();
          await preRegDoc.reference.delete();
        }
      } catch (_) {}

      await _studentController.saveStudentDataToFirestore(
        userId: user.uid,
        name: (payload['name'] as String? ?? '').trim(),
        email: email,
        phone: (payload['phone'] as String? ?? '').trim(),
        dob: payload['dob'] as String?,
        gender: (payload['gender'] as String? ?? '').trim(),
        educationLevel: (payload['educationLevel'] as String? ?? '').trim(),
        classYear: (payload['classYear'] as String? ?? '').trim(),
        stream: (payload['stream'] as String? ?? '').trim(),
        courses: List<String>.from(payload['courses'] as List? ?? const []),
        preferences: Map<String, dynamic>.from(
          payload['preferences'] as Map? ?? const <String, dynamic>{},
        ),
        referralCode: (payload['referralCode'] as String? ?? '').trim(),
        profileImage: profileImageUrl,
        password: password,
        role: assignedRole,
      );

      if (otpDoc.exists) {
        await otpDoc.reference.update({
          'isConsumed': true,
          'consumedByUserId': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      _activeDummyRole = null;
      final nextRoute = assignedRole == 'mentor'
          ? AppRoutes.mentorDashboard
          : AppRoutes.studentDashboard;
      return RegistrationResult(success: true, nextRoute: nextRoute);
    } on FirebaseAuthException catch (e) {
      return RegistrationResult(
        success: false,
        message: e.message ?? 'Registration failed.',
      );
    } catch (e) {
      if (credential?.user != null) {
        await credential!.user!.delete();
      }
      return RegistrationResult(success: false, message: 'Error: $e');
    }
  }

  Future<LoginResult> loginDummyUser({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedEmail == mentorEmail &&
        normalizedPassword == mentorPassword) {
      _activeDummyRole = 'mentor';
      return LoginResult(
        success: true,
        nextRoute: AppRoutes.mentorDashboard,
        role: 'mentor',
      );
    }

    if (normalizedEmail == adminEmail && normalizedPassword == adminPassword) {
      _activeDummyRole = 'admin';
      return LoginResult(
        success: true,
        nextRoute: AppRoutes.adminDashboard,
        role: 'admin',
      );
    }

    return LoginResult(success: false, message: 'No dummy user matched.');
  }

  Future<LoginResult> loginStudent({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return LoginResult(message: 'Login failed.');
      }

      final uid = user.uid;
      final ref = _firestore.collection('users').doc(uid);
      final doc = await ref.get();
      if (!doc.exists) {
        String role = 'student';
        if (email.contains('mentor')) role = 'mentor';
        if (email.contains('admin')) role = 'admin';
        try {
          final preReg = await _firestore
              .collection('pre_registered_roles')
              .doc(email.trim().toLowerCase())
              .get();
          if (preReg.exists) {
            role = (preReg.data()?['role'] ?? role).toString();
            await preReg.reference.delete();
          }
        } catch (_) {}
        await ref.set({
          'uid': uid,
          'email': email,
          'name': email.split('@').first,
          'role': role,
          'isVerified': true,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final loginEmail = user.email ?? '';
      unawaited(_fixMentorDataSilently(user.uid, loginEmail));
      unawaited(_fixStudentDataSilently(user.uid, loginEmail));

      final data = (await ref.get()).data()!;
      final role = (data['role'] ?? 'student').toString().toLowerCase();

      String nextRoute;
      if (role == 'admin') {
        nextRoute = AppRoutes.adminDashboard;
      } else if (role == 'mentor') {
        nextRoute = AppRoutes.mentorDashboard;
      } else {
        nextRoute = AppRoutes.studentDashboard;
      }

      return LoginResult(success: true, nextRoute: nextRoute, role: role);
    } on FirebaseAuthException catch (e) {
      return LoginResult(message: e.message ?? 'Login failed');
    } catch (e) {
      return LoginResult(message: 'Error: $e');
    }
  }

  Future<void> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      try {
        // Try Firebase auth first
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: normalizedEmail,
              password: password,
            );

        final uid = credential.user!.uid;
        final ref = FirebaseFirestore.instance.collection('users').doc(uid);
        var doc = await ref.get();

        if (!doc.exists) {
          String role = 'student';
          if (normalizedEmail.contains('mentor')) role = 'mentor';
          if (normalizedEmail.contains('admin')) role = 'admin';
          // Check admin pre-assigned role (e.g., invite as mentor)
          try {
            final preReg = await FirebaseFirestore.instance
                .collection('pre_registered_roles')
                .doc(normalizedEmail)
                .get();
            if (preReg.exists) {
              role = (preReg.data()?['role'] ?? role).toString();
              await preReg.reference.delete();
            }
          } catch (_) {}
          await ref.set({
            'uid': uid,
            'email': normalizedEmail,
            'name': normalizedEmail.split('@').first,
            'role': role,
            'isVerified': true,
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
          });
          doc = await ref.get();
        }

        final role = doc.data()?['role'] as String? ?? 'student';

        if (!context.mounted) return;

        // Check if user is blocked
        final isBlocked = (doc.data()?['isBlocked'] as bool?) ?? false;
        if (isBlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account has been blocked. Contact support.'),
            ),
          );
          await _auth.signOut();
          return;
        }

        // Sync AppAuthController so router redirect sees the user as logged in
        AppAuthController().currentUser.value = AppUser(
          uid: uid,
          email: normalizedEmail,
          name:
              doc.data()?['name'] as String? ??
              normalizedEmail.split('@').first,
          role: role,
        );

        // Ensure data is fixed for legacy accounts
        unawaited(_fixMentorDataSilently(uid, normalizedEmail));
        unawaited(_fixStudentDataSilently(uid, normalizedEmail));

        switch (role) {
          case 'admin':
            context.go(AppRoutes.adminDashboard);
            break;
          case 'mentor':
            context.go(AppRoutes.mentorDashboard);
            break;
          default:
            context.go(AppRoutes.studentDashboard);
        }
      } on FirebaseAuthException catch (e) {
        // Fall back to dummy user login for mentor/admin if Firebase account doesn't exist
        if ((e.code == 'user-not-found' ||
                e.code == 'invalid-credential' ||
                e.code == 'wrong-password') &&
            (normalizedEmail == mentorEmail || normalizedEmail == adminEmail)) {
          final dummyResult = await loginDummyUser(
            email: normalizedEmail,
            password: password,
          );

          if (dummyResult.success && context.mounted) {
            // Set dummy role globally
            _activeDummyRole = dummyResult.role;

            // For demo accounts, ensure Firestore document exists
            final demoUid = dummyResult.role == 'admin'
                ? 'test-admin-uid'
                : 'test-mentor-uid';
            final demoName = dummyResult.role == 'admin' ? 'Admin' : 'Mentor';

            try {
              final userDoc = await _firestore
                  .collection('users')
                  .doc(demoUid)
                  .get();

              if (!userDoc.exists) {
                // Create the demo user document if it doesn't exist
                await _firestore.collection('users').doc(demoUid).set({
                  'uid': demoUid,
                  'email': normalizedEmail,
                  'name': demoName,
                  'role': dummyResult.role,
                  'isVerified': true,
                  'status': 'active',
                  'isBlocked': false,
                  'profileImage': '',
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
            } catch (fsError) {
              // Log error but continue - demo account can still work even if Firestore fails
              debugPrint('Error ensuring demo user document: $fsError');
            }

            // CRITICAL: sync AppAuthController so router redirect sees user as logged in
            AppAuthController().currentUser.value = AppUser(
              uid: demoUid,
              email: normalizedEmail,
              name: demoName,
              role: dummyResult.role ?? 'student',
            );

            // Navigate to appropriate dashboard if widget is still mounted
            if (context.mounted) {
              context.go(dummyResult.nextRoute ?? AppRoutes.studentDashboard);
            }
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(dummyResult.message ?? 'Login failed'),
                duration: const Duration(seconds: 8),
              ),
            );
          }
        } else if (context.mounted) {
          // Show actual Firebase error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Code: ${e.code} — ${e.message}'),
              duration: const Duration(seconds: 8),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  Future<LoginResult> loginUser({
    required String email,
    required String password,
  }) async {
    // This method is now legacy, but we'll keep it for compatibility if needed.
    // However, the UI should call the new login(email, password, context)
    return LoginResult(
      success: false,
      message: 'Use login(email, password, context) instead.',
    );
  }

  Future<void> logout() async {
    _activeDummyRole = null;
    AppAuthController().currentUser.value = null;
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  /// Check if user is currently authenticated
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<AuthActionResult> logoutUser() async {
    try {
      await logout();
      return AuthActionResult(success: true);
    } catch (e) {
      return AuthActionResult(success: false, message: 'Logout failed: $e');
    }
  }

  /// Logout and clear the navigation stack
  Future<void> logoutAndClearNavigation() async {
    await logout();
  }

  Future<AuthActionResult> sendPasswordResetEmail({
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return AuthActionResult(success: false, message: 'Email is required.');
    }

    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
      return AuthActionResult(
        success: true,
        message: 'Password reset link sent to $normalizedEmail',
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return AuthActionResult(success: false, message: 'Invalid email.');
        case 'user-not-found':
          return AuthActionResult(
            success: false,
            message: 'No account found with this email.',
          );
        default:
          return AuthActionResult(
            success: false,
            message: e.message ?? 'Could not send password reset email.',
          );
      }
    } catch (e) {
      return AuthActionResult(success: false, message: 'Error: $e');
    }
  }

  Future<AuthActionResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      return AuthActionResult(
        success: false,
        message: 'No authenticated user found.',
      );
    }

    // Demo accounts cannot change password
    if (user.email == 'admin@test.com' || user.email == 'mentor@test.com') {
      return AuthActionResult(
        success: false,
        message:
            'Demo accounts cannot change password. Please use a real account.',
      );
    }

    if (newPassword.length < 6) {
      return AuthActionResult(
        success: false,
        message: 'New password must be at least 6 characters.',
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return AuthActionResult(
        success: true,
        message: 'Password updated successfully.',
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return AuthActionResult(
            success: false,
            message: 'Current password is incorrect.',
          );
        case 'weak-password':
          return AuthActionResult(success: false, message: 'Weak password.');
        case 'requires-recent-login':
          return AuthActionResult(
            success: false,
            message: 'Please login again and retry password change.',
          );
        default:
          return AuthActionResult(
            success: false,
            message: e.message ?? 'Password change failed.',
          );
      }
    } catch (e) {
      return AuthActionResult(success: false, message: 'Error: $e');
    }
  }

  Future<AuthActionResult> sendCurrentUserEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      return AuthActionResult(
        success: false,
        message: 'No authenticated user found.',
      );
    }

    if ((user.email ?? '').isEmpty) {
      return AuthActionResult(
        success: false,
        message: 'Current user does not have an email address.',
      );
    }

    if (user.emailVerified) {
      return AuthActionResult(
        success: true,
        message: 'Email is already verified.',
      );
    }

    try {
      await user.sendEmailVerification();
      return AuthActionResult(
        success: true,
        message: 'Verification email sent. Please check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthActionResult(
        success: false,
        message: e.message ?? 'Unable to send verification email.',
      );
    } catch (e) {
      return AuthActionResult(success: false, message: 'Error: $e');
    }
  }

  Future<AuthActionResult> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      return AuthActionResult(
        success: false,
        message: 'No authenticated user found.',
      );
    }

    try {
      await _profileController.deleteUserAccount();
      _activeDummyRole = null;
      return AuthActionResult(
        success: true,
        message: 'Account deleted successfully.',
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'requires-recent-login':
          return AuthActionResult(
            success: false,
            message: 'Please login again before deleting your account.',
          );
        default:
          return AuthActionResult(
            success: false,
            message: e.message ?? 'Account deletion failed.',
          );
      }
    } catch (e) {
      return AuthActionResult(success: false, message: 'Error: $e');
    }
  }

  Future<LoginResult> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      // Always show account picker — never auto-select cached account
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return LoginResult(success: false, message: 'Cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        return LoginResult(success: false, message: 'Google sign-in failed');
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      String role = 'student';
      if (!doc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
          'role': 'student',
          'isVerified': true,
          'status': 'active',
          'isBlocked': false,
          'createdAt': FieldValue.serverTimestamp(),
          'isApproved': true,
        });
      } else {
        role = (doc.data()!['role'] ?? 'student').toString().toLowerCase();
      }

      // Sync AppAuthController so router redirect sees the user as logged in
      AppAuthController().currentUser.value = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        role: role,
      );

      String nextRoute = AppRoutes.studentDashboard;
      if (role == 'mentor') nextRoute = AppRoutes.mentorDashboard;
      if (role == 'admin') nextRoute = AppRoutes.adminDashboard;

      return LoginResult(success: true, nextRoute: nextRoute, role: role);
    } catch (e) {
      return LoginResult(success: false, message: e.toString());
    }
  }
}
