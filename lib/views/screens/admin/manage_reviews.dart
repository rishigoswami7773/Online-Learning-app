import 'package:flutter/material.dart';

class ManageReviewsPage extends StatelessWidget {
  const ManageReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Manage Reviews')), body: const Center(child: Text('Moderate reviews (demo)')));
  }
}
