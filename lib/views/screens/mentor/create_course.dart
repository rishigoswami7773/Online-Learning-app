import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import '../../../models/course_repo.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _category = 'Development';
  bool _isSubmitting = false;

  bool _initialized = false;
  bool _isEdit = false;
  String? _editingId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.isNotEmpty) {
        // prefill for edit
        _isEdit = true;
        _editingId = args['id'] as String?;
        _titleCtrl.text = args['title'] as String? ?? '';
        _descCtrl.text = args['description'] as String? ?? '';
        _category = args['category'] as String? ?? _category;
        final priceVal = args['price'];
        _priceCtrl.text = (priceVal is num)
            ? priceVal.toString()
            : (priceVal as String?) ?? '';
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final price = double.tryParse(_priceCtrl.text) ?? 0.0;
    final id = _isEdit
        ? _editingId ?? 'c${DateTime.now().millisecondsSinceEpoch}'
        : 'c${DateTime.now().millisecondsSinceEpoch}';

    final course = Course(
      id: id,
      title: _titleCtrl.text.trim(),
      instructor: 'You',
      rating: 0.0,
      description: _descCtrl.text.trim(),
      category: _category,
      price: price,
      published: false,
    );

    await Future.delayed(const Duration(milliseconds: 600)); // simulate network

    if (_isEdit) {
      CourseRepository.instance.updateCourse(id, course);
    } else {
      CourseRepository.instance.addCourse(course);
    }

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_isEdit ? 'Course Updated' : 'Course Created'),
        content: Text(
          '"${course.title}" ${_isEdit ? 'updated' : 'created'} successfully.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(
                context,
              ).pushReplacementNamed(AppRoutes.mentorManageCourses);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Course' : 'Create Course')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Course Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Cover
                    GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pick cover image (demo)'),
                        ),
                      ),
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade100,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.photo, size: 40),
                              SizedBox(height: 8),
                              Text('Tap to add cover image'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter course title'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      items: const [
                        DropdownMenuItem(
                          value: 'Development',
                          child: Text('Development'),
                        ),
                        DropdownMenuItem(
                          value: 'Design',
                          child: Text('Design'),
                        ),
                        DropdownMenuItem(
                          value: 'Business',
                          child: Text('Business'),
                        ),
                        DropdownMenuItem(
                          value: 'Marketing',
                          child: Text('Marketing'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _category = v ?? _category),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (USD)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter price';
                        final p = double.tryParse(v);
                        if (p == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 6,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter description'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isSubmitting
                            ? 'Saving...'
                            : (_isEdit ? 'Save Changes' : 'Create Course'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
