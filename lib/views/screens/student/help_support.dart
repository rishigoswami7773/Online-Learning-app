import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          ListTile(title: Text('FAQ'), subtitle: Text('Common questions and answers')),
          ListTile(title: Text('Contact Us'), subtitle: Text('support@example.com')),
          ListTile(title: Text('Terms & Privacy')),
        ],
      ),
    );
  }
}
