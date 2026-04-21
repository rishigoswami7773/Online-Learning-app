import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'Can I explore courses without login?',
      'a':
          'Yes, guest users can browse courses, mentors, and previews before signing in.',
    },
    {
      'q': 'Do I need an account to enroll?',
      'a':
          'Yes. Enrollment and progress tracking require an authenticated account.',
    },
    {
      'q': 'How do I reset my password?',
      'a': 'Use the Forgot Password screen and submit your registered email.',
    },
    {
      'q': 'Are courses self-paced?',
      'a':
          'Most courses are self-paced with guided milestones and mentor support.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [AppColors.brandDark, AppColors.brand],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Find quick answers about guest access, enrollment, and platform features.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search common questions',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              Chip(label: Text('Guest Access')),
              Chip(label: Text('Billing')),
              Chip(label: Text('Mentorship')),
              Chip(label: Text('Account')),
            ],
          ),
          const SizedBox(height: 12),
          ..._faqs.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                leading: const Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.brand,
                ),
                title: Text(item['q'] ?? ''),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(item['a'] ?? ''),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
