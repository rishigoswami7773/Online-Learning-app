import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  static const primary = Color(0xff6A5AE0);

  @override
  Widget build(BuildContext context) {
    final chats = [
      {
        'name': 'Celine (Mentor)',
        'message': 'Have you watched lesson 5?',
        'time': '2m',
      },
      {
        'name': 'Course Bot',
        'message': 'Assignment 2 deadline approaching',
        'time': '1h',
      },
      {
        'name': 'Study Group',
        'message': 'Meet at 7pm for review',
        'time': '3h',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(title: const Text("Chats"), backgroundColor: primary),

      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: chats.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, idx) {
          final c = chats[idx];

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailPage(name: c['name']!),
              ),
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
                          c['name']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c['message']!,
                          style: const TextStyle(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  Text(c['time']!, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  final String name;

  const ChatDetailPage({super.key, required this.name});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  static const primary = Color(0xff6A5AE0);

  final List<Map<String, dynamic>> _messages = [
    {'fromMe': false, 'text': 'Hi, are you joining the live class?'},
    {'fromMe': true, 'text': 'Yes, I will be there.'},
  ];

  final TextEditingController _ctrl = TextEditingController();

  void _send() {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;

    setState(() {
      _messages.add({'fromMe': true, 'text': txt});
    });

    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: primary,
        title: Row(
          children: [
            const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
            const SizedBox(width: 8),
            Text(widget.name),
          ],
        ),
      ),

      body: Column(
        children: [
          /// messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,

              itemBuilder: (context, idx) {
                final m = _messages[idx];

                return Align(
                  alignment: m['fromMe']
                      ? Alignment.centerRight
                      : Alignment.centerLeft,

                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),

                    decoration: BoxDecoration(
                      color: m['fromMe'] ? primary : Colors.white,

                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(m['fromMe'] ? 16 : 4),
                        bottomRight: Radius.circular(m['fromMe'] ? 4 : 16),
                      ),

                      boxShadow: [
                        if (!m['fromMe'])
                          BoxShadow(color: Colors.grey.shade200, blurRadius: 5),
                      ],
                    ),

                    child: Text(
                      m['text'],
                      style: TextStyle(
                        color: m['fromMe'] ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /// message input
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

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
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
