import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'admin_widgets.dart';

class AdminContentUploadScreen extends StatefulWidget {
  const AdminContentUploadScreen({super.key});

  @override
  State<AdminContentUploadScreen> createState() =>
      _AdminContentUploadScreenState();
}

class _AdminContentUploadScreenState extends State<AdminContentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  final _priceController = TextEditingController();

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _courses = [];
  bool _loadingCourses = true;
  bool _uploading = false;
  double _progress = 0.0;

  String? _selectedCourseId;
  String _fileKind = 'image';
  PlatformFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _youtubeUrlController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('courses').get();
      if (!mounted) return;
      setState(() {
        _courses = snap.docs;
        _loadingCourses = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCourses = false);
    }
  }

  Future<void> _pickFile() async {
    final allowedExtensions = switch (_fileKind) {
      'image' => ['png', 'jpg', 'jpeg', 'webp'],
      'pdf' => ['pdf'],
      _ => ['mp4', 'mov', 'mkv', 'webm'],
    };

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    setState(() => _pickedFile = result.files.first);
  }

  Future<String> _uploadFile(String courseId, PlatformFile file) async {
    final pathName = file.name;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final storageRef = FirebaseStorage.instance.ref().child(
      'content/$courseId/${stamp}_$pathName',
    );
    final uploadTask = storageRef.putFile(File(file.path!));
    uploadTask.snapshotEvents.listen((event) {
      if (!mounted) return;
      final total = event.totalBytes;
      if (total <= 0) return;
      setState(() => _progress = event.bytesTransferred / total);
    });
    await uploadTask;
    return storageRef.getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a course')));
      return;
    }

    final youtubeUrl = _youtubeUrlController.text.trim();
    if (youtubeUrl.isEmpty &&
        (_pickedFile == null || _pickedFile!.path == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a YouTube URL or pick a file')),
      );
      return;
    }

    setState(() {
      _uploading = true;
      _progress = 0.0;
    });

    try {
      final courseRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(_selectedCourseId);
      final uploadedAt = Timestamp.now();

      final updateData = <String, dynamic>{'contentUpdatedAt': uploadedAt};

      if (youtubeUrl.isNotEmpty) {
        updateData['videoUrl'] = youtubeUrl;
        updateData['contentUploads'] = FieldValue.arrayUnion([
          {
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'type': 'youtube',
            'url': youtubeUrl,
            'uploadedAt': uploadedAt,
          },
        ]);
      }

      if (_pickedFile != null && _pickedFile!.path != null) {
        final downloadUrl = await _uploadFile(_selectedCourseId!, _pickedFile!);
        final fileEntry = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'type': _fileKind,
          'url': downloadUrl,
          'filename': _pickedFile!.name,
          'uploadedAt': uploadedAt,
        };

        if (updateData.containsKey('contentUploads')) {
          // If we already added youtubeUrl, this might conflict with arrayUnion
          // but for simplicity in this flow we update it sequentially or combine.
          // Firestore update with multiple FieldValue.arrayUnion calls on same field is risky.
          // We will update correctly below.
        } else {
          updateData['contentUploads'] = FieldValue.arrayUnion([fileEntry]);
        }

        if (_fileKind == 'image') {
          updateData['thumbnailUrl'] = downloadUrl;
        } else if (_fileKind == 'pdf') {
          updateData['pdfUrl'] = downloadUrl;
        }
      }

      await courseRef.update(updateData);

      // If both were present, the updateData logic above might need to be refined
      // to avoid overwriting or missing one arrayUnion.
      // Correcting: If both present, use a list of entries.
      if (youtubeUrl.isNotEmpty &&
          (_pickedFile != null && _pickedFile!.path != null)) {
        // Redo to be sure both are added
        final downloadUrl = await _uploadFile(_selectedCourseId!, _pickedFile!);
        await courseRef.update({
          'contentUploads': FieldValue.arrayUnion([
            {
              'title': _titleController.text.trim(),
              'description': _descriptionController.text.trim(),
              'type': _fileKind,
              'url': downloadUrl,
              'filename': _pickedFile!.name,
              'uploadedAt': uploadedAt,
            },
          ]),
        });
      }

      if (!mounted) return;
      setState(() {
        _uploading = false;
        _progress = 0.0;
        _pickedFile = null;
        _titleController.clear();
        _descriptionController.clear();
        _youtubeUrlController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _progress = 0.0;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageWrapper(
      title: 'Upload Content',
      showBackButton: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Upload content to a course',
                style: AdminTextStyles.sectionTitle,
              ),
              const SizedBox(height: 16),
              adminListCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _loadingCourses
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            initialValue: _selectedCourseId,
                            decoration: InputDecoration(
                              labelText: 'Course',
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(14),
                                ),
                              ),
                            ),
                            items: _courses
                                .map(
                                  (doc) => DropdownMenuItem(
                                    value: doc.id,
                                    child: Text(
                                      (doc.data()['title'] as String?) ??
                                          'Untitled course',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedCourseId = value),
                            validator: (value) =>
                                value == null ? 'Select a course' : null,
                          ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _fileKind,
                      decoration: InputDecoration(
                        labelText: 'File type',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'image', child: Text('Image')),
                        DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _fileKind = value;
                          _pickedFile = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Content title',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Title is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'YouTube Video URL',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _youtubeUrlController,
                      decoration: InputDecoration(
                        labelText:
                            'Paste YouTube link (e.g. https://youtu.be/xxxxx)',
                        prefixIcon: Icon(
                          Icons.play_circle_outline,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Attach Image / PDF (optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _uploading ? null : _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        _pickedFile == null ? 'Pick file' : _pickedFile!.name,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminColors.brand,
                        side: const BorderSide(color: AdminColors.brand),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_uploading) ...[
                      LinearProgressIndicator(value: _progress),
                      const SizedBox(height: 8),
                      Text('${(_progress * 100).toStringAsFixed(0)}% uploaded'),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _uploading ? null : _submit,
                        icon: const Icon(Icons.cloud_upload),
                        label: Text(
                          _uploading ? 'Uploading...' : 'Upload Content',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.brand,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
