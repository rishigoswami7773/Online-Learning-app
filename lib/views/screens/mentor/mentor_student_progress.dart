import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/uid_resolver.dart';

void _safeBackToMentorStudents(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.mentorStudents);
  }
}

class MentorStudentProgressScreen extends StatefulWidget {
  final String? initialCourseId;
  const MentorStudentProgressScreen({super.key, this.initialCourseId});

  @override
  State<MentorStudentProgressScreen> createState() =>
      _MentorStudentProgressScreenState();
}

class _MentorStudentProgressScreenState
    extends State<MentorStudentProgressScreen> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  String _filterCourse = 'all';
  List<String> _mentorCourses = [];
  bool _isLoadingCourses = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialCourseId != null && widget.initialCourseId!.isNotEmpty) {
      _filterCourse = widget.initialCourseId!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!UidResolver.isLoggedIn && mounted) {
        context.go(AppRoutes.login);
      } else {
        _loadMentorCourses();
      }
    });
  }

  Future<void> _loadMentorCourses() async {
    try {
      final uid = UidResolver.uid;
      if (uid == null) return;

      final courses = await _fs
          .collection('courses')
          .where('mentorId', isEqualTo: uid)
          .get();

      if (mounted) {
        setState(() {
          _mentorCourses = courses.docs
              .map((d) => '${d.id}|${d['title']}')
              .toList();
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCourses = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading courses: $e')));
      }
    }
  }

  String _getProgressLabel(double progress) {
    final percent = (progress * 100).toInt();
    if (percent == 0) return 'Not Started';
    if (percent < 50) return 'In Progress';
    if (percent < 100) return 'Near Complete';
    return 'Completed';
  }

  Color _getProgressColor(double progress) {
    if (progress == 0) return Colors.grey;
    if (progress < 0.5) return Colors.orange;
    if (progress < 1.0) return Colors.blue;
    return Colors.green;
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
        _safeBackToMentorStudents(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Progress'),
          elevation: 0,
          leading: BackButton(
            onPressed: () => _safeBackToMentorStudents(context),
          ),
        ),
        body: Column(
          children: [
            if (!_isLoadingCourses && _mentorCourses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  initialValue: _filterCourse,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Filter by Course',
                    prefixIcon: const Icon(Icons.filter_list),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Courses'),
                    ),
                    ..._mentorCourses.map((course) {
                      final parts = course.split('|');
                      return DropdownMenuItem(
                        value: parts[0],
                        child: Text(parts[1]),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _filterCourse = val);
                  },
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _filterCourse == 'all'
                    ? _fs
                          .collection('enrollments')
                          .where(
                            'courseId',
                            whereIn: _mentorCourses
                                .map((c) => c.split('|')[0])
                                .toList(),
                          )
                          .snapshots()
                    : _fs
                          .collection('enrollments')
                          .where('courseId', isEqualTo: _filterCourse)
                          .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final enrollments = snapshot.data?.docs ?? [];
                  if (enrollments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No student enrollments yet',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: enrollments.length,
                    itemBuilder: (context, idx) {
                      final enrollment =
                          enrollments[idx].data() as Map<String, dynamic>;
                      final studentId = enrollment['studentId'] as String?;
                      final progress =
                          ((enrollment['progress'] as num?)?.toDouble() ?? 0.0);
                      final completedLessons =
                          (enrollment['completedLessons'] as num?)?.toInt() ??
                          0;
                      final totalLessons =
                          (enrollment['totalLessons'] as num?)?.toInt() ?? 10;
                      final enrolledAt =
                          (enrollment['enrolledAt'] as Timestamp?)?.toDate();

                      return FutureBuilder<DocumentSnapshot>(
                        future: _fs.collection('users').doc(studentId).get(),
                        builder: (context, userSnap) {
                          final studentName =
                              (userSnap.data?.data() as Map?)?['name'] ??
                              'Student';
                          final studentEmail =
                              (userSnap.data?.data() as Map?)?['email'] ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blue.withValues(
                                          alpha: 0.1,
                                        ),
                                        child: Text(
                                          studentName.isNotEmpty
                                              ? studentName[0].toUpperCase()
                                              : 'S',
                                          style: const TextStyle(
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
                                              studentName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              studentEmail,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (enrolledAt != null)
                                              Text(
                                                'Enrolled: ${enrolledAt.day}/${enrolledAt.month}/${enrolledAt.year}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            minHeight: 8,
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  _getProgressColor(progress),
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${(progress * 100).toInt()}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$completedLessons/$totalLessons lessons completed',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getProgressColor(
                                            progress,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          _getProgressLabel(progress),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: _getProgressColor(progress),
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
