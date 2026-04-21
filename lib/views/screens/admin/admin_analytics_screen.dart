import 'package:flutter/material.dart';
import 'admin_widgets.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdminPageWrapper(
        title: 'Analytics',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Analytics', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Card(child: SizedBox(height: 180, child: Center(child: Text('Active users chart placeholder')))),
            const SizedBox(height: 12),
            Card(child: SizedBox(height: 180, child: Center(child: Text('Revenue / Growth placeholder')))),
          ]),
        ),
      ),
    );
  }
}
