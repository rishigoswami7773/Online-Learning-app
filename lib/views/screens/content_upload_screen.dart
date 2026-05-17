import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../utils/uid_resolver.dart';

class ContentUploadScreen extends StatefulWidget {
  const ContentUploadScreen({super.key});

  @override
  State<ContentUploadScreen> createState() => _ContentUploadScreenState();
}

class _ContentUploadScreenState extends State<ContentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  String? _courseId;
  String? _courseTitleForPreFilled; // Track if courseId came from route
  PlatformFile? _pickedFile;
  bool _saving = false;
  double _uploadProgress = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_courseId != null) return;

    final extra = GoRouterState.of(context).extra;
    final args = extra is Map<String, dynamic> ? extra : null;
    final selectedCourseId = args?['courseId']?.toString().trim();
    final courseTitle = args?['courseTitle']?.toString().trim();
    if (selectedCourseId != null && selectedCourseId.isNotEmpty) {
      _courseId = selectedCourseId;
      _courseTitleForPreFilled = courseTitle; // BUG 7: Track pre-filled course
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp4', 'mov', 'avi', 'mkv'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
        _uploadProgress = 0;
      });
    }
  }

  String _getFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ext == 'pdf' ? 'pdf' : 'video';
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_courseId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a course')));
      return;
    }
    if (_pickedFile == null || _pickedFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload')),
      );
      return;
    }

    final uid = UidResolver.uid ?? '';
    setState(() => _saving = true);
    try {
      // Upload file to Firebase Storage
      final ext = (_pickedFile!.extension ?? '').toLowerCase();
      final storageRef = FirebaseStorage.instance.ref().child(
        'courses/$_courseId/materials/${_pickedFile!.name}',
      );

      final task = storageRef.putData(
        _pickedFile!.bytes!,
        SettableMetadata(
          contentType: ext == 'pdf' ? 'application/pdf' : 'video/$ext',
        ),
      );

      task.snapshotEvents.listen((event) {
        if (!mounted) return;
        final total = event.totalBytes;
        if (total > 0) {
          setState(() => _uploadProgress = event.bytesTransferred / total);
        }
      });

      await task;
      final downloadUrl = await storageRef.getDownloadURL();
      final fileType = _getFileType(_pickedFile!.name);

      // Save metadata to course_materials collection
      await FirebaseFirestore.instance.collection('course_materials').add({
        'courseId': _courseId,
        'mentorId': uid,
        'title': _titleCtrl.text.trim(),
        'fileUrl': downloadUrl,
        'fileType': fileType,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      // Also update the courses document
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(_courseId)
          .update({
            'contentUrl': downloadUrl,
            'contentType': fileType,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Upload complete')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Content'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.mentorDashboard);
            }
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .where('mentorId', isEqualTo: UidResolver.uid ?? '')
            .snapshots(),
        builder: (context, snapshot) {
          final courses = snapshot.data?.docs ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (courses.isEmpty) {
            return const Center(
              child: Text('Create a course first to upload materials.'),
            );
          }
          _courseId ??= courses.first.id;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // BUG 7 FIX: Show course selection with validation
                  if (_courseTitleForPreFilled != null)
                    // When courseId is pre-filled from route, show as read-only chip
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Course (Pre-selected)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(_courseTitleForPreFilled ?? 'Unknown'),
                            avatar: const Icon(Icons.menu_book_rounded),
                            backgroundColor: Colors.blue.shade50,
                          ),
                        ],
                      ),
                    )
                  else
                    // When courseId is not pre-filled, show dropdown to select
                    DropdownButtonFormField<String>(
                      initialValue: _courseId,
                      items: courses
                          .map(
                            (doc) => DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(
                                (doc.data()['title'] ?? 'Untitled').toString(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _courseId = value),
                      decoration: const InputDecoration(
                        labelText: 'Select Course',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null ? 'Please select a course' : null,
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Material Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter title' : null,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: (_saving) ? null : _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      _pickedFile == null
                          ? 'Pick Video or PDF'
                          : _pickedFile!.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_pickedFile != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Type: ${(_pickedFile!.extension ?? '').toUpperCase()}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                  if (_saving) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _uploadProgress > 0 ? _uploadProgress : null,
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: (_saving) ? null : _upload,
                    icon: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: const Text('Upload to Firebase'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
