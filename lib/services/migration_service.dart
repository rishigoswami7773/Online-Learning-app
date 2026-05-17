import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationService {
  static final MigrationService _instance = MigrationService._internal();

  factory MigrationService() {
    return _instance;
  }

  MigrationService._internal();

  /// Add password field to existing users that don't have it
  /// Returns the number of documents updated
  static Future<int> addPasswordFieldToExistingUsers() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final usersRef = firestore.collection('users');

      // Get all users that don't have a password field
      final snapshot = await usersRef.get();

      int updatedCount = 0;
      final batch = firestore.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Check if password field is missing or empty
        if (!data.containsKey('password') || data['password'] == null) {
          batch.update(doc.reference, {
            'password': '', // Add empty password for existing users
            'updatedAt': FieldValue.serverTimestamp(),
          });
          updatedCount++;
        }
      }

      if (updatedCount > 0) {
        await batch.commit();
      }

      return updatedCount;
    } catch (e) {
      return 0;
    }
  }

  /// Check migration status
  static Future<Map<String, int>> getMigrationStatus() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final usersRef = firestore.collection('users');

      final snapshot = await usersRef.get();

      int totalUsers = snapshot.docs.length;
      int usersWithPassword = 0;
      int usersWithoutPassword = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('password') &&
            data['password'] != null &&
            (data['password'] as String).isNotEmpty) {
          usersWithPassword++;
        } else {
          usersWithoutPassword++;
        }
      }

      return {
        'total': totalUsers,
        'withPassword': usersWithPassword,
        'withoutPassword': usersWithoutPassword,
      };
    } catch (e) {
      return {'total': 0, 'withPassword': 0, 'withoutPassword': 0};
    }
  }
}
