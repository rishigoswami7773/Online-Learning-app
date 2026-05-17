import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/payment_config.dart';

class PaymentService {
  PaymentService._();

  static Future<Map<String, dynamic>> createOrder({
    required String courseId,
    required String courseName,
    required double amount,
  }) async {
    final credentials = base64Encode(
      utf8.encode(
        '${PaymentConfig.razorpayKeyId}:${PaymentConfig.razorpayKeySecret}',
      ),
    );
    final response = await http.post(
      Uri.parse('https://api.razorpay.com/v1/orders'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': (amount * 100).round(),
        'currency': 'INR',
        'receipt': 'rcpt_${courseId}_${DateTime.now().millisecondsSinceEpoch}',
        'notes': {'courseId': courseId, 'courseName': courseName},
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'orderId': data['id'],
        'amount': data['amount'],
        'currency': data['currency'],
      };
    } else {
      throw Exception('Failed to create order: ${response.body}');
    }
  }

  static Future<bool> verifyAndEnroll({
    required String orderId,
    required String paymentId,
    required String signature,
    required String courseId,
    required String courseName,
    required double amount,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final db = FirebaseFirestore.instance;
    final now = FieldValue.serverTimestamp();

    String mentorId = '';
    String studentName = '';
    try {
      final courseDoc = await db.collection('courses').doc(courseId).get();
      mentorId = (courseDoc.data()?['mentorId'] ?? '').toString();
    } catch (_) {}
    try {
      final userDoc = await db.collection('users').doc(uid).get();
      studentName =
          (userDoc.data()?['name'] ?? userDoc.data()?['displayName'] ?? '')
              .toString();
    } catch (_) {}

    await db.collection('payments').add({
      'userId': uid,
      'mentorId': mentorId,
      'studentName': studentName,
      'courseId': courseId,
      'courseName': courseName,
      'amount': amount,
      'currency': 'INR',
      'orderId': orderId,
      'paymentId': paymentId,
      'status': 'success',
      'paidAt': now,
    });

    await db.collection('enrollments').doc('${uid}_$courseId').set({
      'studentId': uid,
      'courseId': courseId,
      'courseTitle': courseName,
      'mentorId': mentorId,
      'status': 'active',
      'enrolledAt': now,
      'paymentId': paymentId,
      'paid': true,
    });

    await db.collection('activityLogs').add({
      'userId': uid,
      'action': 'course_purchased',
      'courseId': courseId,
      'courseName': courseName,
      'amount': amount,
      'timestamp': now,
    });

    return true;
  }

  static Stream<QuerySnapshot> getPaymentHistory(String userId) =>
      FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('paidAt', descending: true)
          .snapshots();

  static Future<bool> isCoursePurchased(String userId, String courseId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('enrollments')
          .doc('${userId}_$courseId')
          .get();
      return doc.exists && (doc.data()?['paid'] == true);
    } catch (_) {
      return false;
    }
  }
}
