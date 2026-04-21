import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';

class AdminPageWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  const AdminPageWrapper({super.key, required this.title, required this.child});

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    // if there is nowhere to pop, go to main admin route
    Navigator.of(context).pushReplacementNamed(AppRoutes.admin);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _handleBack(context),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.admin),
                  tooltip: 'Back to admin home',
                )
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
