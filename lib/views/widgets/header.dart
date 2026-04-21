import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Online Learning Demo'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
          child: const Text('Login', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
