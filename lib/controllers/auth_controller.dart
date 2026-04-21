import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:math';

import 'profile_controller.dart';
import 'student_controller.dart';
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
      if (!otpVerified || otpConsumed) {
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
      );

      await otpDoc.reference.update({
        'isConsumed': true,
        'consumedByUserId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _activeDummyRole = null;
      return RegistrationResult(
        success: true,
        nextRoute: AppRoutes.studentDashboard,
      );
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
        return LoginResult(
          message: 'Login failed. User not found in auth state.',
        );
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return LoginResult(message: 'User profile not found.');
      }

      final data = userDoc.data()!;
      final role = (data['role'] ?? '').toString().toLowerCase();
      final isVerified = data['isVerified'] == true;

      if (role != 'student') {
        await _auth.signOut();
        return LoginResult(
          message: 'Only student accounts can login from this flow.',
        );
      }

      if (!isVerified) {
        await _auth.signOut();
        return LoginResult(
          message:
              'Your account is not verified yet. Please complete verification.',
        );
      }

      _activeDummyRole = null;
      return LoginResult(
        success: true,
        nextRoute: AppRoutes.studentDashboard,
        role: 'student',
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return LoginResult(message: 'No account found with this email');
        case 'wrong-password':
          return LoginResult(message: 'Incorrect password');
        case 'invalid-email':
          return LoginResult(message: 'Invalid email address');
        case 'user-disabled':
          return LoginResult(message: 'This account has been disabled');
        default:
          return LoginResult(message: 'Login failed: ${e.message}');
      }
    } catch (e) {
      return LoginResult(message: 'Error: $e');
    }
  }

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final dummyResult = await loginDummyUser(email: email, password: password);
    if (dummyResult.success) {
      return dummyResult;
    }
    return loginStudent(email: email, password: password);
  }

  Future<LoginResult> loginUser({
    required String email,
    required String password,
  }) async {
    return login(email: email, password: password);
  }

  Future<void> logout() async {
    _activeDummyRole = null;
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
}
