import 'package:flutter/material.dart';

import '../../models/guest_home_content.dart';

class GuestCourseCard extends StatelessWidget {
  const GuestCourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.showCategory = true,
  });

  final GuestCourse course;
  final VoidCallback onTap;
  final bool showCategory;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    course.thumbnailAsset,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: course.accentColor.withValues(alpha: 0.12),
                      child: Center(
                        child: Icon(
                          course.icon,
                          size: 44,
                          color: course.accentColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                course.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (showCategory) ...[
                const SizedBox(height: 4),
                Text(
                  course.category,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(course.rating.toStringAsFixed(1)),
                  const Spacer(),
                  TextButton(onPressed: onTap, child: const Text('View')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
