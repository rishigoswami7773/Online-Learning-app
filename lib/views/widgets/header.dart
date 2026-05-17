import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import '../../utils/theme_helper.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Online Learning Demo'),
      actions: [
        TextButton(
          onPressed: () {
            GoRouter.of(context).push(AppRoutes.login);
          },
          child: Text('Login', style: TextStyle(color: context.textPrimary)),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
