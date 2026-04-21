import 'package:flutter/material.dart';
import 'package:online_learning_app/views/widgets/dashboard_constants.dart';

// ============ SHIMMER EFFECT ============

class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({required this.child, this.isLoading = true, super.key});

  final Widget child;
  final bool isLoading;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 - (2 * _controller.value), 0),
              end: Alignment(1.0 + (2 * _controller.value), 0),
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// ============ SECTION HEADER ============

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionText,
    this.onActionTap,
    this.icon,
    super.key,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DashboardConstants.spacingL,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: DashboardConstants.brandColor),
            const SizedBox(width: DashboardConstants.spacingM),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText!,
                style: TextStyle(
                  color: DashboardConstants.brandColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============ COURSE CARD ============

class CourseCard extends StatelessWidget {
  const CourseCard({
    required this.imageUrl,
    required this.title,
    required this.category,
    required this.instructor,
    required this.rating,
    required this.studentCount,
    this.progress,
    this.tags = const [],
    this.onTap,
    this.showProgress = false,
    this.difficulty,
    super.key,
  });

  final String imageUrl;
  final String title;
  final String category;
  final String instructor;
  final double rating;
  final String studentCount;
  final double? progress; // 0-1, null if no progress
  final List<String> tags; // e.g., ['Bestseller', 'New']
  final VoidCallback? onTap;
  final bool showProgress;
  final String? difficulty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DashboardConstants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DashboardConstants.radiusLarge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with tags overlay
              Stack(
                children: [
                  _CourseImage(url: imageUrl, height: 140),
                  if (tags.isNotEmpty)
                    Positioned(
                      top: DashboardConstants.spacingM,
                      left: DashboardConstants.spacingM,
                      right: DashboardConstants.spacingM,
                      child: Row(
                        children: tags
                            .take(2)
                            .map(
                              (tag) => Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: DashboardConstants.spacingS,
                                    vertical: DashboardConstants.spacingXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getTagColor(tag),
                                    borderRadius: BorderRadius.circular(
                                      DashboardConstants.radiusSmall,
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            )
                            .toList()
                            .expand(
                              (widget) => [
                                widget,
                                const SizedBox(
                                  width: DashboardConstants.spacingXS,
                                ),
                              ],
                            )
                            .toList()
                            .dropLast(1),
                      ),
                    ),
                ],
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(DashboardConstants.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: DashboardConstants.spacingS),
                      Text(
                        instructor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: DashboardConstants.spacingM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Color(0xFFFBBF24),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            studentCount,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (showProgress && progress != null) ...[
                        const SizedBox(height: DashboardConstants.spacingM),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            color: DashboardConstants.brandColor,
                            backgroundColor: DashboardConstants.brandColor
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        const SizedBox(height: DashboardConstants.spacingS),
                        Text(
                          '${(progress! * 100).toStringAsFixed(0)}% completed',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: DashboardConstants.brandColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTagColor(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('bestseller') || lower.contains('popular')) {
      return DashboardConstants.accentColor;
    }
    if (lower.contains('new')) {
      return DashboardConstants.successColor;
    }
    if (lower.contains('trending')) {
      return DashboardConstants.warningColor;
    }
    return DashboardConstants.brandColor;
  }
}

// ============ COURSE IMAGE ============

class _CourseImage extends StatelessWidget {
  const _CourseImage({required this.url, this.height = 140});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DashboardConstants.brandColor.withValues(alpha: 0.1),
              DashboardConstants.accentColor.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(DashboardConstants.radiusLarge),
            topRight: Radius.circular(DashboardConstants.radiusLarge),
          ),
        ),
        child: const Center(child: Icon(Icons.auto_stories_outlined, size: 40)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(DashboardConstants.radiusLarge),
        topRight: Radius.circular(DashboardConstants.radiusLarge),
      ),
      child: Image.network(
        url,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DashboardConstants.brandColor.withValues(alpha: 0.1),
                  DashboardConstants.accentColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.auto_stories_outlined, size: 40),
            ),
          );
        },
      ),
    );
  }
}

// ============ QUICK ACTION CARD ============

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (backgroundColor ?? DashboardConstants.brandColor).withValues(
                    alpha: 0.15,
                  ),
                  (backgroundColor ?? DashboardConstants.brandColor).withValues(
                    alpha: 0.05,
                  ),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(
                DashboardConstants.radiusLarge,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor ?? DashboardConstants.brandColor,
              size: 28,
            ),
          ),
          const SizedBox(height: DashboardConstants.spacingS),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============ CATEGORY CHIP ============

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DashboardConstants.spacingM,
          vertical: DashboardConstants.spacingS,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    DashboardConstants.brandColor,
                    DashboardConstants.accentColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: !isSelected ? DashboardConstants.neutralLight : null,
          borderRadius: BorderRadius.circular(DashboardConstants.radiusLarge),
          border: !isSelected
              ? Border.all(color: Colors.grey[300]!, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : DashboardConstants.brandColor,
            ),
            const SizedBox(width: DashboardConstants.spacingS),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ STREAK CARD ============

class StreakCard extends StatelessWidget {
  const StreakCard({
    required this.streakDays,
    required this.message,
    super.key,
  });

  final int streakDays;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DashboardConstants.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            streakDays > 0
                ? DashboardConstants.successColor.withValues(alpha: 0.1)
                : DashboardConstants.neutralLight,
            streakDays > 0
                ? const Color(0xFFFEF3C7)
                : DashboardConstants.neutralLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DashboardConstants.radiusLarge),
        border: Border.all(
          color: streakDays > 0
              ? DashboardConstants.successColor.withValues(alpha: 0.2)
              : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Text(
            streakDays > 0 ? '🔥' : '⭐',
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: DashboardConstants.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streakDays > 0
                      ? '$streakDays Day Streak'
                      : 'Start Your Streak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DashboardConstants.spacingXS),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============ STAT CARD ============

class StatCard extends StatelessWidget {
  const StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DashboardConstants.spacingL),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DashboardConstants.radiusLarge),
          border: Border.all(color: Colors.grey[200]!),
          color: Colors.grey[50],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DashboardConstants.brandColor.withValues(alpha: 0.1),
                    DashboardConstants.accentColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(
                  DashboardConstants.radiusSmall,
                ),
              ),
              child: Icon(icon, color: DashboardConstants.brandColor),
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DashboardConstants.spacingXS),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ============ EMPTY STATE ============

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onButtonTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onButtonTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DashboardConstants.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: DashboardConstants.brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 44, color: DashboardConstants.brandColor),
            ),
            const SizedBox(height: DashboardConstants.spacingXL),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DashboardConstants.spacingM),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DashboardConstants.spacing2XL),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onButtonTap,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper extension to drop last element from list
extension DropLastExtension<T> on List<T> {
  List<T> dropLast(int count) {
    return length <= count ? [] : sublist(0, length - count);
  }
}
