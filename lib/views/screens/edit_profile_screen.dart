import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../controllers/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    this.userProfile = const <String, dynamic>{},
    this.studentProfile = const <String, dynamic>{},
  });

  final Map<String, dynamic> userProfile;
  final Map<String, dynamic> studentProfile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  ImageProvider? _avatarProvider(String path) {
    final normalized = path.trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return NetworkImage(normalized);
    }
    final file = File(normalized);
    if (!file.existsSync()) {
      return null;
    }
    return FileImage(file);
  }

  final _profileController = ProfileController();
  final _formKey = GlobalKey<FormState>();

  static const List<String> _genderOptions = <String>[
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];
  static const List<String> _educationOptions = <String>[
    'School',
    'College',
    'Professional',
  ];
  static const List<String> _streamOptions = <String>[
    'Science',
    'Commerce',
    'Arts',
    'Other',
  ];
  static const List<String> _languageOptions = <String>[
    'English',
    'Hindi',
    'Gujarati',
    'Other',
  ];
  static const List<String> _availableCourses = <String>[
    'Flutter App Development',
    'Python for Beginners',
    'Digital Marketing Basics',
    'Business Communication',
    'Data Analytics Foundations',
    'Commerce Career Prep',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _countryController;
  late final TextEditingController _classYearController;
  late final TextEditingController _learningGoalsController;

  DateTime? _dob;
  String _gender = 'Prefer not to say';
  String _educationLevel = 'School';
  String _stream = 'Science';
  String _languagePreference = 'English';
  String _profileImageUrl = '';
  final Set<String> _selectedCourses = <String>{};

  bool _isSaving = false;
  bool _isUploadingImage = false;

  String _asText(dynamic value, {String fallback = ''}) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  DateTime? _toDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }

  String _dateLabel(DateTime? value) {
    if (value == null) {
      return 'Select date of birth';
    }
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2008, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked == null) {
      return;
    }
    setState(() => _dob = picked);
  }

  Future<void> _pickAndUploadImageFromFiles() async {
    if (_isUploadingImage) {
      return;
    }

    final fileResult = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: false,
    );

    final filePath = fileResult?.files.single.path;
    if (filePath == null || filePath.trim().isEmpty) {
      return;
    }

    setState(() => _isUploadingImage = true);
    try {
      final imageUrl = await _profileController.uploadProfileImageFromPath(
        filePath: filePath,
      );
      if (!mounted) {
        return;
      }
      setState(() => _profileImageUrl = imageUrl);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile image updated.')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      final message = e.toString().replaceFirst('Bad state: ', '').trim();
      if (message.contains('canceled')) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image upload failed: $message')));
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final userProfile = widget.userProfile;
    final studentProfile = widget.studentProfile;
    final preferences = Map<String, dynamic>.from(
      studentProfile['preferences'] as Map? ?? const <String, dynamic>{},
    );
    final location = Map<String, dynamic>.from(
      preferences['location'] as Map? ?? const <String, dynamic>{},
    );

    _nameController = TextEditingController(text: _asText(userProfile['name']));
    _emailController = TextEditingController(
      text: _asText(userProfile['email']),
    );
    _phoneController = TextEditingController(
      text: _asText(userProfile['phone']),
    );
    _cityController = TextEditingController(
      text: _asText(userProfile['city'], fallback: _asText(location['city'])),
    );
    _stateController = TextEditingController(
      text: _asText(userProfile['state'], fallback: _asText(location['state'])),
    );
    _countryController = TextEditingController(
      text: _asText(
        userProfile['country'],
        fallback: _asText(location['country'], fallback: 'India'),
      ),
    );
    _classYearController = TextEditingController(
      text: _asText(studentProfile['classYear']),
    );
    _learningGoalsController = TextEditingController(
      text: _asText(
        userProfile['learningGoals'],
        fallback: _asText(
          studentProfile['learningGoals'],
          fallback: _asText(preferences['learningGoal']),
        ),
      ),
    );

    _profileImageUrl = _asText(userProfile['profileImage']);
    _dob = _toDate(userProfile['dob']) ?? _toDate(studentProfile['dob']);

    final profileGender = _asText(
      userProfile['gender'],
      fallback: _asText(studentProfile['gender'], fallback: _gender),
    );
    if (_genderOptions.contains(profileGender)) {
      _gender = profileGender;
    }

    final profileEducation = _asText(studentProfile['educationLevel']);
    if (_educationOptions.contains(profileEducation)) {
      _educationLevel = profileEducation;
    }

    final profileStream = _asText(studentProfile['stream']);
    if (_streamOptions.contains(profileStream)) {
      _stream = profileStream;
    }

    final language = _asText(
      userProfile['languagePreference'],
      fallback: _asText(preferences['languagePreference']),
    );
    if (_languageOptions.contains(language)) {
      _languagePreference = language;
    }

    final coursesRaw =
        userProfile['selectedCourses'] ?? studentProfile['courses'] ?? const [];
    if (coursesRaw is List) {
      for (final item in coursesRaw) {
        final course = item.toString().trim();
        if (course.isNotEmpty) {
          _selectedCourses.add(course);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _classYearController.dispose();
    _learningGoalsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _profileController.updateUserProfile(
        name: _nameController.text,
        phone: _phoneController.text,
        profileImage: _profileImageUrl,
        dob: _dob?.toIso8601String(),
        gender: _gender,
        city: _cityController.text,
        state: _stateController.text,
        country: _countryController.text,
        educationLevel: _educationLevel,
        classYear: _classYearController.text,
        stream: _stream,
        languagePreference: _languagePreference,
        learningGoals: _learningGoalsController.text,
        selectedCourses: _selectedCourses.toList(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundImage: _avatarProvider(_profileImageUrl),
                          child: _profileImageUrl.isEmpty
                              ? const Icon(Icons.person, size: 44)
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: _isUploadingImage
                                ? null
                                : _pickAndUploadImageFromFiles,
                            child: CircleAvatar(
                              radius: 16,
                              child: _isUploadingImage
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.edit, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Full name is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      if (phone.isEmpty) {
                        return 'Phone is required.';
                      }
                      if (!RegExp(r'^[0-9]{7,15}$').hasMatch(phone)) {
                        return 'Enter a valid phone number.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickDob,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text('Date of Birth: ${_dateLabel(_dob)}'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                    ),
                    items: _genderOptions
                        .map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _gender = value ?? _gender);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'City is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'State is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Country is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _educationLevel,
                    decoration: const InputDecoration(
                      labelText: 'Education Level',
                      border: OutlineInputBorder(),
                    ),
                    items: _educationOptions
                        .map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(
                        () => _educationLevel = value ?? _educationLevel,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _classYearController,
                    decoration: const InputDecoration(
                      labelText: 'Class / Year',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Class / Year is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _stream,
                    decoration: const InputDecoration(
                      labelText: 'Stream / Field',
                      border: OutlineInputBorder(),
                    ),
                    items: _streamOptions
                        .map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _stream = value ?? _stream);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _languagePreference,
                    decoration: const InputDecoration(
                      labelText: 'Language Preference',
                      border: OutlineInputBorder(),
                    ),
                    items: _languageOptions
                        .map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(
                        () =>
                            _languagePreference = value ?? _languagePreference,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _learningGoalsController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Learning Goals',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Learning goals are required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Selected Courses',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableCourses.map((course) {
                      final selected = _selectedCourses.contains(course);
                      return FilterChip(
                        label: Text(course),
                        selected: selected,
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedCourses.add(course);
                            } else {
                              _selectedCourses.remove(course);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
