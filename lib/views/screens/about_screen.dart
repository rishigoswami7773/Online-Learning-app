import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [AppColors.brand, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/splash/splash.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.school_rounded,
                              size: 60,
                              color: Colors.white,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'LearnSphere',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Building career-ready learning experiences for everyone.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _InfoCard(
                title: 'Our Mission',
                body:
                    'We make quality learning accessible to everyone by combining flexible digital courses, practical projects, and mentor support.',
                icon: Icons.flag_outlined,
              ),
              const SizedBox(height: 12),
              const _InfoCard(
                title: 'What We Offer',
                body:
                    'Industry-ready programs, self-paced tracks, mentorship, and practical project workflows designed for real outcomes.',
                icon: Icons.workspace_premium_outlined,
              ),
              const SizedBox(height: 8),
              const _AboutPoint(text: 'Industry-ready courses across domains'),
              const _AboutPoint(
                text: 'Self-paced and structured learning paths',
              ),
              const _AboutPoint(
                text: 'Progress tracking and practical assignments',
              ),
              const _AboutPoint(
                text: 'Community and mentor support for learners',
              ),
              const SizedBox(height: 18),
              const _InfoCard(
                title: 'Contact',
                body:
                    'Email: support@learnsphere.app\nPhone: +91 90000 00000\nLocation: India',
                icon: Icons.contact_support_outlined,
              ),
              const SizedBox(height: 18),
              Text(
                'Platform Snapshot',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _StatChip(label: '10K+ Learners'),
                  _StatChip(label: '250+ Courses'),
                  _StatChip(label: '4.8 Avg Rating'),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.mentors),
                    icon: const Icon(Icons.workspace_premium_outlined),
                    label: const Text('Meet Mentors'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.faq),
                    icon: const Icon(Icons.quiz_outlined),
                    label: const Text('Read FAQ'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.contact),
                    icon: const Icon(Icons.contact_support_outlined),
                    label: const Text('Contact Us'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.brandSoft,
              child: Icon(icon, color: AppColors.brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(body, style: const TextStyle(height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutPoint extends StatelessWidget {
  const _AboutPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
