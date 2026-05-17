import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/uid_resolver.dart';

/// Logs admin/mentor actions to the activityLogs Firestore collection.
class ActivityLogger {
  static Future<void> log({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('activityLogs').add({
        'action': action,
        'entityType': entityType,
        'entityId': entityId ?? '',
        'performedBy': UidResolver.uid ?? 'unknown',
        'role': UidResolver.role,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Never block the caller on logging errors
    }
  }
}
