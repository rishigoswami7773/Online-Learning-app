import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/uid_resolver.dart';

class MentorChatController {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  String get uid => UidResolver.uid ?? '';

  /// Stream of chat messages for a conversation id.
  Stream<QuerySnapshot> messagesStream(String conversationId) {
    if (uid.isEmpty || conversationId.isEmpty) return const Stream.empty();
    return _fs
        .collection('chat_conversations')
        .doc(conversationId)
        .collection('chat_messages')
        .orderBy('sentAt')
        .snapshots();
  }

  /// Stream of conversations where this mentor is a participant.
  Stream<QuerySnapshot> conversationsStream() {
    if (uid.isEmpty) return const Stream.empty();
    return _fs
        .collection('chat_conversations')
        .where('mentorId', isEqualTo: uid)
        .snapshots();
  }

  Future<void> sendMessage(
    String conversationId,
    String toId,
    String text,
  ) async {
    if (uid.isEmpty || conversationId.isEmpty || text.trim().isEmpty) return;
    final conversationRef = _fs
        .collection('chat_conversations')
        .doc(conversationId);
    await conversationRef.collection('chat_messages').add({
      'fromId': uid,
      'toId': toId,
      'text': text.trim(),
      'sentAt': FieldValue.serverTimestamp(),
    });
    await conversationRef.set({
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
