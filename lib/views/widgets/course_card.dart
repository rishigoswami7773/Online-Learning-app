import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import 'package:online_learning_app/utils/theme_helper.dart';

const Color _studentTeal = Color(0xFF0E7C86);

class CourseCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const CourseCard({super.key, required this.data});

  static final List<Map<String, dynamic>> dummyCourses = [
    {
      'id': 'c1',
      'title': 'Flutter for Beginners',
      'instructor': 'Celine',
      'rating': 4.5,
      'description': 'Learn basics of Flutter and build real apps.',
    },
    {
      'id': 'c2',
      'title': 'Advanced Dart',
      'instructor': 'Admin',
      'rating': 4.2,
      'description': 'Deep dive into Dart language features.',
    },
    {
      'id': 'c3',
      'title': 'UI/UX for Mobile',
      'instructor': 'Alice',
      'rating': 4.7,
      'description': 'Design beautiful mobile user interfaces.',
    },
  ];

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool _isHovered = false;

  String? _youTubeId(String url) {
    if (url.isEmpty) return null;
    for (final pattern in [
      RegExp(r'youtube\.com/watch\?v=([^&]+)'),
      RegExp(r'youtu\.be/([^?]+)'),
      RegExp(r'youtube\.com/embed/([^?]+)'),
    ]) {
      final m = pattern.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final rawThumb =
        (widget.data['thumbnailUrl'] ??
                widget.data['thumbnailURL'] ??
                widget.data['thumbnailAsset'] ??
                '')
            .toString();
    final videoUrl =
        (widget.data['videoUrl'] ?? widget.data['youtubeUrl'] ?? '')
            .toString();
    final ytId = rawThumb.isEmpty ? _youTubeId(videoUrl) : null;
    final thumb = rawThumb.isNotEmpty
        ? rawThumb
        : (ytId != null
              ? 'https://img.youtube.com/vi/$ytId/hqdefault.jpg'
              : '');
    final title = (widget.data['title'] ?? 'Untitled').toString();
    final instructor = (widget.data['instructor'] ?? 'Unknown').toString();
    final rating = (widget.data['rating'] as num?)?.toDouble() ?? 0.0;
    final price = (widget.data['price'] as num?)?.toDouble() ?? 0.0;
    final category = (widget.data['category'] ?? 'General').toString();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          context.push(
            AppRoutes.studentCourseDetail,
            extra: {'courseId': (widget.data['id'] ?? '').toString()},
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor, width: 0.8),
            boxShadow: context.isDark
                ? const []
                : (_isHovered ? context.cardShadow : context.cardShadow),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _studentTeal.withValues(alpha: 0.8),
                        const Color(0xFF17A2B8),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Thumbnail image or placeholder
                      SizedBox.expand(
                        child:
                            (thumb.startsWith('http://') ||
                                thumb.startsWith('https://'))
                            ? Image.network(
                                thumb,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, st) => Center(
                                  child: Icon(
                                    Icons.school_rounded,
                                    size: 56,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.school_rounded,
                                  size: 56,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                      ),
                      // Category chip
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _studentTeal,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Instructor
                        Text(
                          'By $instructor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: context.textSecondary,
                          ),
                        ),

                        const Spacer(),

                        // Rating
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '($rating)',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Price
                        if (price > 0)
                          Text(
                            '\$${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _studentTeal,
                            ),
                          ),
                      ],
                    ),
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
