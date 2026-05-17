// PASTE THIS INTO pubspec.yaml under dependencies FIRST, then run: flutter pub get
//   url_launcher: ^6.3.0

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:online_learning_app/routes/app_routes.dart';

void _safeBackToStudentDashboard(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.studentDashboard);
  }
}

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  Future<List<Map<String, dynamic>>> _fetchFAQ() async {
    final snap = await FirebaseFirestore.instance
        .collection('faq')
        .orderBy('order')
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<String> _fetchSupportEmail() async {
    final snap = await FirebaseFirestore.instance
        .doc('settings/platform')
        .get();
    if (snap.exists) {
      return (snap.data() as Map<String, dynamic>)['supportEmail'] ?? '';
    }
    return '';
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _safeBackToStudentDashboard(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _safeBackToStudentDashboard(context),
          ),
          title: const Text('Help & Support'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FAQ Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Frequently Asked Questions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchFAQ(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No FAQs available.'),
                    );
                  }
                  return Column(
                    children: items.map((item) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          title: Text(
                            item['question'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(item['answer'] ?? ''),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 16),
              const Divider(),

              // Contact Us Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Contact Us',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FutureBuilder<String>(
                future: _fetchSupportEmail(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: Icon(Icons.email_outlined),
                      title: Text('Loading...'),
                    );
                  }
                  final email = snap.data ?? '';
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email Support'),
                      subtitle: Text(
                        email.isNotEmpty ? email : 'Not configured',
                      ),
                      trailing: email.isNotEmpty
                          ? const Icon(Icons.chevron_right)
                          : null,
                      onTap: email.isNotEmpty
                          ? () => _launchEmail(email)
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Terms & Privacy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
