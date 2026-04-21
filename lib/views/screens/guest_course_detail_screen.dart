import 'package:flutter/material.dart';

import '../../controllers/home_controller.dart';

class GuestCourseDetailScreen extends StatelessWidget {
  const GuestCourseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        const <String, dynamic>{};

    final title = args['title'] as String? ?? 'Course Details';
    final category = args['category'] as String? ?? 'General';
    final instructor = args['instructor'] as String? ?? 'LearnSphere Team';
    final description =
        args['description'] as String? ??
        'Explore this learning path in guest mode. Sign in to unlock full access.';
    final rating = (args['rating'] as num?)?.toDouble() ?? 4.5;
    final duration = args['duration'] as String? ?? '6 Weeks';
    final level = args['level'] as String? ?? 'Beginner';
    final priceLabel = args['priceLabel'] as String? ?? 'INR 999';
    final thumbnailAsset = args['thumbnailAsset'] as String? ?? '';
    final highlights =
        (args['highlights'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[
          'Structured lessons with hands-on tasks',
          'Mentor support and feedback checkpoints',
          'Practical projects to build confidence',
        ];

    const previewLessons = <String>[
      'Welcome & Course Orientation',
      'Core Concepts and Foundations',
      'Guided Project Walkthrough',
      'Assessment and Certification',
    ];

    final controller = const HomeController();

    return Scaffold(
      appBar: AppBar(title: const Text('Course Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: thumbnailAsset.isEmpty
                  ? Container(
                      color: const Color(0xFFE3F4F6),
                      child: const Center(
                        child: Icon(Icons.school_rounded, size: 72),
                      ),
                    )
                  : Image.asset(
                      thumbnailAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFE3F4F6),
                        child: const Center(
                          child: Icon(Icons.school_rounded, size: 72),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(category)),
              Chip(label: Text(duration)),
              Chip(label: Text(level)),
              Chip(label: Text(priceLabel)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text('Instructor: $instructor')),
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(rating.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 16),
          Text(
            'What you will learn',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...highlights.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(Icons.check_circle, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Preview Lessons (Locked in Guest Mode)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...previewLessons.asMap().entries.map(
            (entry) => Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text('Lesson ${entry.key + 1}: ${entry.value}'),
                subtitle: const Text('Login required to watch this lesson'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    controller.requireAuthenticationForEnrollment(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () =>
                controller.requireAuthenticationForEnrollment(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Enroll Now'),
            ),
          ),
        ],
      ),
    );
  }
}
