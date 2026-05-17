import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../utils/uid_resolver.dart';

const Color _mentorTeal = Color(0xFF0E7C86);

void _safeBackToMentorDashboard(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.mentorDashboard);
  }
}

class MentorRatingsPage extends StatefulWidget {
  const MentorRatingsPage({super.key});

  @override
  State<MentorRatingsPage> createState() => _MentorRatingsPageState();
}

class _MentorRatingsPageState extends State<MentorRatingsPage> {
  late int _reloadKey = 0;

  // BUG 6 FIX: Convert async* stream to regular Future to avoid deadlock
  Future<_MentorRatingsState> _loadRatings(String uid) async {
    final courseSnap = await FirebaseFirestore.instance
        .collection('courses')
        .where('mentorId', isEqualTo: uid)
        .get();

    final courseTitles = <String, String>{
      for (final doc in courseSnap.docs)
        doc.id: (doc.data()['title'] as String?)?.trim().isNotEmpty == true
            ? (doc.data()['title'] as String).trim()
            : 'Untitled course',
    };
    final courseIds = courseTitles.keys.toList();

    if (courseIds.isEmpty) {
      return const _MentorRatingsState(rows: [], averageRating: 0.0);
    }

    final rows = <_MentorReviewRow>[];
    for (var index = 0; index < courseIds.length; index += 10) {
      final chunk = courseIds.skip(index).take(10).toList();
      final reviewSnap = await FirebaseFirestore.instance
          .collection('course_reviews')
          .where('courseId', whereIn: chunk)
          .get();

      for (final doc in reviewSnap.docs) {
        final data = doc.data();
        final courseId = (data['courseId'] as String?) ?? '';
        rows.add(
          _MentorReviewRow(
            reviewerName: (data['reviewerName'] as String?) ?? 'Student',
            courseTitle:
                courseTitles[courseId] ??
                (data['courseTitle'] as String?) ??
                'Untitled course',
            rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
            comment: (data['comment'] as String?) ?? '',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          ),
        );
      }
    }

    rows.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    final averageRating = rows.isEmpty
        ? 0.0
        : rows.map((row) => row.rating).reduce((a, b) => a + b) / rows.length;

    return _MentorRatingsState(rows: rows, averageRating: averageRating);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = UidResolver.uid;
      if (uid == null && mounted) {
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = UidResolver.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _safeBackToMentorDashboard(context);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          title: const Text('Ratings & Reviews'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _mentorTeal),
            onPressed: () => _safeBackToMentorDashboard(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: _mentorTeal),
              onPressed: () {
                setState(() => _reloadKey++);
              },
            ),
          ],
        ),
        body: FutureBuilder<_MentorRatingsState>(
          key: ValueKey(_reloadKey),
          future: _loadRatings(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Unable to load reviews: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData || (snapshot.data?.rows ?? []).isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 80,
                      color: _mentorTeal.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When students leave reviews, they\'ll appear here',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final state = snapshot.data!;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                // Summary Card
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_mentorTeal, Color(0xFF17A2B8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(
                                    5,
                                    (index) => Icon(
                                      index < state.averageRating.round()
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Based on ${state.rows.length} review${state.rows.length == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Rating Distribution
                      ...[5, 4, 3, 2, 1].map((rating) {
                        final count = state.rows
                            .where((r) => r.rating.round() == rating)
                            .length;
                        final percentage = state.rows.isEmpty
                            ? 0.0
                            : (count / state.rows.length);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Text(
                                '$rating★',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    minHeight: 4,
                                    backgroundColor: Colors.white24,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                count.toString(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Reviews List
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                   child: const Text(
                     'Recent Reviews',
                     style: TextStyle(
                       fontSize: 16,
                       fontWeight: FontWeight.w800,
                     ),
                   ),
                 ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: state.rows.map((row) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: _mentorTeal.withValues(
                                        alpha: 0.12,
                                      ),
                                      child: Text(
                                        row.reviewerName.isNotEmpty
                                            ? row.reviewerName[0].toUpperCase()
                                            : 'S',
                                        style: const TextStyle(
                                          color: _mentorTeal,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                           Text(
                                             row.reviewerName,
                                             style: const TextStyle(
                                               fontWeight: FontWeight.w700,
                                             ),
                                           ),
                                           const SizedBox(height: 2),
                                           Text(
                                             row.courseTitle,
                                             style: const TextStyle(
                                               color: Colors.grey,
                                               fontSize: 12,
                                             ),
                                           ),
                                        ],
                                      ),
                                    ),
                                     Text(
                                       _formatDate(row.createdAt),
                                       style: const TextStyle(
                                         color: Colors.grey,
                                         fontSize: 11,
                                       ),
                                     ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: List.generate(
                                    5,
                                    (index) => Icon(
                                      index < row.rating.round()
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                 if (row.comment.isNotEmpty) ...[
                                   const SizedBox(height: 10),
                                   Text(
                                     row.comment,
                                     style: const TextStyle(
                                       color: Colors.grey,
                                       fontSize: 13,
                                       fontStyle: FontStyle.italic,
                                       height: 1.4,
                                     ),
                                   ),
                                 ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MentorRatingsState {
  const _MentorRatingsState({required this.rows, required this.averageRating});

  final List<_MentorReviewRow> rows;
  final double averageRating;
}

class _MentorReviewRow {
  const _MentorReviewRow({
    required this.reviewerName,
    required this.courseTitle,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String reviewerName;
  final String courseTitle;
  final double rating;
  final String comment;
  final DateTime? createdAt;
}
