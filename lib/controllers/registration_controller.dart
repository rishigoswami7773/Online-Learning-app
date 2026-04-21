import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../routes/app_routes.dart';

class RegistrationResult {
  RegistrationResult({this.success = false, this.message, this.nextRoute});

  final bool success;
  final String? message;
  final String? nextRoute;
}

class RegistrationController {
  Future<RegistrationResult> registerStudent(
    Map<String, dynamic> payload,
  ) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: (payload['email'] as String).trim(),
            password: payload['password'] as String,
          );

      final uid = userCredential.user?.uid;
      if (uid == null) {
        return RegistrationResult(
          message: 'User ID not available after registration.',
        );
      }

      final profile = Map<String, dynamic>.from(payload)
        ..remove('password')
        ..['userId'] = uid
        ..['createdAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .set(profile);
      return RegistrationResult(
        success: true,
        nextRoute: AppRoutes.studentDashboard,
      );
    } on FirebaseAuthException catch (error) {
      return RegistrationResult(
        message: error.message ?? 'Registration failed.',
      );
    } catch (error) {
      return RegistrationResult(message: 'Error: $error');
    }
  }
}
