import 'package:cloud_firestore/cloud_firestore.dart';

class UserStats {
  final int totalUsers;
  final int students;
  final int mentors;
  final int admins;
  final int activeUsers;

  UserStats({
    required this.totalUsers,
    required this.students,
    required this.mentors,
    required this.admins,
    required this.activeUsers,
  });
}

class AdminUsersController {
  AdminUsersController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Get all users
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').snapshots();
  }

  /// Get users by role
  Stream<QuerySnapshot> getUsersByRole(String role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots();
  }

  /// Get user statistics
  Future<UserStats> getUserStats() async {
    final allUsers = await _firestore.collection('users').count().get();
    final studentsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .count()
        .get();
    final mentorsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'mentor')
        .count()
        .get();
    final adminsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .count()
        .get();

    return UserStats(
      totalUsers: allUsers.count ?? 0,
      students: studentsSnapshot.count ?? 0,
      mentors: mentorsSnapshot.count ?? 0,
      admins: adminsSnapshot.count ?? 0,
      activeUsers: 0, // Would need lastLogin tracking
    );
  }

  /// Suspend/activate user
  Future<void> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': isActive,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    // Delete user document
    await _firestore.collection('users').doc(userId).delete();

    // Delete related data
    final enrollments = await _firestore
        .collection('enrollments')
        .where('studentId', isEqualTo: userId)
        .get();

    for (final doc in enrollments.docs) {
      await doc.reference.delete();
    }

    // Delete chat conversations
    final chats = await _firestore
        .collection('chat_conversations')
        .where('studentId', isEqualTo: userId)
        .get();

    for (final doc in chats.docs) {
      await doc.reference.delete();
    }
  }

  /// Update user role
  Future<void> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'role': newRole,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Search users
  Stream<QuerySnapshot> searchUsers(String query) {
    final normalizedQuery = query.toLowerCase();
    return _firestore
        .collection('users')
        .where('nameLower', isGreaterThanOrEqualTo: normalizedQuery)
        .where('nameLower', isLessThan: '${normalizedQuery}z')
        .snapshots();
  }

  /// Get user by email
  Future<DocumentSnapshot?> getUserByEmail(String email) async {
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
  }
}
