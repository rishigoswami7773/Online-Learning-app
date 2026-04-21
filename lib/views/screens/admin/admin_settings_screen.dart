import 'package:flutter/material.dart';
import 'admin_widgets.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdminPageWrapper(
        title: 'Settings',
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const ListTile(leading: Icon(Icons.palette), title: Text('Theme')),
          const ListTile(leading: Icon(Icons.language), title: Text('Language')),
          const ListTile(leading: Icon(Icons.security), title: Text('Security')),
          const Divider(),
          ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save),
              label: const Text('Save settings')),
        ]),
      ),
    );
  }
}
