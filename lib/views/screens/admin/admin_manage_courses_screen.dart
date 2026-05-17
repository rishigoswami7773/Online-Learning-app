import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_widgets.dart';

class AdminManageCoursesScreen extends StatelessWidget {
  const AdminManageCoursesScreen({super.key});

  Future<void> _togglePublish(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> ref,
    bool publish,
  ) async {
    try {
      await ref.update({
        'isPublished': publish,
        'status': publish ? 'active' : 'draft',
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(publish ? 'Course published' : 'Course unpublished'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update course: $e')));
    }
  }

  Future<void> _deleteCourse(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete course?'),
        content: const Text(
          'This will delete the course document. Related data will remain in Firestore unless removed separately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Course deleted')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete course: $e')));
    }
  }

  Future<void> _approveCourse(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      await ref.update({'status': 'active', 'isPublished': true});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course approved and published')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to approve course: $e')));
    }
  }

  Future<void> _rejectCourse(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      await ref.update({'status': 'rejected', 'isPublished': false});
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Course rejected')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reject course: $e')));
    }
  }

  String _formatStatus(bool published) => published ? 'Published' : 'Draft';

  Color _statusColor(bool published) =>
      published ? Colors.green : Colors.orange;

  @override
  Widget build(BuildContext context) {
    return AdminPageWrapper(
      title: 'Manage Courses',
      showBackButton: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          children: [
            adminHeroHeader(
              title: 'Manage Courses',
              subtitle: 'Review, publish, and remove course content',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.separated(
                      itemCount: 5,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) => const ShimmerBox(
                        width: double.infinity,
                        height: 140,
                        borderRadius: BorderRadius.all(Radius.circular(18)),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Unable to load courses: ${snapshot.error}'),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 56,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(height: 10),
                          Text('No courses found'),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final title =
                          (data['title'] as String?) ?? 'Untitled course';
                      final mentorId = (data['mentorId'] as String?) ?? '';
                      final enrollmentCount =
                          (data['enrollmentCount'] as num?)?.toInt() ?? 0;
                      final rating =
                          (data['averageRating'] as num?)?.toDouble() ?? 0.0;
                      final published = (data['isPublished'] as bool?) ?? false;
                      final status = _formatStatus(published);
                      final firestoreStatus =
                          (data['status'] as String?) ??
                          (published ? 'active' : 'draft');
                      final isPending = firestoreStatus == 'pending';

                      return StaggeredItem(
                        delay: Duration(milliseconds: index * 50),
                        child: adminListCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
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
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        FutureBuilder<
                                          DocumentSnapshot<Map<String, dynamic>>
                                        >(
                                          future: mentorId.isEmpty
                                              ? null
                                              : FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(mentorId)
                                                    .get(),
                                          builder: (context, mentorSnap) {
                                            final mentorData =
                                                mentorSnap.data?.data() ??
                                                <String, dynamic>{};
                                            final mentorName =
                                                (mentorData['name']
                                                    as String?) ??
                                                (data['instructor']
                                                    as String?) ??
                                                'Unknown mentor';
                                            return Text(
                                              mentorName,
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            adminPill(
                                              'Enrollments: $enrollmentCount',
                                              AdminColors.brand,
                                            ),
                                            adminPill(
                                              'Rating: ${rating.toStringAsFixed(1)}',
                                              AdminColors.accent,
                                            ),
                                            adminPill(
                                              '₹${(data['price'] as num?)?.toStringAsFixed(0) ?? "Free"}',
                                              const Color(0xFFE7F6F7),
                                              textColor: const Color(
                                                0xFF0E7C86,
                                              ),
                                            ),
                                            if (isPending)
                                              adminPill(
                                                'Pending Review',
                                                Colors.orange,
                                              )
                                            else
                                              adminPill(
                                                status,
                                                _statusColor(published),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: published,
                                    activeThumbColor: AdminColors.brand,
                                    onChanged: (value) => _togglePublish(
                                      context,
                                      doc.reference,
                                      value,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (isPending)
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _approveCourse(
                                          context,
                                          doc.reference,
                                        ),
                                        icon: const Icon(Icons.check, size: 14),
                                        label: const Text('Approve'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AdminColors.brand,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _rejectCourse(
                                          context,
                                          doc.reference,
                                        ),
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                          size: 14,
                                        ),
                                        label: const Text('Reject'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(
                                            color: Colors.red,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _deleteCourse(
                                          context,
                                          doc.reference,
                                        ),
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 14,
                                        ),
                                        label: const Text('Delete'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(
                                            color: Colors.red,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _togglePublish(
                                        context,
                                        doc.reference,
                                        !published,
                                      ),
                                      icon: Icon(
                                        published
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        size: 14,
                                      ),
                                      label: Text(
                                        published ? 'Unpublish' : 'Publish',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AdminColors.brand,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _deleteCourse(context, doc.reference),
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 14,
                                      ),
                                      label: const Text('Delete'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
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
          ],
        ),
      ),
    );
  }
}

class AdminCourseDetailScreen extends StatefulWidget {
  const AdminCourseDetailScreen({super.key, required this.courseData});

  final Map<String, dynamic> courseData;

  @override
  State<AdminCourseDetailScreen> createState() =>
      _AdminCourseDetailScreenState();
}

class _AdminCourseDetailScreenState extends State<AdminCourseDetailScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: (widget.courseData['title'] as String?) ?? '',
    );
    _categoryController = TextEditingController(
      text: (widget.courseData['category'] as String?) ?? '',
    );
    _descriptionController = TextEditingController(
      text: (widget.courseData['description'] as String?) ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final courseId = (widget.courseData['id'] as String?) ?? '';
    if (courseId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .update({
          'title': _titleController.text.trim(),
          'category': _categoryController.text.trim(),
          'description': _descriptionController.text.trim(),
        });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Course updated')));
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageWrapper(
      title: 'Course Details',
      showBackButton: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
