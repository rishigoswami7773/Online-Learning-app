import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../models/student/course_model.dart';
import '../../../models/student/enrollment_model.dart';
import '../../../routes/app_routes.dart';
import '../../../services/certificate_service.dart';
import '../../../services/payment_service.dart';
import '../../../utils/theme_helper.dart';

void _safeBackFromCourseDetail(BuildContext context, bool? isEnrolled) {
  if (context.canPop()) {
    context.pop();
  } else if (isEnrolled == true) {
    context.go(AppRoutes.studentMyCourses);
  } else {
    context.go(AppRoutes.studentBrowse);
  }
}

String? _extractYouTubeId(String url) {
  final regExp = RegExp(
    r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})',
  );
  final match = regExp.firstMatch(url);
  return match?.group(1);
}

class StudentCourseDetailPage extends StatelessWidget {
  final Object? extra;

  const StudentCourseDetailPage({super.key, this.extra});

  Future<(LegacyCourseModel, EnrollmentModel?)> _loadCourseWithEnrollment(
    String courseId, {
    String fallbackTitle = 'Unknown Course',
    String fallbackThumbnail = '',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final courseFuture = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .get();

    LegacyCourseModel course;
    EnrollmentModel? enrollment;

    // Load course
    final courseSnap = await courseFuture;
    if (courseSnap.exists) {
      course = LegacyCourseModel.fromFirestore(courseSnap);
    } else {
      course = LegacyCourseModel.fromMap({
        'id': courseId,
        'title': fallbackTitle,
        'category': 'General',
        'instructor': 'Instructor',
        'description': 'Course details are unavailable.',
        'thumbnailUrl': fallbackThumbnail,
        'durationHours': 0,
        'rating': 0,
        'totalLessons': 0,
      }, fallbackId: courseId);
    }

    // Load enrollment if user is logged in
    if (uid != null) {
      try {
        final enrollmentSnap = await FirebaseFirestore.instance
            .collection('enrollments')
            .where('studentId', isEqualTo: uid)
            .where('courseId', isEqualTo: courseId)
            .limit(1)
            .get();

        if (enrollmentSnap.docs.isEmpty) {
          enrollment = null;
        } else {
          enrollment = EnrollmentModel.fromMap(
            enrollmentSnap.docs.first.data(),
          );
        }
      } catch (_) {}
    }

    return (course, enrollment);
  }

  @override
  Widget build(BuildContext context) {
    // Support both GoRouter.extra (passed via state.extra) and legacy
    // Navigator.pushNamed(arguments: ...)
    final routeArguments = ModalRoute.of(context)?.settings.arguments;
    final args = <String, dynamic>{
      if (extra is Map<String, dynamic>) ...extra as Map<String, dynamic>,
      if (routeArguments is Map<String, dynamic>) ...routeArguments,
    };

    final courseId = extra is String
        ? extra as String
        : args['courseId']?.toString() ??
              (routeArguments is String ? routeArguments : null);

    final courseMap = args['course'] as Map<String, dynamic>?;
    final enrollmentMap = args['enrollment'] as Map<String, dynamic>?;

    final enrollment = enrollmentMap == null
        ? null
        : EnrollmentModel.fromMap(enrollmentMap);

    final progress = enrollment?.progress ?? 0.0;

    if (courseMap != null) {
      final course = LegacyCourseModel.fromMap(courseMap);
      return _buildContent(context, course, enrollment, progress);
    }

    if (courseId != null && courseId.isNotEmpty) {
      final fallbackTitle = args['courseTitle']?.toString() ?? 'Unknown Course';
      final fallbackThumbnail = args['courseThumbnail']?.toString() ?? '';

      return FutureBuilder<(LegacyCourseModel, EnrollmentModel?)>(
        future: _loadCourseWithEnrollment(
          courseId,
          fallbackTitle: fallbackTitle,
          fallbackThumbnail: fallbackThumbnail,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(
                leading: BackButton(
                  onPressed: () => _safeBackFromCourseDetail(context, null),
                ),
                title: const Text('Course Detail'),
              ),
              body: const Center(child: Text('Unable to load course details.')),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(
                leading: BackButton(
                  onPressed: () => _safeBackFromCourseDetail(context, null),
                ),
                title: const Text('Course Detail'),
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final (course, loadedEnrollment) =
              snapshot.data ?? (LegacyCourseModel.dummyCourses.first, null);
          return _buildContent(
            context,
            course,
            loadedEnrollment,
            loadedEnrollment?.progress ?? 0.0,
          );
        },
      );
    }

    final course = LegacyCourseModel.dummyCourses.first;
    return _buildContent(context, course, enrollment, progress);
  }

  Widget _buildContent(
    BuildContext context,
    LegacyCourseModel course,
    EnrollmentModel? enrollment,
    double progress,
  ) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _safeBackFromCourseDetail(context, enrollment != null);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () =>
                _safeBackFromCourseDetail(context, enrollment != null),
          ),
          title: const Text('Course Detail'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BannerImage(url: course.thumbnailUrl),
              const SizedBox(height: 16),
              Text(
                course.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(course.category)),
                  Chip(label: Text('${course.durationHours} hours')),
                  Chip(label: Text('${course.totalLessons} lessons')),
                  Chip(label: Text('⭐ ${course.rating.toStringAsFixed(1)}')),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Instructor: ${course.instructor}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                course.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              // YouTube Video Preview Section
              _buildVideoPreviewSection(course),
              const SizedBox(height: 20),
              // Course Video Lectures List
              _VideoLecturesList(courseId: course.id),
              const SizedBox(height: 20),
              if (enrollment != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Progress',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 8),
                        Text(
                          '${enrollment.progressPercent}% completed • ${enrollment.completedLessons}/${enrollment.totalLessons} lessons',
                        ),
                      ],
                    ),
                  ),
                ),
              if (enrollment != null && enrollment.isCompleted) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => CertificateService.generateAndDownload(
                      context: context,
                      courseTitle: course.title,
                      courseCategory: course.category,
                    ),
                    icon: const Icon(Icons.workspace_premium),
                    label: const Text('Download Certificate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0E7C86),
                      side: const BorderSide(color: Color(0xFF0E7C86)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FutureBuilder<(double, bool)>(
                future: _getPriceAndPurchaseStatus(context, course.id),
                builder: (context, priceSnapshot) {
                  if (!priceSnapshot.hasData) {
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0E7C86), Color(0xFF17A2B8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final (coursePrice, isPurchased) = priceSnapshot.data!;

                  // If enrolled and purchased, show continue learning
                  if (enrollment != null) {
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _handleContinueLearning(context, course),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('▶  Continue Learning'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0E7C86),
                          side: const BorderSide(
                            color: Color(0xFF0E7C86),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    );
                  }

                  // If course is paid and not purchased, show buy button
                  if (coursePrice > 0 && !isPurchased) {
                    return GestureDetector(
                      onTap: () => _handleBuyNow(context, course, coursePrice),
                      child: Container(
                        height: 52,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0E7C86), Color(0xFF17A2B8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0E7C86,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Buy Now  ₹${coursePrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // Free course - show enroll button
                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _handleFreeEnroll(context, course),
                      icon: const Icon(Icons.school),
                      label: const Text('Enroll'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _ReviewSection(courseId: course.id),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreviewSection(LegacyCourseModel course) {
    final videoUrl = course.videoUrl;

    if (videoUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final videoId = _extractYouTubeId(videoUrl);
    if (videoId == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview Video',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: YoutubePlayer(
                controller: YoutubePlayerController(
                  initialVideoId: videoId,
                  flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
                ),
                showVideoProgressIndicator: true,
                progressColors: const ProgressBarColors(
                  playedColor: Color(0xFF0E7C86),
                  handleColor: Color(0xFF0E7C86),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<(double, bool)> _getPriceAndPurchaseStatus(
    BuildContext context,
    String courseId,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final courseDoc = await FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .get();
    final coursePrice = (courseDoc.data()?['price'] as num?)?.toDouble() ?? 0.0;

    if (uid == null || coursePrice == 0) {
      return (coursePrice, false);
    }

    final isPurchased = await PaymentService.isCoursePurchased(uid, courseId);
    return (coursePrice, isPurchased);
  }

  Future<void> _handleBuyNow(
    BuildContext context,
    LegacyCourseModel course,
    double coursePrice,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      context.go(AppRoutes.login);
      return;
    }

    // Get course details for checkout
    final courseDoc = await FirebaseFirestore.instance
        .collection('courses')
        .doc(course.id)
        .get();
    final mentorName =
        (courseDoc.data()?['instructor'] as String?) ?? course.instructor;
    final thumbnailUrl = courseDoc.data()?['thumbnailUrl'] as String?;

    if (!context.mounted) return;
    context.push(
      AppRoutes.checkout,
      extra: {
        'courseId': course.id,
        'courseName': course.title,
        'price': coursePrice,
        'mentorName': mentorName,
        'thumbnailUrl': thumbnailUrl,
      },
    );
  }

  Future<void> _handleFreeEnroll(
    BuildContext context,
    LegacyCourseModel course,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final messenger = ScaffoldMessenger.of(context);

    if (uid == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please log in to enroll.')),
      );
      return;
    }

    try {
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(course.id)
          .get();
      final mentorId = (courseDoc.data()?['mentorId'] as String?) ?? '';

      await FirebaseFirestore.instance.collection('enrollments').add({
        'studentId': uid,
        'courseId': course.id,
        'courseTitle': course.title,
        'courseCategory': course.category,
        'courseThumbnail': course.thumbnailUrl,
        'mentorId': mentorId,
        'progressPercent': 0,
        'lessonsCompleted': 0,
        'totalLessons': course.totalLessons,
        'status': 'active',
        'enrolledAt': FieldValue.serverTimestamp(),
        'lastAccessedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('courses')
          .doc(course.id)
          .update({'enrollmentCount': FieldValue.increment(1)});

      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Enrolled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Enrollment failed: $e')));
    }
  }

  Future<void> _handleContinueLearning(
    BuildContext context,
    LegacyCourseModel course,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final videos = await _fetchAllCourseVideos(course.id);
      final videoUrl = videos.isNotEmpty
          ? (videos.first['videoUrl'] as String? ?? '')
          : '';
      final title = videos.isNotEmpty
          ? (videos.first['title'] as String? ?? course.title)
          : course.title;

      if (videoUrl.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No video available for this course.')),
        );
        return;
      }

      if (!context.mounted) return;
      context.push(
        AppRoutes.studentVideo,
        extra: {
          'videoUrl': videoUrl,
          'title': title,
          'courseId': course.id,
        },
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error loading video: $e')),
      );
    }
  }
}

/// Extracts YouTube video ID from a URL and returns the hqdefault thumbnail URL.
String? _youtubeThumbnail(String? videoUrl) {
  if (videoUrl == null || videoUrl.isEmpty) return null;
  final id = _extractYouTubeId(videoUrl);
  if (id == null) return null;
  return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}

/// Fetches all video lectures for a course from all possible storage locations:
/// 1. courses/{id}/videos subcollection (videoURL / videoUrl field)
/// 2. top-level lessons collection (contentUrl field, type == 'video')
/// 3. videoUrl / videoURL / contentUrl field on the courses doc itself
Future<List<Map<String, dynamic>>> _fetchAllCourseVideos(
  String courseId,
) async {
  // Source 1: courses/{courseId}/videos subcollection
  try {
    final snap = await FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('videos')
        .orderBy('orderIndex')
        .get();
    if (snap.docs.isNotEmpty) {
      return snap.docs.map((doc) {
        final d = doc.data();
        return {
          'title': (d['title'] ?? 'Untitled').toString(),
          'videoUrl': (d['videoURL'] ?? d['videoUrl'] ?? '').toString(),
          'orderIndex': (d['orderIndex'] as num?)?.toInt() ?? 0,
        };
      }).toList();
    }
  } catch (_) {}

  // Source 2: top-level lessons collection with courseId
  try {
    final snap = await FirebaseFirestore.instance
        .collection('lessons')
        .where('courseId', isEqualTo: courseId)
        .get();
    final videos = snap.docs
        .map((doc) {
          final d = doc.data();
          return d;
        })
        .where((d) => (d['type'] ?? 'video').toString() == 'video')
        .toList();
    if (videos.isNotEmpty) {
      videos.sort(
        (a, b) =>
            ((a['order'] as num?)?.toInt() ?? 0).compareTo(
              (b['order'] as num?)?.toInt() ?? 0,
            ),
      );
      return videos
          .map(
            (d) => {
              'title': (d['title'] ?? 'Untitled').toString(),
              'videoUrl':
                  (d['contentUrl'] ?? d['videoUrl'] ?? d['videoURL'] ?? '')
                      .toString(),
              'orderIndex': (d['order'] as num?)?.toInt() ?? 0,
            },
          )
          .toList();
    }
  } catch (_) {}

  // Source 3: videoUrl / videoURL / contentUrl field on the course document
  try {
    final courseSnap = await FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .get();
    final d = courseSnap.data() ?? {};
    final url =
        (d['videoUrl'] ?? d['videoURL'] ?? d['contentUrl'] ?? '').toString();
    if (url.isNotEmpty) {
      return [
        {
          'title': (d['title'] ?? 'Course Video').toString(),
          'videoUrl': url,
          'orderIndex': 0,
        },
      ];
    }
  } catch (_) {}

  return [];
}

/// Shows the list of video lectures for a course, checking all storage locations.
class _VideoLecturesList extends StatelessWidget {
  const _VideoLecturesList({required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllCourseVideos(courseId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        final videos = snap.data ?? [];
        if (videos.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Course Content',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...videos.map((data) {
              final title = data['title'] as String;
              final videoUrl = data['videoUrl'] as String;
              final thumbUrl = _youtubeThumbnail(videoUrl);
              final index = data['orderIndex'] as int;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: context.borderColor),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: videoUrl.isEmpty
                      ? null
                      : () async {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          final messenger = ScaffoldMessenger.of(context);
                          if (uid == null) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please log in to enroll and view videos.',
                                ),
                              ),
                            );
                            context.go(AppRoutes.login);
                            return;
                          }

                          // Check enrollment
                          try {
                            final enrollSnap = await FirebaseFirestore.instance
                                .collection('enrollments')
                                .where('studentId', isEqualTo: uid)
                                .where('courseId', isEqualTo: courseId)
                                .limit(1)
                                .get();

                            if (!context.mounted) return;

                            final enrolled = enrollSnap.docs.isNotEmpty;
                            if (enrolled) {
                              context.push(
                                AppRoutes.studentVideo,
                                extra: {
                                  'videoUrl': videoUrl,
                                  'title': title,
                                  'courseId': courseId,
                                },
                              );
                              return;
                            }

                            // Not enrolled: check course price
                            final courseDoc = await FirebaseFirestore.instance
                                .collection('courses')
                                .doc(courseId)
                                .get();
                            if (!context.mounted) return;
                            final price =
                                (courseDoc.data()?['price'] as num?)
                                    ?.toDouble() ??
                                0.0;

                            if (price > 0) {
                              // Paid course -> must purchase
                              final purchased =
                                  await PaymentService.isCoursePurchased(
                                    uid,
                                    courseId,
                                  );
                              if (!context.mounted) return;
                              if (purchased) {
                                context.push(
                                  AppRoutes.studentVideo,
                                  extra: {
                                    'videoUrl': videoUrl,
                                    'title': title,
                                    'courseId': courseId,
                                  },
                                );
                                return;
                              }

                              // Prompt to buy
                              showDialog<void>(
                                context: context,
                                builder: (dctx) => AlertDialog(
                                  title: const Text('Purchase required'),
                                  content: const Text(
                                    'This course requires purchase to view full videos.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dctx).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.of(dctx).pop();
                                        context.push(
                                          AppRoutes.checkout,
                                          extra: {
                                            'courseId': courseId,
                                            'courseName':
                                                courseDoc.data()?['title'] ??
                                                '',
                                            'price': price,
                                          },
                                        );
                                      },
                                      child: const Text('Buy'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            // Free course -> enroll automatically then open video
                            await FirebaseFirestore.instance
                                .collection('enrollments')
                                .add({
                                  'studentId': uid,
                                  'courseId': courseId,
                                  'courseTitle':
                                      courseDoc.data()?['title'] ?? '',
                                  'courseCategory':
                                      courseDoc.data()?['category'] ?? '',
                                  'courseThumbnail':
                                      courseDoc.data()?['thumbnailUrl'] ?? '',
                                  'mentorId':
                                      courseDoc.data()?['mentorId'] ?? '',
                                  'progressPercent': 0,
                                  'lessonsCompleted': 0,
                                  'totalLessons':
                                      (courseDoc.data()?['totalLessons']
                                              as num?)
                                          ?.toInt() ??
                                      0,
                                  'status': 'active',
                                  'enrolledAt': FieldValue.serverTimestamp(),
                                  'lastAccessedAt':
                                      FieldValue.serverTimestamp(),
                                });

                            await FirebaseFirestore.instance
                                .collection('courses')
                                .doc(courseId)
                                .update({
                                  'enrollmentCount': FieldValue.increment(1),
                                });

                            if (!context.mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Enrolled successfully'),
                              ),
                            );
                            context.push(
                              AppRoutes.studentVideo,
                              extra: {
                                'videoUrl': videoUrl,
                                'title': title,
                                'courseId': courseId,
                              },
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 90,
                            height: 60,
                            child: thumbUrl != null
                                ? Image.network(
                                    thumbUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        _VideoThumbPlaceholder(index: index),
                                  )
                                : _VideoThumbPlaceholder(index: index),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lecture ${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF0E7C86),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          videoUrl.isEmpty
                              ? Icons.lock_outline_rounded
                              : Icons.play_circle_outline_rounded,
                          color: videoUrl.isEmpty
                              ? Colors.grey
                              : const Color(0xFF0E7C86),
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _VideoThumbPlaceholder extends StatelessWidget {
  const _VideoThumbPlaceholder({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E7C86).withValues(alpha: 0.12),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0E7C86),
          ),
        ),
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Icon(Icons.menu_book, size: 52)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: 180,
          color: Colors.grey.shade300,
          child: const Center(child: Icon(Icons.image_not_supported)),
        ),
      ),
    );
  }
}

class _ReviewSection extends StatefulWidget {
  const _ReviewSection({required this.courseId});
  final String courseId;
  @override
  State<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<_ReviewSection> {
  int _selectedRating = 0;
  late TextEditingController _reviewController;
  String? _existingReviewId;
  bool _hasReviewed = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController();
    _loadExistingReview();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingReview() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('course_reviews')
          .where('studentId', isEqualTo: uid)
          .where('courseId', isEqualTo: widget.courseId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        if (mounted) {
          setState(() {
            _selectedRating = (data['rating'] as num?)?.toInt() ?? 0;
            _reviewController.text = (data['reviewText'] as String?) ?? '';
            _existingReviewId = snap.docs.first.id;
            _hasReviewed = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading review: $e');
    }
  }

  Future<void> _submitReview() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a review.')),
      );
      return;
    }

    if (_selectedRating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final wasExistingReview = _existingReviewId != null;
      if (_existingReviewId != null) {
        // Update existing review
        await FirebaseFirestore.instance
            .collection('course_reviews')
            .doc(_existingReviewId)
            .update({
              'rating': _selectedRating,
              'reviewText': _reviewController.text,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } else {
        // Add new review
        final docRef = await FirebaseFirestore.instance
            .collection('course_reviews')
            .add({
              'studentId': uid,
              'courseId': widget.courseId,
              'rating': _selectedRating,
              'reviewText': _reviewController.text,
              'createdAt': FieldValue.serverTimestamp(),
            });
        if (mounted) {
          setState(() => _existingReviewId = docRef.id);
        }
      }

      if (mounted) {
        // The review form stayed editable before the local review state flipped.
        setState(() => _hasReviewed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasExistingReview ? 'Review updated!' : 'Review submitted!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit review: $e')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildSubmittedReviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Review',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _hasReviewed = false);
                  },
                  child: const Text('Edit Review'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                final rating = index + 1;
                return Icon(
                  rating <= _selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 24,
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              _reviewController.text.trim().isEmpty
                  ? 'No review text provided.'
                  : _reviewController.text.trim(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasReviewed) ...[
          _buildSubmittedReviewCard(),
        ] else ...[
          // Review form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate & Review',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (index) {
                      final rating = index + 1;
                      return IconButton(
                        onPressed: () =>
                            setState(() => _selectedRating = rating),
                        icon: Icon(
                          _selectedRating >= rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reviewController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts about this course...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _existingReviewId == null
                                  ? 'Submit Review'
                                  : 'Update Review',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text('Course Reviews', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        // Reviews list
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('course_reviews')
              .where('courseId', isEqualTo: widget.courseId)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final docs = snapshot.data?.docs.toList() ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No reviews yet. Be the first!'),
                ),
              );
            }

            // Sort client-side by createdAt in descending order (no index needed)
            docs.sort((a, b) {
              final aTs = a.data()['createdAt'] as Timestamp?;
              final bTs = b.data()['createdAt'] as Timestamp?;
              if (aTs == null || bTs == null) return 0;
              return bTs.compareTo(aTs);
            });

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final reviewData = docs[index].data();
                final rating = (reviewData['rating'] as num?)?.toInt() ?? 0;
                final reviewText = (reviewData['reviewText'] as String?) ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            );
                          }),
                        ),
                        if (reviewText.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(reviewText),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
