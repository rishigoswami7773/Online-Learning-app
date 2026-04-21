import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'pages.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
    return MaterialApp(
      title: 'Online Learning Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRouter.initialRoute,
      routes: AppRouter.routes,
      onGenerateRoute: AppRouter.onGenerateRoute,
      // Listen to auth state changes and handle navigation accordingly
      navigatorObservers: [_AuthNavigatorObserver()],
    );
  }
}

/// Custom NavigatorObserver to ensure users cannot access guest routes when logged in
class _AuthNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _checkAuthStateForRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _checkAuthStateForRoute(newRoute);
    }
  }

  void _checkAuthStateForRoute(Route<dynamic> route) {
    final routeName = route.settings.name;
    if (routeName == null) return;

    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isGuestRoute = _isGuestRoute(routeName);
    final isAuthRoute = _isAuthRoute(routeName);

    // If user is logged in and trying to access guest/auth routes, redirect to dashboard
    if (isLoggedIn && (isGuestRoute || isAuthRoute)) {
      Future.microtask(
        () => navigator?.pushNamedAndRemoveUntil(
          '/student_dashboard',
          (route) => false,
        ),
      );
    }
  }

  /// Check if route is a guest-only route
  bool _isGuestRoute(String routeName) {
    final guestRoutes = [
      '/',
      '/splash',
      '/courses',
      '/course_list',
      '/about',
      '/mentors',
      '/contact',
      '/faq',
      '/wishlist',
      '/guest_notifications',
      '/guest_chat',
      '/course_detail_public',
    ];
    return guestRoutes.contains(routeName);
  }

  /// Check if route is authentication-only route
  bool _isAuthRoute(String routeName) {
    final authRoutes = ['/login', '/register', '/forgot'];
    return authRoutes.contains(routeName);
  }
}
