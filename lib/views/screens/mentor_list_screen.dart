import 'package:flutter/material.dart';

import '../../controllers/home_controller.dart';
import '../../models/mentor_model.dart';
import '../../theme/app_theme.dart';

class MentorListScreen extends StatelessWidget {
  const MentorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = const HomeController();
    final mentors = controller.getTopMentors();

    return Scaffold(
      appBar: AppBar(title: const Text('Top Mentors')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brand, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Learn From Industry Mentors',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Personalized guidance, practical insights, and career-focused learning support.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...mentors.map(
            (mentor) => _MentorCard(
              mentor: mentor,
              onBookMentorship: () =>
                  controller.bookMentorship(context, mentor),
            ),
          ),
        ],
      ),
    );
  }
}

class _MentorCard extends StatelessWidget {
  const _MentorCard({required this.mentor, required this.onBookMentorship});

  final MentorModel mentor;
  final VoidCallback onBookMentorship;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.brandSoft,
                  child: Text(
                    mentor.name.substring(0, 1),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentor.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mentor.expertise,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(mentor.rating.toStringAsFixed(1)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(mentor.bio, style: const TextStyle(height: 1.35)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: const Text('1:1 Sessions'),
                  backgroundColor: AppColors.brandSoft,
                ),
                Chip(
                  label: const Text('Project Guidance'),
                  backgroundColor: AppColors.brandSoft,
                ),
                Chip(
                  label: const Text('Career Tips'),
                  backgroundColor: AppColors.brandSoft,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onBookMentorship,
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Book Mentorship'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
