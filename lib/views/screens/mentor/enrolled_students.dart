import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../utils/uid_resolver.dart';

const Color _mentorTeal = Color(0xFF0E7C86);

class EnrolledStudentsPage extends StatefulWidget {
  final VoidCallback? onBack;

  const EnrolledStudentsPage({super.key, this.onBack});

  @override
  State<EnrolledStudentsPage> createState() => _EnrolledStudentsPageState();
}

class _EnrolledStudentsPageState extends State<EnrolledStudentsPage> {
  Map<String, String> _courseTitles = {};
  bool _coursesFetched = false;
  String? _courseError;
  int _reloadToken = 0;
  String? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = UidResolver.uid;
      if (uid == null && mounted) {
        context.go(AppRoutes.login);
        return;
      }
      _fetchCourseTitles(uid!);
    });
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }

    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(AppRoutes.mentorDashboard);
  }

  Future<void> _fetchCourseTitles(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('courses')
          .where('mentorId', isEqualTo: uid)
          .get();
      if (!mounted) return;
      setState(() {
        _courseTitles = {
          for (final doc in snap.docs)
            doc.id: (doc.data()['title'] as String?)?.trim().isNotEmpty == true
                ? (doc.data()['title'] as String).trim()
                : 'Untitled course',
        };
        _coursesFetched = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _courseError = e.toString();
        _coursesFetched = true;
      });
    }
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  Widget _emptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: _mentorTeal.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No students enrolled yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Once students enroll in your courses, they will appear here',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentsStream() {
    final courseIds = _courseTitles.keys.toList();
    // Process all courses in chunks of 30 for Firestore whereIn limits.

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('enrollments').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load students: ${snapshot.error}'),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((doc) {
          final courseId = (doc.data()['courseId'] as String?) ?? '';
          return courseIds.contains(courseId);
        }).toList();
        if (docs.isEmpty) return _emptyWidget();

        final grouped = <String, List<_StudentEnrollmentRow>>{};
        for (final doc in docs) {
          final data = doc.data();
          final courseId = (data['courseId'] as String?) ?? '';
          final courseTitle =
              _courseTitles[courseId] ??
              (data['courseTitle'] as String?) ??
              'Untitled course';
          final studentId = (data['studentId'] as String?) ?? '';
          final studentName =
              data['studentName']?.toString() ??
              data['name']?.toString() ??
              'Student';

          // BUG 5 FIX: Normalize progress field (0-100 int OR 0-1 float)
          double raw =
              (data['progress'] as num?)?.toDouble() ??
              (data['progressPercent'] as num?)?.toDouble() ??
              0.0;
          // If stored as 0-100 (e.g., 45) convert to fraction 0.0-1.0; if already 0.0-1.0 keep as-is
          double progressFraction = raw > 1.0 ? (raw / 100.0) : raw;
          double progressPercent = (progressFraction * 100.0);

          final enrolledAt = (data['enrolledAt'] as Timestamp?)?.toDate();
          final completedLessons =
              ((data["completedLessons"] is List
                      ? data["completedLessons"] as List
                      : null))
                  ?.map((lessonId) => lessonId.toString())
                  .toList() ??
              const <String>[];

          grouped.putIfAbsent(courseTitle, () => []);
          grouped[courseTitle]!.add(
            _StudentEnrollmentRow(
              courseId: courseId,
              studentId: studentId,
              studentName: studentName,
              courseTitle: courseTitle,
              progressFraction: progressFraction,
              progressPercent: progressPercent,
              enrolledAt: enrolledAt,
              completedLessons: completedLessons,
            ),
          );
        }

        for (final entry in grouped.entries) {
          entry.value.sort((a, b) {
            final aDate =
                a.enrolledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                b.enrolledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
        }
        // Apply course filter if selected
        final sortedCourses =
            grouped.keys
                .where(
                  (title) => _selectedCourseId == null
                      ? true
                      : grouped[title]?.any(
                              (r) => r.courseId == _selectedCourseId,
                            ) ==
                            true,
                )
                .toList()
              ..sort();
        final totalStudents = grouped.values.fold<int>(
          0,
          (p, e) => p + e.length,
        );
        // Build a list with filter chips, summary banner, and course sections
        final children = <Widget>[];

        // Filter chips
        children.add(
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('All Courses'),
                  selected: _selectedCourseId == null,
                  selectedColor: _mentorTeal,
                  labelStyle: TextStyle(
                    color: _selectedCourseId == null
                        ? Colors.white
                        : _mentorTeal,
                  ),
                  onSelected: (_) => setState(() => _selectedCourseId = null),
                ),
                const SizedBox(width: 8),
                ..._courseTitles.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.value, overflow: TextOverflow.ellipsis),
                      selected: _selectedCourseId == e.key,
                      selectedColor: _mentorTeal,
                      labelStyle: TextStyle(
                        color: _selectedCourseId == e.key
                            ? Colors.white
                            : _mentorTeal,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedCourseId = e.key),
                    ),
                  );
                }),
              ],
            ),
          ),
        );

        // Summary banner
        children.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_mentorTeal, Color(0xFF17A2B8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '👥 $totalStudents total students',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${grouped.keys.length} courses',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.people_rounded, color: Colors.white, size: 36),
              ],
            ),
          ),
        );

        // Course sections
        for (final courseTitle in sortedCourses) {
          final rows = grouped[courseTitle] ?? [];
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _mentorTeal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: _mentorTeal,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              courseTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${rows.length} student${rows.length == 1 ? '' : 's'}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...rows.map((row) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              _mentorTeal,
                                              Color(0xFF17A2B8),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _initials(row.studentName),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _StudentNameText(
                                              studentId: row.studentId,
                                              fallback: row.studentName,
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _mentorTeal,
                                                ),
                                              ),
                                              child: Text(
                                                courseTitle,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: _mentorTeal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${row.progressPercent.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: _mentorTeal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: row.progressFraction,
                                      minHeight: 6,
                                      backgroundColor: Colors.grey.shade200,
                                      color: _mentorTeal,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Enrolled: ${_formatDate(row.enrolledAt ?? DateTime.now())}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: children,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!UidResolver.isLoggedIn) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'My Students',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _mentorTeal,
                fontSize: 16,
              ),
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('enrollments')
                  .snapshots(),
              builder: (context, snap) {
                final allDocs = snap.data?.docs ?? [];
                final courseIds = _courseTitles.keys.toList();
                final count = allDocs
                    .where(
                      (doc) => courseIds.contains(
                        (doc.data()['courseId'] as String?) ?? '',
                      ),
                    )
                    .length;
                return Text(
                  '$count student${count == 1 ? '' : 's'} enrolled',
                  style: TextStyle(
                    fontSize: 12,
                    color: _mentorTeal.withAlpha(180),
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _mentorTeal),
          onPressed: _handleBack,
        ),
      ),
      body: !_coursesFetched
          ? const Center(child: CircularProgressIndicator())
          : _courseError != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text('Unable to load students: $_courseError'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(() => _reloadToken++),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _courseTitles.isEmpty
          ? _emptyWidget()
          : _buildEnrollmentsStream(),
    );
  }
}

class _StudentEnrollmentRow {
  const _StudentEnrollmentRow({
    required this.courseId,
    required this.studentId,
    required this.studentName,
    required this.courseTitle,
    required this.progressFraction,
    required this.progressPercent,
    required this.enrolledAt,
    this.completedLessons = const [],
  });

  final String courseId;
  final String studentId;
  final String studentName;
  final String courseTitle;
  // progressFraction: 0.0 - 1.0
  final double progressFraction;
  // progressPercent: 0 - 100
  final double progressPercent;
  final DateTime? enrolledAt;
  final List<String> completedLessons;
}

class _StudentNameText extends StatelessWidget {
  const _StudentNameText({required this.studentId, required this.fallback});
  final String studentId;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    if (studentId.isEmpty) {
      return Text(
        fallback,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      );
    }
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .get(),
      builder: (context, snap) {
        final name = snap.data?.data()?['name']?.toString();
        return Text(
          (name != null && name.isNotEmpty) ? name : fallback,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        );
      },
    );
  }
}
