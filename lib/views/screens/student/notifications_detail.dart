import 'package:flutter/material.dart';

class NotificationDetailPage extends StatelessWidget {
  final String title;
  final String body;

  const NotificationDetailPage({
    super.key,
    required this.title,
    required this.body,
  });

  static const primary = Color(0xff6A5AE0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        title: const Text("Notification"),
      ),

      body: Column(
        children: [

          /// HEADER SECTION
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff6A5AE0), Color(0xff8E7BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),

            child: Column(
              children: [

                /// ICON
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 12),

                /// TITLE
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                /// TIME
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time,
                        color: Colors.white70, size: 16),
                    SizedBox(width: 5),
                    Text(
                      "Just now",
                      style: TextStyle(color: Colors.white70),
                    )
                  ],
                ),
              ],
            ),
          ),

          /// BODY
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// MESSAGE TITLE
                  const Text(
                    "Message",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// MESSAGE CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Text(
                      body,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const Spacer(),

                  /// ACTION BUTTONS
                  Row(
                    children: [

                      /// BACK BUTTON
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.arrow_back),
                          label: const Text("Back"),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: primary,
                            side: const BorderSide(color: primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// MARK AS READ
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text("Mark as Read"),
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}