import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'controllers/theme_controller.dart';
import 'services/firestore_setup.dart';
import 'pages.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Only run setup if an admin user is already signed in
  // to avoid Firestore permission-denied errors on cold start.
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    try {
      await FirestoreSetup.ensureCollections();
    } catch (e) {
      debugPrint('FirestoreSetup failed: $e');
    }
  }
  await ThemeController().loadSaved();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController().mode,
      builder: (context, mode, _) {
        return MaterialApp.router(
          title: 'Online Learning Platform',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          routerConfig: AppRouter.router,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
        );
      },
    );
  }
}
