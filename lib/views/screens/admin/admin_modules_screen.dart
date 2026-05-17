import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Admin module and lesson management screen
class AdminModulesScreen extends StatefulWidget {
  const AdminModulesScreen({super.key});

  @override
  State<AdminModulesScreen> createState() => _AdminModulesScreenState();
}

class _AdminModulesScreenState extends State<AdminModulesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Module Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Admin Module Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              Text(
                'Module and lesson management interface coming soon',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
