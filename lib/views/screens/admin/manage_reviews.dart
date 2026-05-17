import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import 'admin_widgets.dart';

void _safeBackToAdminHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.adminHome);
  }
}

class ManageReviewsPage extends StatelessWidget {
  const ManageReviewsPage({super.key});

  Future<void> _approveReview(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    await doc.reference.update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteReview(DocumentSnapshot<Map<String, dynamic>> doc) async {
    await doc.reference.delete();
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          const Text('No reviews yet'),
          const SizedBox(height: 6),
          const Text('Published course reviews will appear here for moderation.'),
        ],
      ),
    );
  }

  Widget _stars(double rating) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < rating.round() ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _safeBackToAdminHome(context);
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: AdminTextStyles.appBarTitle,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _safeBackToAdminHome(context),
          ),
          title: const Text('Manage Reviews'),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('course_reviews')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    adminHeroHeader(
                      title: 'Manage Reviews',
                      subtitle: 'Moderate community feedback',
                    ),
                    SizedBox(height: 16),
                    ShimmerBox(
                      width: double.infinity,
                      height: 110,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ],
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 56),
                    const SizedBox(height: 12),
                    Text('Unable to load reviews: ${snapshot.error}'),
                  ],
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return _emptyState(context);
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final rating = (data['rating'] as num?)?.toDouble() ?? 0;
                final comment = (data['comment'] ?? data['reviewText'] ?? '')
                    .toString();
                final reviewerName = (data['reviewerName'] ?? 'Anonymous')
                    .toString();
                final courseTitle = (data['courseTitle'] ?? 'Unknown course')
                    .toString();
                final createdAt = data['createdAt'];
                final approved = data['status']?.toString() == 'approved';

                return StaggeredItem(
                  delay: Duration(milliseconds: index * 50),
                  child: adminListCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AdminColors.brandSoft,
                              child: Text(
                                reviewerName.isNotEmpty
                                    ? reviewerName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: AdminColors.brand,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reviewerName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    courseTitle,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (approved)
                              adminPill('Approved', AdminColors.brand),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _stars(rating),
                        const SizedBox(height: 8),
                        Text(
                          comment.isEmpty
                              ? 'No written feedback provided.'
                              : comment,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (createdAt is Timestamp)
                          Text(
                            createdAt.toDate().toLocal().toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (!approved)
                              ElevatedButton(
                                onPressed: () async {
                                  await _approveReview(doc);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AdminColors.brand,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Approve',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            OutlinedButton(
                              onPressed: () async {
                                await _deleteReview(doc);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Delete',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
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
