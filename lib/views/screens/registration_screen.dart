import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../controllers/auth_controller.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _authController = AuthController();
  final List<GlobalKey<FormState>> _stepKeys =
      List<GlobalKey<FormState>>.generate(6, (_) => GlobalKey<FormState>());

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();

  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');

  final _classController = TextEditingController();
  final _learningGoalController = TextEditingController();

  final _referralController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentRelationshipController = TextEditingController();
  final _parentContactController = TextEditingController();

  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isOtpVerified = false;

  DateTime? _dateOfBirth;
  DateTime? _preferredStartDate;
  String _gender = 'Prefer not to say';
  String _educationLevel = 'School';
  String _stream = 'Science';
  String _preferredTimeSlot = 'Morning';
  String _languagePreference = 'English';

  String? _profilePhotoPath;
  String? _documentPath;
  bool _hasGuardianDetails = false;

  bool _acceptTerms = false;
  bool _acceptPrivacy = false;

  final List<String> _availableCourses = const [
    'Flutter App Development',
    'Python for Beginners',
    'Digital Marketing Basics',
    'Business Communication',
    'Data Analytics Foundations',
    'Commerce Career Prep',
  ];

  final Set<String> _selectedCourses = <String>{};

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _classController.dispose();
    _learningGoalController.dispose();
    _referralController.dispose();
    _parentNameController.dispose();
    _parentRelationshipController.dispose();
    _parentContactController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDob}) async {
    final initialDate = isDob
        ? (_dateOfBirth ?? DateTime(2008, 1, 1))
        : (_preferredStartDate ?? DateTime.now().add(const Duration(days: 7)));
    final firstDate = isDob ? DateTime(1950) : DateTime.now();
    final lastDate = isDob
        ? DateTime.now()
        : DateTime.now().add(const Duration(days: 730));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isDob) {
        _dateOfBirth = picked;
      } else {
        _preferredStartDate = picked;
      }
    });
  }

  Future<void> _pickFile({required bool isImage}) async {
    final result = await FilePicker.platform.pickFiles(
      type: isImage ? FileType.image : FileType.custom,
      allowedExtensions: isImage
          ? null
          : <String>['pdf', 'doc', 'docx', 'png', 'jpg'],
      withData: false,
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    setState(() {
      if (isImage) {
        _profilePhotoPath = result.files.single.path;
      } else {
        _documentPath = result.files.single.path;
      }
    });
  }

  String _dateLabel(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  bool _validateStep(int step) {
    if (step <= 5) {
      final formState = _stepKeys[step].currentState;
      if (formState != null && !formState.validate()) {
        return false;
      }
    }

    if (step == 1 && _dateOfBirth == null) {
      _showError('Please select Date of Birth.');
      return false;
    }
    if (step == 0 && !_isOtpVerified) {
      _showError('Please send and verify OTP to continue.');
      return false;
    }
    if (step == 4 && _selectedCourses.isEmpty) {
      _showError('Please select at least one course.');
      return false;
    }
    if (step == 4 && _preferredStartDate == null) {
      _showError('Please select preferred start date.');
      return false;
    }
    if (step == 6 && (!_acceptTerms || !_acceptPrivacy)) {
      _showError('Accept Terms and Privacy Policy to continue.');
      return false;
    }

    return true;
  }

  Future<void> _submitRegistration() async {
    if (_isSubmitting) {
      return;
    }

    if (!_isOtpVerified) {
      _showError('Please verify OTP before submitting registration.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _authController
          .registerStudent({
            'name': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
            'phone': _mobileController.text.trim(),
            'dob': _dateOfBirth?.toIso8601String(),
            'gender': _gender,
            'educationLevel': _educationLevel,
            'classYear': _classController.text.trim(),
            'stream': _stream,
            'courses': _selectedCourses.toList(),
            'preferences': {
              'preferredStartDate': _preferredStartDate?.toIso8601String(),
              'preferredTimeSlot': _preferredTimeSlot,
              'languagePreference': _languagePreference,
              'learningGoal': _learningGoalController.text.trim(),
              'location': {
                'city': _cityController.text.trim(),
                'state': _stateController.text.trim(),
                'country': _countryController.text.trim(),
              },
            },
            'referralCode': _referralController.text.trim(),
            'profilePhotoPath': _profilePhotoPath ?? '',
          })
          .timeout(const Duration(seconds: 25));

      if (!result.success) {
        _showError(result.message ?? 'Registration failed.');
        return;
      }

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        result.nextRoute ?? AppRoutes.studentDashboard,
        (route) => false,
      );
    } on TimeoutException {
      _showError(
        'Registration timed out. Check internet/Firebase and try again.',
      );
    } catch (error) {
      _showError('Error: $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _sendOtp() async {
    if ((_emailController.text.trim().isEmpty) ||
        (_mobileController.text.trim().isEmpty)) {
      _showError('Enter email and mobile number before sending OTP.');
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _isOtpVerified = false;
    });

    try {
      final result = await _authController
          .sendOtp(email: _emailController.text, phone: _mobileController.text)
          .timeout(const Duration(seconds: 15));

      if (!result.success) {
        _showError(result.message ?? 'Failed to send OTP');
        return;
      }

      final displayMessage = result.debugOtp == null
          ? (result.message ?? 'OTP sent')
          : '${result.message} (Dev OTP: ${result.debugOtp})';

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(displayMessage)));
    } on TimeoutException {
      _showError(
        'OTP request timed out. Check internet or Firestore setup and try again.',
      );
    } on FirebaseException catch (e) {
      _showError(
        'OTP failed: ${e.message ?? e.code}. Check Firebase rules/config.',
      );
    } catch (e) {
      _showError('Unable to send OTP: $e');
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      _showError('Enter OTP first.');
      return;
    }

    setState(() => _isVerifyingOtp = true);

    try {
      final result = await _authController.verifyOTP(
        email: _emailController.text,
        otp: _otpController.text,
      );

      if (!result.success) {
        _showError(result.message ?? 'OTP verification failed');
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() => _isOtpVerified = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message ?? 'OTP verified')));
    } catch (e) {
      _showError('Unable to verify OTP: $e');
    } finally {
      if (mounted) {
        setState(() => _isVerifyingOtp = false);
      }
    }
  }

  Future<void> _handleContinue() async {
    if (!_validateStep(_currentStep)) {
      return;
    }

    if (_currentStep < 6) {
      setState(() {
        _currentStep += 1;
      });
      return;
    }

    await _submitRegistration();
  }

  void _handleBack() {
    if (_currentStep == 0) {
      return;
    }

    setState(() {
      _currentStep -= 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Registration')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Stepper(
            currentStep: _currentStep,
            type: StepperType.vertical,
            onStepTapped: (index) {
              if (index <= _currentStep) {
                setState(() {
                  _currentStep = index;
                });
              }
            },
            controlsBuilder: (context, details) {
              return Row(
                children: [
                  FilledButton(
                    onPressed: _isSubmitting ? null : _handleContinue,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentStep == 6 ? 'Submit' : 'Continue'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isSubmitting ? null : _handleBack,
                    child: const Text('Back'),
                  ),
                ],
              );
            },
            steps: [
              Step(
                title: const Text('Basic Details'),
                isActive: _currentStep >= 0,
                content: Form(
                  key: _stepKeys[0],
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Full name is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                        ),
                        validator: (value) {
                          final mobile = value?.trim() ?? '';
                          if (mobile.isEmpty) {
                            return 'Mobile number is required';
                          }
                          if (!RegExp(r'^[0-9]{10,15}$').hasMatch(mobile)) {
                            return 'Enter a valid mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'OTP',
                              ),
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return 'OTP is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _isSendingOtp ? null : _sendOtp,
                            child: _isSendingOtp
                                ? const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Send OTP'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: _isVerifyingOtp ? null : _verifyOtp,
                            child: _isVerifyingOtp
                                ? const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Verify'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Icon(
                              _isOtpVerified
                                  ? Icons.verified_rounded
                                  : Icons.error_outline,
                              size: 16,
                              color: _isOtpVerified
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isOtpVerified
                                  ? 'OTP verified'
                                  : 'OTP verification pending',
                              style: TextStyle(
                                color: _isOtpVerified
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Step(
                title: const Text('Personal Details'),
                isActive: _currentStep >= 1,
                content: Form(
                  key: _stepKeys[1],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickDate(isDob: true),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          'Date of Birth: ${_dateLabel(_dateOfBirth)}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                          DropdownMenuItem(
                            value: 'Prefer not to say',
                            child: Text('Prefer not to say'),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _gender = value ?? 'Prefer not to say';
                        }),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _pickFile(isImage: true),
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          _profilePhotoPath == null
                              ? 'Upload Profile Photo (optional)'
                              : 'Profile Photo Selected',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Step(
                title: const Text('Location Details'),
                isActive: _currentStep >= 2,
                content: Form(
                  key: _stepKeys[2],
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'City'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'City is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(labelText: 'State'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'State is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(labelText: 'Country'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Country is required'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              Step(
                title: const Text('Academic Details'),
                isActive: _currentStep >= 3,
                content: Form(
                  key: _stepKeys[3],
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _educationLevel,
                        decoration: const InputDecoration(
                          labelText: 'Education Level',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'School',
                            child: Text('School'),
                          ),
                          DropdownMenuItem(
                            value: 'College',
                            child: Text('College'),
                          ),
                          DropdownMenuItem(
                            value: 'Professional',
                            child: Text('Professional'),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _educationLevel = value ?? 'School';
                        }),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _classController,
                        decoration: const InputDecoration(
                          labelText: 'Class / Grade / Year',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Class / Grade / Year is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _stream,
                        decoration: const InputDecoration(
                          labelText: 'Stream / Field',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Science',
                            child: Text('Science'),
                          ),
                          DropdownMenuItem(
                            value: 'Commerce',
                            child: Text('Commerce'),
                          ),
                          DropdownMenuItem(value: 'Arts', child: Text('Arts')),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _stream = value ?? 'Science';
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              Step(
                title: const Text('Course & Preferences'),
                isActive: _currentStep >= 4,
                content: Form(
                  key: _stepKeys[4],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course Selection',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
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
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _pickDate(isDob: false),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          'Preferred Start Date: ${_dateLabel(_preferredStartDate)}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _preferredTimeSlot,
                        decoration: const InputDecoration(
                          labelText: 'Preferred Time Slot',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Morning',
                            child: Text('Morning'),
                          ),
                          DropdownMenuItem(
                            value: 'Afternoon',
                            child: Text('Afternoon'),
                          ),
                          DropdownMenuItem(
                            value: 'Evening',
                            child: Text('Evening'),
                          ),
                          DropdownMenuItem(
                            value: 'Night',
                            child: Text('Night'),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _preferredTimeSlot = value ?? 'Morning';
                        }),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _languagePreference,
                        decoration: const InputDecoration(
                          labelText: 'Language Preference',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'English',
                            child: Text('English'),
                          ),
                          DropdownMenuItem(
                            value: 'Hindi',
                            child: Text('Hindi'),
                          ),
                          DropdownMenuItem(
                            value: 'Gujarati',
                            child: Text('Gujarati'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _languagePreference = value ?? 'English';
                        }),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _learningGoalController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Learning Goal',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Please enter your learning goal'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              Step(
                title: const Text('Optional Details'),
                isActive: _currentStep >= 5,
                content: Form(
                  key: _stepKeys[5],
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _referralController,
                        decoration: const InputDecoration(
                          labelText: 'Referral Code',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _hasGuardianDetails,
                        title: const Text('Add Parent/Guardian Details'),
                        onChanged: (value) => setState(() {
                          _hasGuardianDetails = value;
                        }),
                      ),
                      if (_hasGuardianDetails) ...[
                        TextFormField(
                          controller: _parentNameController,
                          decoration: const InputDecoration(
                            labelText: 'Parent/Guardian Name',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _parentRelationshipController,
                          decoration: const InputDecoration(
                            labelText: 'Relationship',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _parentContactController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact Number',
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _pickFile(isImage: false),
                        icon: const Icon(Icons.file_upload_outlined),
                        label: Text(
                          _documentPath == null
                              ? 'Upload Documents (optional)'
                              : 'Document Selected',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Step(
                title: const Text('Agreements'),
                isActive: _currentStep >= 6,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('I accept Terms & Conditions'),
                      value: _acceptTerms,
                      onChanged: (value) => setState(() {
                        _acceptTerms = value ?? false;
                      }),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('I accept Privacy Policy'),
                      value: _acceptPrivacy,
                      onChanged: (value) => setState(() {
                        _acceptPrivacy = value ?? false;
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please review your details before submitting.',
                      style: Theme.of(context).textTheme.bodySmall,
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
