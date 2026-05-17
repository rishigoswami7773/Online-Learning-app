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

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _videoUrlController = TextEditingController();

  String? _category;
  String? _level;
  bool _saving = false;
  bool _isEdit = false;
  String? _courseId;

  List<String> _categories = [
    'Programming',
    'Design',
    'Data Science',
    'Business',
    'Marketing',
  ];
  static const _levels = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = UidResolver.uid;
      if (uid == null && mounted) {
        context.go(AppRoutes.login);
      }
    });
  }

  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('categories')
          .get();
      if (snap.docs.isNotEmpty) {
        final cats = snap.docs
            .map((d) => (d.data()['name'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
        if (mounted) {
          setState(() => _categories = cats);
        }
      }
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    final data = extra is Map<String, dynamic> ? extra : null;
    if (data != null && !_isEdit) {
      _isEdit = true;
      _courseId = (data['id'] as String?)?.trim();
      _titleController.text = (data['title'] as String?) ?? '';
      _descriptionController.text = (data['description'] as String?) ?? '';
      _priceController.text = (data['price'] as num?)?.toString() ?? '';
      _videoUrlController.text = (data['videoUrl'] as String?)?.trim() ?? '';
      _category = (data['category'] as String?)?.trim();
      _level = (data['level'] as String?)?.trim();
      _category = (_category != null && !_categories.contains(_category))
          ? _categories.first
          : _category;
      _level = (_level != null && !_levels.contains(_level))
          ? _levels.first
          : _level;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = UidResolver.uid;
    if (uid == null && mounted) {
      context.go(AppRoutes.login);
      return;
    }
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final courseRef = _isEdit && _courseId != null
          ? FirebaseFirestore.instance.collection('courses').doc(_courseId)
          : FirebaseFirestore.instance.collection('courses').doc();

      final mentorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      final mentorName =
          (mentorDoc.data()?['name'] as String?)?.trim().isNotEmpty == true
          ? (mentorDoc.data()?['name'] as String).trim()
          : 'Mentor';

      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final videoUrl = _videoUrlController.text.trim();

      if (_isEdit && _courseId != null) {
        final updatePayload = <String, dynamic>{
          'mentorId': uid,
          'instructor': mentorName,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _category,
          'level': _level,
          'price': price,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (videoUrl.isNotEmpty) updatePayload['videoUrl'] = videoUrl;

        await courseRef.update(updatePayload);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Course updated successfully!')),
        );
      } else {
        // New course: status = 'pending', admin must approve
        final createPayload = <String, dynamic>{
          'mentorId': uid,
          'instructor': mentorName,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _category,
          'level': _level,
          'price': price,
          'status': 'pending',
          'isPublished': false,
          'enrollmentCount': 0,
          'averageRating': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (videoUrl.isNotEmpty) createPayload['videoUrl'] = videoUrl;

        await courseRef.set(createPayload);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Course submitted for admin review!'),
            backgroundColor: _mentorTeal,
          ),
        );
      }

      if (!mounted) return;
      context.go(AppRoutes.mentorDashboard);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save course: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _mentorTeal),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _mentorTeal, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!UidResolver.isLoggedIn) {
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
          backgroundColor: _mentorTeal,
          elevation: 0,
          title: Text(
            _isEdit ? 'Edit Course' : 'Create New Course',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _safeBackToMentorDashboard(context),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Info banner ────────────────────────────────────
                      if (!_isEdit)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _mentorTeal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _mentorTeal.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: _mentorTeal,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Your course will be reviewed by admin before it is published to students.',
                                  style: TextStyle(
                                    color: _mentorTeal,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Course Details Card ────────────────────────────
                      _sectionCard(
                        title: 'Course Details',
                        icon: Icons.menu_book_outlined,
                        children: [
                          // Title
                          TextFormField(
                            controller: _titleController,
                            decoration: _fieldDecoration(
                              'Course Title *',
                              Icons.title,
                            ),
                            validator: (value) =>
                                (value ?? '').trim().isEmpty
                                ? 'Enter a course title'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: _fieldDecoration(
                              'Description *',
                              Icons.description_outlined,
                            ),
                            validator: (value) =>
                                (value ?? '').trim().isEmpty
                                ? 'Enter a course description'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Category & Level row
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _category,
                                  decoration: _fieldDecoration(
                                    'Category *',
                                    Icons.category_outlined,
                                  ),
                                  items: _categories
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item,
                                          child: Text(
                                            item,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _category = value),
                                  validator: (value) =>
                                      value == null ? 'Select category' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _level,
                                  decoration: _fieldDecoration(
                                    'Level *',
                                    Icons.layers_outlined,
                                  ),
                                  items: _levels
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item,
                                          child: Text(item),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _level = value),
                                  validator: (value) =>
                                      value == null ? 'Select level' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Price
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _fieldDecoration(
                              'Course Price (₹) *',
                              Icons.currency_rupee,
                            ),
                            validator: (v) =>
                                (double.tryParse(v ?? '') ?? 0) > 0
                                ? null
                                : 'Enter a valid price (e.g. 499)',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Video Section Card ─────────────────────────────
                      _sectionCard(
                        title: 'Course Video',
                        icon: Icons.play_circle_outline,
                        children: [
                          Text(
                            'Add a YouTube video URL for your course preview or main lesson.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _videoUrlController,
                            decoration: _fieldDecoration(
                              'YouTube Video URL (optional)',
                              Icons.video_library_outlined,
                            ).copyWith(
                              hintText: 'https://www.youtube.com/watch?v=...',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final url = v.trim();
                              if (!url.startsWith('https://www.youtube.com') &&
                                  !url.startsWith('https://youtu.be')) {
                                return 'URL must be from youtube.com or youtu.be';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          if (_videoUrlController.text.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      'Video URL added',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      _videoUrlController.clear();
                                      setState(() {});
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Sticky Bottom Bar ──────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 12,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    12 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  _titleController.clear();
                                  _descriptionController.clear();
                                  _priceController.clear();
                                  _videoUrlController.clear();
                                  setState(() {
                                    _category = null;
                                    _level = null;
                                  });
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _mentorTeal,
                            side: const BorderSide(color: _mentorTeal),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Clear',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _submit,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _isEdit ? Icons.save_outlined : Icons.rocket_launch_outlined,
                                  size: 18,
                                ),
                          label: Text(
                            _isEdit ? 'Save Changes' : 'Submit for Review',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _mentorTeal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _mentorTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _mentorTeal, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
