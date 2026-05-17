import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:online_learning_app/routes/app_routes.dart';

import 'admin_widgets.dart';

void _safeBackToAdminHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.adminHome);
  }
}

class AdminManageCoursesScreenNew extends StatefulWidget {
  const AdminManageCoursesScreenNew({super.key});

  @override
  State<AdminManageCoursesScreenNew> createState() =>
      _AdminManageCoursesScreenNewState();
}

class _AdminManageCoursesScreenNewState
    extends State<AdminManageCoursesScreenNew> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filterStatus = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesFilters(Map<String, dynamic> data) {
    final title = (data['title'] as String? ?? '').toLowerCase();
    final instructor = (data['instructor'] as String? ?? '').toLowerCase();
    final category = (data['category'] as String? ?? '').toLowerCase();
    final query = _searchCtrl.text.trim().toLowerCase();

    final status = (data['status'] as String? ?? '').toLowerCase();
    final isPublished = data['isPublished'] as bool? ?? false;
    final effectiveStatus = isPublished && status.isEmpty ? 'published' : status;
    final statusPass = _filterStatus == 'all'
        || effectiveStatus == _filterStatus
        || (_filterStatus == 'published' && isPublished)
        || (_filterStatus == 'published' && status == 'active');
    final queryPass =
        query.isEmpty ||
        title.contains(query) ||
        instructor.contains(query) ||
        category.contains(query);

    return statusPass && queryPass;
  }

  Future<void> _deleteCourse(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await FirebaseFirestore.instance.collection('courses').doc(docId).delete();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Course deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            FirebaseFirestore.instance
                .collection('courses')
                .doc(docId)
                .set(data);
          },
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _safeBackToAdminHome(context),
          ),
          title: const Text('Manage Courses'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              adminSearchField(
                controller: _searchCtrl,
                hintText: 'Search courses...',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                isExpanded: true,
                value: _filterStatus,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Status')),
                  DropdownMenuItem(
                    value: 'published',
                    child: Text('Published'),
                  ),
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'archived', child: Text('Archived')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _filterStatus = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('courses')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];
                    final filtered = docs
                        .where((doc) => _matchesFilters(doc.data()))
                        .toList();

                    if (filtered.isEmpty) {
                      return const Center(child: Text('No courses found'));
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        final data = doc.data();
                        final docId = doc.id;

                        final title = (data['title'] as String?) ?? 'Untitled';
                        final instructor =
                            (data['instructor'] as String?) ?? 'Unknown';
                        final status =
                            (data['status'] as String?)?.toLowerCase() ??
                            'published';
                        final rating =
                            (data['rating'] as num?)?.toDouble() ?? 0.0;

                        return Dismissible(
                          key: ValueKey(docId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            color: Colors.red.shade400,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) async {
                            final copy = Map<String, dynamic>.from(data);
                            await _deleteCourse(context, docId, copy);
                          },
                          child: InkWell(
                            onTap: () =>
                                _showDetailsDialog(context, docId, data),
                            borderRadius: BorderRadius.circular(14),
                            child: adminListCard(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AdminColors.brandSoft,
                                    child: Text(
                                      title.isNotEmpty
                                          ? title[0].toUpperCase()
                                          : 'C',
                                      style: const TextStyle(
                                        color: AdminColors.brand,
                                        fontWeight: FontWeight.w700,
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
                                          title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          instructor,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            adminPill(
                                              status,
                                              status == 'published'
                                                  ? AdminColors.brand
                                                  : status == 'archived'
                                                  ? Colors.grey
                                                  : Colors.orange,
                                            ),
                                            if (rating > 0)
                                            Wrap(
                                              spacing: 8,
                                              children: [
                                                adminPill(
                                                  status,
                                                  status == 'published'
                                                      ? AdminColors.brand
                                                      : status == 'archived'
                                                      ? Colors.grey
                                                      : status == 'pending'
                                                      ? Colors.green
                                                      : Colors.orange,
                                                ),
                                                if (rating > 0)
                                                  adminPill(
                                                    '⭐ ${rating.toStringAsFixed(1)}',
                                                    AdminColors.accent,
                                                  ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Quick Approve button for pending courses
                                                if (status == 'pending')
                                                  Tooltip(
                                                    message: 'Approve this course',
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons.check_circle_outline,
                                                        color: Colors.green,
                                                      ),
                                                      onPressed: () async {
                                                        final confirmed = await showDialog<bool>(
                                                          context: context,
                                                          builder: (ctx) => AlertDialog(
                                                            title: const Text('Approve Course'),
                                                            content: Text(
                                                              'Approve "$title" and publish it for students?',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () => ctx.pop(false),
                                                                child: const Text('Cancel'),
                                                              ),
                                                              FilledButton(
                                                                onPressed: () => ctx.pop(true),
                                                                style: FilledButton.styleFrom(
                                                                  backgroundColor: Colors.green,
                                                                ),
                                                                child: const Text('Approve'),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                        if (confirmed == true) {
                                                          await FirebaseFirestore.instance
                                                              .collection('courses')
                                                              .doc(docId)
                                                              .update({
                                                                'status': 'active',
                                                                'isPublished': true,
                                                              });
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text('"$title" approved & published!'),
                                                                backgroundColor: Colors.green,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.more_vert,
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                                  onPressed: () =>
                                                      _showDetailsDialog(context, docId, data),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text((data['title'] as String?) ?? 'Course Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Instructor', (data['instructor'] as String?) ?? '-'),
              _detailRow('Category', (data['category'] as String?) ?? '-'),
              _detailRow(
                'Price',
                data['price']?.toString() ??
                    data['priceDisplay']?.toString() ??
                    'Free',
              ),
              _detailRow('Duration', '${data['durationHours'] ?? 0} hours'),
              _detailRow('Lessons', '${data['totalLessons'] ?? 0}'),
              _detailRow('Status', (data['status'] as String?) ?? 'published'),
              _detailRow('Rating', '${data['rating'] ?? 0.0} ⭐'),
              _detailRow('Students', '${data['enrollmentCount'] ?? 0}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              dialogContext.pop();
              _showEditCourseDialog(context, docId, data);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              dialogContext.pop();
              _showStatusDialog(
                context,
                docId,
                (data['status'] as String?) ?? 'published',
              );
            },
            child: const Text('Change Status'),
          ),
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showStatusDialog(BuildContext context, String docId, String current) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final status in ['published', 'draft', 'archived', 'pending'])
              RadioMenuButton<String>(
                value: status,
                groupValue: current,
                onChanged: (value) async {
                  if (value == null) return;
                  await FirebaseFirestore.instance
                      .collection('courses')
                      .doc(docId)
                      .update({'status': value});
                  if (dialogContext.mounted) dialogContext.pop();
                },
                child: Text(status[0].toUpperCase() + status.substring(1)),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditCourseDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final videoUrlController = TextEditingController(
      text: (data['videoUrl'] as String?)?.trim() ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: videoUrlController,
                decoration: InputDecoration(
                  labelText: 'YouTube Video URL',
                  hintText: 'https://www.youtube.com/watch?v=...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final videoUrl = videoUrlController.text.trim();

              // Validate URL if not empty
              if (videoUrl.isNotEmpty &&
                  !videoUrl.startsWith('https://www.youtube.com') &&
                  !videoUrl.startsWith('https://youtu.be')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL must be from youtube.com or youtu.be'),
                  ),
                );
                return;
              }

              try {
                final updateMap = <String, dynamic>{};
                if (videoUrl.isEmpty) {
                  updateMap['videoUrl'] = FieldValue.delete();
                } else {
                  updateMap['videoUrl'] = videoUrl;
                }

                await FirebaseFirestore.instance
                    .collection('courses')
                    .doc(docId)
                    .update(updateMap);

                if (dialogContext.mounted) {
                  dialogContext.pop();
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Course updated')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
