import 'package:flutter/material.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  static const Color _primary = Color(0xff6A5AE0);

  @override
  Widget build(BuildContext context) {
    final wishlist = [
      {
        'title': 'Flutter for Beginners',
        'instructor': 'Celine R.',
        'duration': '18h 30m',
        'rating': '4.8',
      },
      {
        'title': 'UI/UX Design Essentials',
        'instructor': 'Ava M.',
        'duration': '12h 10m',
        'rating': '4.7',
      },
      {
        'title': 'Web Development Bootcamp',
        'instructor': 'Noah T.',
        'duration': '22h 45m',
        'rating': '4.9',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Wishlist'), backgroundColor: _primary),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: wishlist.length,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final course = wishlist[index];
          return Container(
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite, color: _primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${course['instructor']} • ${course['duration']} • ${course['rating']}⭐',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('Open')),
              ],
            ),
          );
        },
      ),
    );
  }
}
