import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF102A43), AppColors.brand],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We are here to help',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Reach our support team for enrollment, mentorship, or technical guidance.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ContactChannelTile(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@learnsphere.app',
          ),
          _ContactChannelTile(
            icon: Icons.call_outlined,
            title: 'Call Us',
            subtitle: '+91 90000 00000 (Mon-Sat, 9AM-6PM)',
          ),
          _ContactChannelTile(
            icon: Icons.location_on_outlined,
            title: 'Head Office',
            subtitle: 'Bengaluru, India',
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Message',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Your email',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thanks! We will reach out soon.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Send Message'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactChannelTile extends StatelessWidget {
  const _ContactChannelTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.brandSoft,
          child: Icon(icon, color: AppColors.brand),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
