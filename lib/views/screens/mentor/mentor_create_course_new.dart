import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/uid_resolver.dart';

class MentorCreateCourseScreenNew extends StatefulWidget {
  const MentorCreateCourseScreenNew({super.key});

  @override
  State<MentorCreateCourseScreenNew> createState() =>
      _MentorCreateCourseScreenNewState();
}

class _MentorCreateCourseScreenNewState
    extends State<MentorCreateCourseScreenNew> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _instructorCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _lessonsCtrl = TextEditingController();
  final _youtubeUrlCtrl = TextEditingController();

  // File upload fields
  File? _selectedPdfFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  List<Map<String, String>> _uploadedMaterials = [];

  final List<Map<String, dynamic>> _quizQuestions = [];

  String _courseId = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!UidResolver.isLoggedIn && mounted) {
        await Future.delayed(Duration.zero);
        if (!mounted) return;
        context.go(AppRoutes.login);
        return;
      }
      _loadCourse();
    });
  }

  void _loadCourse() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _courseId = args?['courseId']?.toString() ?? '';

    if (_courseId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(_courseId)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        final data = doc.data() ?? {};
        _titleCtrl.text = data['title'] ?? '';
        _descriptionCtrl.text = data['description'] ?? '';
        _instructorCtrl.text = data['instructor'] ?? '';
        _categoryCtrl.text = data['category'] ?? '';
        _priceCtrl.text = (data['price'] ?? '').toString();
        _durationCtrl.text = (data['durationHours'] ?? '').toString();
        _lessonsCtrl.text = (data['totalLessons'] ?? '').toString();

        // YouTube URL
        _youtubeUrlCtrl.text = (data['youtubeUrl'] ?? '') as String;

        // Load uploaded materials (PDFs only)
        if (data['courseMaterials'] is List) {
          final materials = (data['courseMaterials'] as List)
              .cast<Map<String, dynamic>>()
              .where((m) => (m['type'] ?? '') != 'video')
              .map(
                (m) => <String, String>{
                  'type': (m['type'] ?? 'unknown') as String,
                  'url': (m['url'] ?? '') as String,
                  'name': (m['name'] ?? 'Material') as String,
                },
              )
              .toList();
          if (mounted) {
            setState(() => _uploadedMaterials = materials);
          }
          // Load quiz questions if present
          if (data['quizQuestions'] is List) {
            if (mounted) {
              setState(() {
                _quizQuestions.clear();
                _quizQuestions.addAll(
                  (data['quizQuestions'] as List).cast<Map<String, dynamic>>(),
                );
              });
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _instructorCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _lessonsCtrl.dispose();
    _youtubeUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        setState(() => _selectedPdfFile = file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking PDF: $e')));
      }
    }
  }

  Future<String?> _uploadFile(File file, String fileType) async {
    try {
      setState(() => _isUploading = true);
      final uid = UidResolver.uid;
      if (uid == null) return null;

      final fileName =
          '${uid}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('course_materials')
          .child(fileType)
          .child(fileName);

      final uploadTask = ref.putFile(file);
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (mounted) {
          setState(() => _uploadProgress = progress);
        }
      });

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      if (!mounted) return downloadUrl;
      setState(() => _isUploading = false);
      return downloadUrl;
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload error: $e')));
      }
      return null;
    }
  }

  Future<void> _uploadCoursePdf() async {
    if (_selectedPdfFile == null) return;
    final url = await _uploadFile(_selectedPdfFile!, 'pdfs');
    if (url != null && mounted) {
      setState(() {
        _uploadedMaterials.add({
          'type': 'pdf',
          'url': url,
          'name': _selectedPdfFile?.path.split('/').last ?? 'pdf',
        });
        _selectedPdfFile = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF uploaded successfully!')),
        );
      }
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final uid = UidResolver.uid;
      if (uid == null) {
        if (mounted) context.go(AppRoutes.login);
        return;
      }
      final now = FieldValue.serverTimestamp();

      final data = {
        'title': _titleCtrl.text,
        'description': _descriptionCtrl.text,
        'instructor': _instructorCtrl.text,
        'category': _categoryCtrl.text,
        'price': double.tryParse(_priceCtrl.text) ?? 0.0,
        'durationHours': int.tryParse(_durationCtrl.text) ?? 0,
        'totalLessons': int.tryParse(_lessonsCtrl.text) ?? 0,
        'mentorId': uid,
        'status': _courseId.isEmpty ? 'pending' : 'draft',
        'rating': 0.0,
        'averageRating': 0.0,
        'reviewCount': 0,
        'courseMaterials': _uploadedMaterials,
        'youtubeUrl': _youtubeUrlCtrl.text.trim(),
        'quizQuestions': _quizQuestions,
      };

      if (_courseId.isEmpty) {
        data['createdAt'] = now;
        await FirebaseFirestore.instance.collection('courses').add(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course created successfully!')),
          );
        }
      } else {
        data['updatedAt'] = now;
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(_courseId)
            .update(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course updated successfully!')),
          );
        }
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!UidResolver.isLoggedIn) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.mentorDashboard);
            }
          },
        ),
        title: Text(_courseId.isEmpty ? 'Create Course' : 'Edit Course'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Course Title'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instructorCtrl,
                decoration: const InputDecoration(labelText: 'Instructor Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                decoration: InputDecoration(
                  labelText: 'Course Price (₹)',
                  hintText: 'e.g. 1499',
                  prefixIcon: const Icon(
                    Icons.currency_rupee,
                    color: Color(0xFF0E7C86),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (double.tryParse(v ?? '') ?? 0) > 0
                    ? null
                    : 'Price must be greater than ₹0',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Duration (hours)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lessonsCtrl,
                decoration: const InputDecoration(labelText: 'Total Lessons'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _youtubeUrlCtrl,
                decoration: InputDecoration(
                  labelText: 'YouTube Video URL',
                  hintText: 'https://youtube.com/watch?v=...',
                  prefixIcon: const Icon(
                    Icons.play_circle_outline,
                    color: Color(0xFFFF0000),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.url,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return null;
                  }
                  final uri = Uri.tryParse(v.trim());
                  if (uri == null || !uri.hasAbsolutePath) {
                    return 'Enter a valid URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Content Upload Section
              const Text(
                'Course Materials',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              // PDF Upload
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload Course Materials (PDF)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedPdfFile != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Selected: ${_selectedPdfFile!.path.split('/').last}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      if (_isUploading && _uploadProgress > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Uploading...',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(value: _uploadProgress),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isUploading ? null : _pickPdfFile,
                              icon: const Icon(Icons.description),
                              label: const Text('Pick PDF'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_selectedPdfFile != null)
                            FilledButton.icon(
                              onPressed: _isUploading ? null : _uploadCoursePdf,
                              icon: const Icon(Icons.upload),
                              label: const Text('Upload'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Uploaded Materials List
              if (_uploadedMaterials.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uploaded Materials',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _uploadedMaterials.length,
                      itemBuilder: (context, idx) {
                        final mat = _uploadedMaterials[idx];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            mat['type'] == 'video'
                                ? Icons.video_library
                                : Icons.description,
                          ),
                          title: Text(
                            mat['name'] ?? 'Material',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, size: 16),
                            onPressed: () {
                              setState(() => _uploadedMaterials.removeAt(idx));
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              // Quiz section
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Quiz Questions',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showAddQuestionDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Question'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_quizQuestions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No quiz questions added yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _quizQuestions.length,
                  itemBuilder: (context, idx) {
                    final q = _quizQuestions[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 14,
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        title: Text(
                          q['question'] as String? ?? '',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          'Correct: ${(q['options'] as List?)?[(q['correctIndex'] as int? ?? 0)] ?? ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              setState(() => _quizQuestions.removeAt(idx)),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading || _isUploading ? null : _saveCourse,
                  child: Text(_isLoading ? 'Saving...' : 'Save Course'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddQuestionDialog() {
    final questionCtrl = TextEditingController();
    final optionCtrls = List.generate(4, (_) => TextEditingController());
    int selectedCorrect = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Quiz Question',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: questionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  4,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => setModalState(() => selectedCorrect = i),
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Icon(
                              selectedCorrect == i
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 20,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: optionCtrls[i],
                            decoration: InputDecoration(
                              labelText:
                                  'Option ${i + 1}${i == selectedCorrect ? ' (Correct)' : ''}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (questionCtrl.text.trim().isEmpty) return;
                      final opts = optionCtrls
                          .map((c) => c.text.trim())
                          .toList();
                      if (opts.any((o) => o.isEmpty)) return;
                      setState(() {
                        _quizQuestions.add({
                          'question': questionCtrl.text.trim(),
                          'options': opts,
                          'correctIndex': selectedCorrect,
                        });
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save Question'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
