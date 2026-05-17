import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';

void _safeBackToStudentDashboard(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.studentDashboard);
  }
}

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  static const Color _primary = Color(0xff6A5AE0);

  Future<void> _removeFromWishlist(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('wishlists/$uid/courses')
        .doc(docId)
        .delete();
  }

  String _formatDuration(num hours) {
    final totalMinutes = (hours * 60).round();
    final wholeHours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;
    if (remainingMinutes == 0) {
      return '${wholeHours}h';
    }
    return '${wholeHours}h ${remainingMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
          title: const Text('Wishlist', style: TextStyle(color: Colors.white)),
          backgroundColor: _primary,
        ),
        body: uid == null
            ? const Center(child: Text('Sign in to view your wishlist.'))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('wishlists/$uid/courses')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Unable to load wishlist.'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final courses = snapshot.data?.docs ?? const [];
                  if (courses.isEmpty) {
                    return const Center(child: Text('Your wishlist is empty.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: courses.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final courseDoc = courses[index];
                      final course = courseDoc.data();
                      final title = (course['title'] ?? 'Untitled Course')
                          .toString();
                      final instructor =
                          (course['instructorName'] ?? 'Instructor').toString();
                      final duration = _formatDuration(
                        (course['durationHours'] as num?) ?? 0,
                      );
                      final rating = ((course['rating'] as num?) ?? 0)
                          .toDouble();

                      return Dismissible(
                        key: ValueKey(courseDoc.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _removeFromWishlist(courseDoc.id),
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
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _primary.withValues(alpha: .12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: _primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$instructor • $duration • ${rating.toStringAsFixed(1)}⭐',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push(
                                  AppRoutes.courseDetail,
                                  extra: course['courseId'],
                                ),
                                child: const Text('Open'),
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
