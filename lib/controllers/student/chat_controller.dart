import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final String conversationId;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.conversationId,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      conversationId: data['conversationId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'senderName': senderName,
    'message': message,
    'timestamp': Timestamp.fromDate(timestamp),
    'conversationId': conversationId,
  };
}

class ChatConversation {
  final String id;
  final String studentId;
  final String mentorId;
  final String mentorName;
  final DateTime lastMessageTime;
  final String lastMessage;

  ChatConversation({
    required this.id,
    required this.studentId,
    required this.mentorId,
    required this.mentorName,
    required this.lastMessageTime,
    required this.lastMessage,
  });

  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatConversation(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      mentorId: data['mentorId'] ?? '',
      mentorName: data['mentorName'] ?? '',
      lastMessageTime:
          (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'studentId': studentId,
    'mentorId': mentorId,
    'mentorName': mentorName,
    'lastMessageTime': Timestamp.fromDate(lastMessageTime),
    'lastMessage': lastMessage,
  };
}

class ChatController {
  ChatController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Get all conversations for current user
  Stream<List<ChatConversation>> getConversations() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('chat_conversations')
        .where('studentId', isEqualTo: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatConversation.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get messages for a conversation
  Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _firestore
        .collection('chat_messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList(),
        );
  }

  /// Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String message,
    required String senderName,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    final msg = ChatMessage(
      id: '',
      senderId: uid,
      senderName: senderName,
      message: message,
      timestamp: DateTime.now(),
      conversationId: conversationId,
    );

    await _firestore.collection('chat_messages').add(msg.toFirestore());

    // Update last message in conversation
    await _firestore
        .collection('chat_conversations')
        .doc(conversationId)
        .update({'lastMessage': message, 'lastMessageTime': Timestamp.now()});
  }

  /// Create a new conversation with a mentor
  Future<String> createConversation({
    required String mentorId,
    required String mentorName,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    // Check if conversation already exists
    final query = await _firestore
        .collection('chat_conversations')
        .where('studentId', isEqualTo: uid)
        .where('mentorId', isEqualTo: mentorId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    final conversation = ChatConversation(
      id: '',
      studentId: uid,
      mentorId: mentorId,
      mentorName: mentorName,
      lastMessageTime: DateTime.now(),
      lastMessage: '',
    );

    final docRef = await _firestore
        .collection('chat_conversations')
        .add(conversation.toFirestore());

    return docRef.id;
  }
}
