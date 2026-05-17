import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:online_learning_app/controllers/app_auth_controller.dart';
import 'package:online_learning_app/routes/app_routes.dart';

void _safeBackToStudentDashboard(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.studentDashboard);
  }
}

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  static const primary = Color(0xff6A5AE0);

  String _formatLastMessageTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }

    final date = timestamp.toDate();
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) {
      return 'now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h';
    }

    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = AppAuthController().currentUser.value?.uid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _safeBackToStudentDashboard(context);
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _safeBackToStudentDashboard(context),
          ),
          title: const Text("Chats", style: TextStyle(color: Colors.white)),
          backgroundColor: primary,
        ),
        body: uid == null
            ? const Center(child: Text('Sign in to view chats.'))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('chat_conversations')
                    .where('participants', arrayContains: uid)
                    .orderBy('lastMessageAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Unable to load chats.'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final chats = snapshot.data?.docs ?? const [];
                  if (chats.isEmpty) {
                    return const Center(child: Text('No chats yet.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: chats.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final chatDoc = chats[idx];
                      final data = chatDoc.data();
                      final participants = List<String>.from(
                        data['participants'] ?? const <String>[],
                      );
                      final others = participants
                          .where((participant) => participant != uid)
                          .toList();
                      final chatTitle = others.isEmpty
                          ? 'Chat'
                          : others.join(', ');
                      final lastMessage =
                          (data['lastMessage'] ?? 'No messages yet').toString();
                      final lastMessageAt = data['lastMessageAt'] as Timestamp?;

                      return GestureDetector(
                        onTap: () => context.push(
                          AppRoutes.studentChat,
                          extra: {'chatId': chatDoc.id, 'title': chatTitle},
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              /// avatar
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: primary.withValues(alpha: .2),
                                child: const Icon(Icons.person, color: primary),
                              ),

                              const SizedBox(width: 12),

                              /// text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      chatTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lastMessage,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                _formatLastMessageTime(lastMessageAt),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final String title;

  const ChatDetailPage({super.key, required this.chatId, required this.title});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  static const primary = Color(0xff6A5AE0);

  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onMessageChanged);
  }

  void _onMessageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onMessageChanged);
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send(String uid) async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final chatRef = firestore
        .collection('chat_conversations')
        .doc(widget.chatId);
    final messageRef = chatRef.collection('chat_messages').doc();
    final batch = firestore.batch();

    batch.set(messageRef, {
      'senderId': uid,
      'text': txt,
      'sentAt': FieldValue.serverTimestamp(),
    });
    batch.set(chatRef, {
      'lastMessage': txt,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AppAuthController().currentUser.value?.uid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _safeBackToStudentDashboard(context);
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => _safeBackToStudentDashboard(context),
          ),
          backgroundColor: primary,
          title: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                child: Icon(Icons.person, size: 18),
              ),
              const SizedBox(width: 8),
              Text(widget.title),
            ],
          ),
        ),
        body: uid == null
            ? const Center(child: Text('Sign in to chat.'))
            : Column(
                children: [
                  /// messages
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('chat_conversations')
                          .doc(widget.chatId)
                          .collection('messages')
                          .orderBy('sentAt')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Unable to load messages.'),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final messages = snapshot.data?.docs ?? const [];
                        if (messages.isEmpty) {
                          return const Center(
                            child: Text('Start the conversation.'),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, idx) {
                            final messageDoc = messages[idx];
                            final data = messageDoc.data();
                            final senderId = (data['senderId'] ?? '')
                                .toString();
                            final text = (data['text'] ?? '').toString();
                            final isMe = senderId == uid;

                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe ? primary : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                  ),
                                  boxShadow: [
                                    if (!isMe)
                                      BoxShadow(
                                        color: Colors.grey.shade200,
                                        blurRadius: 5,
                                      ),
                                  ],
                                ),
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  /// message input
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              decoration: InputDecoration(
                                hintText: "Write a message",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) {
                                if (uid.isNotEmpty) {
                                  _send(uid);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: const BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed:
                                  (uid.isEmpty || _ctrl.text.trim().isEmpty)
                                  ? null
                                  : () => _send(uid),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
