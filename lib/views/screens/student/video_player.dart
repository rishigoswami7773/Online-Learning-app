// PASTE THIS INTO pubspec.yaml under dependencies FIRST, then run: flutter pub get
//   video_player: ^2.8.3
//   chewie: ^1.7.4
//   youtube_player_flutter: ^9.1.1

import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import '../../../services/payment_service.dart';

String? extractYoutubeId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  if (uri.host.contains('youtu.be')) {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  }
  if (uri.host.contains('youtube.com')) {
    return uri.queryParameters['v'];
  }
  return null;
}

bool isYoutubeUrl(String url) => extractYoutubeId(url) != null;

class CourseVideoPlayerPage extends StatefulWidget {
  const CourseVideoPlayerPage({super.key});

  @override
  State<CourseVideoPlayerPage> createState() => _CourseVideoPlayerPageState();
}

class _CourseVideoPlayerPageState extends State<CourseVideoPlayerPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  bool _isInitialized = false;
  bool _isYoutube = false;
  String? _error;
  bool _started = false;
  bool _marked = false;
  String? _courseId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _initPlayer();
    }
  }

  /// Increments lessonsCompleted in the enrollment doc and recalculates progress.
  Future<void> _markVideoWatched() async {
    if (_marked || _courseId == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: uid)
          .where('courseId', isEqualTo: _courseId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return;

      final doc = snap.docs.first;
      final data = doc.data();
      final total = (data['totalLessons'] as num?)?.toInt() ?? 1;
      final completed = (data['lessonsCompleted'] as num?)?.toInt() ?? 0;
      final newCompleted = (completed + 1).clamp(0, total > 0 ? total : 1);
      final fraction = total > 0 ? newCompleted / total : 1.0;

      await doc.reference.update({
        'lessonsCompleted': newCompleted,
        'completedLessons': newCompleted,
        'progress': fraction,
        'progressPercent': fraction * 100,
        'lastAccessedAt': FieldValue.serverTimestamp(),
        if (newCompleted >= total && total > 0) 'status': 'completed',
        if (newCompleted >= total && total > 0) 'completedAt': Timestamp.now(),
      });

      _marked = true;
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress saved!')),
        );
      }
    } catch (_) {}
  }

  Future<void> _initPlayer() async {
    final extra = GoRouterState.of(context).extra;
    if (extra == null) {
      if (mounted) {
        setState(() => _error = 'No video data provided.');
      }
      return;
    }
    final args = extra as Map<String, dynamic>;
    final videoUrl = args['videoUrl'] as String?;
    final courseId = args['courseId'] as String?;
    _courseId = courseId;

    // Verify access: require logged-in + enrollment or purchase for paid courses.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _error = 'Please log in and enroll to view this video.');
      return;
    }

    if (courseId != null && courseId.isNotEmpty) {
      try {
        final enrollSnap = await FirebaseFirestore.instance
            .collection('enrollments')
            .where('studentId', isEqualTo: uid)
            .where('courseId', isEqualTo: courseId)
            .limit(1)
            .get();

        if (enrollSnap.docs.isEmpty) {
          // Not enrolled — check purchase status for paid courses
          final courseDoc = await FirebaseFirestore.instance
              .collection('courses')
              .doc(courseId)
              .get();
          final price = (courseDoc.data()?['price'] as num?)?.toDouble() ?? 0.0;
          if (price > 0) {
            final purchased = await PaymentService.isCoursePurchased(
              uid,
              courseId,
            );
            if (!purchased) {
              setState(
                () => _error = 'Please purchase and enroll to view this video.',
              );
              return;
            }
          } else {
            setState(() => _error = 'Please enroll to view this video.');
            return;
          }
        }
      } catch (e) {
        setState(() => _error = 'Access check failed: $e');
        return;
      }
    }

    if (videoUrl == null || videoUrl.isEmpty) {
      setState(() => _error = 'No video URL provided.');
      return;
    }

    try {
      if (isYoutubeUrl(videoUrl)) {
        // YouTube path
        final videoId = extractYoutubeId(videoUrl)!;
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
        );
        if (mounted) {
          setState(() {
            _isYoutube = true;
            _isInitialized = true;
          });
        }
      } else {
        // Direct URL path
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        );
        _videoController = controller;
        await controller.initialize();

        _chewieController = ChewieController(
          videoPlayerController: controller,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          allowMuting: true,
          showControlsOnInitialize: true,
        );

        // Auto-mark progress when video reaches the end
        controller.addListener(() {
          if (!_marked &&
              controller.value.isInitialized &&
              controller.value.duration > Duration.zero &&
              controller.value.position >=
                  controller.value.duration - const Duration(seconds: 2)) {
            _markVideoWatched();
          }
        });

        if (mounted) setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load video: $e');
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final title = args?['title'] as String? ?? 'Course Video';
    final courseId = args?['courseId'] as String?;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          // If we can't pop, we should go back to course detail if we have an ID
          if (courseId != null) {
            context.go(
              AppRoutes.studentCourseDetail,
              extra: {'courseId': courseId},
            );
          } else {
            context.go(AppRoutes.studentDashboard);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                if (courseId != null) {
                  context.go(
                    AppRoutes.studentCourseDetail,
                    extra: {'courseId': courseId},
                  );
                } else {
                  context.go(AppRoutes.studentDashboard);
                }
              }
            },
          ),
          title: Text(title),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white54,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.white54),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('Go Back'),
                          ),
                        ],
                      ),
                    )
                  : !_isInitialized
                  ? const Center(child: CircularProgressIndicator())
                  : _isYoutube
                  ? YoutubePlayer(
                      controller: _youtubeController!,
                      showVideoProgressIndicator: true,
                    )
                  : Chewie(controller: _chewieController!),
            ),
            Container(
              color: Theme.of(context).colorScheme.surface,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isInitialized && _videoController != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(
                        _videoController?.value.duration ?? Duration.zero,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (_courseId != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: _marked
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  'Lesson completed!',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : ElevatedButton.icon(
                              onPressed: _markVideoWatched,
                              icon: const Icon(Icons.check),
                              label: const Text('Mark as Complete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0E7C86),
                                foregroundColor: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
