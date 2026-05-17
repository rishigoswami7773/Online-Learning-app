import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();

    Timer(const Duration(seconds: 2), _handleStartupNavigation);
  }

  Future<void> _handleStartupNavigation() async {
    if (!mounted) {
      return;
    }

    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      GoRouter.of(context).go(AppRoutes.login);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!mounted) {
        return;
      }

      if (!userDoc.exists) {
        await auth.signOut();
        if (!mounted) {
          return;
        }
        GoRouter.of(context).go(AppRoutes.login);
        return;
      }

      final data = userDoc.data()!;
      final role = (data['role'] ?? '').toString().toLowerCase();

      if (role == 'student') {
        GoRouter.of(context).go(AppRoutes.studentDashboard);
        return;
      }

      if (role == 'mentor') {
        GoRouter.of(context).go(AppRoutes.mentorDashboard);
        return;
      }

      if (role == 'admin') {
        GoRouter.of(context).go(AppRoutes.adminDashboard);
        return;
      }

      await auth.signOut();
      if (!mounted) {
        return;
      }
      GoRouter.of(context).go(AppRoutes.login);
    } catch (_) {
      await auth.signOut();
      if (!mounted) {
        return;
      }
      GoRouter.of(context).go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).primaryColor,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Image.asset(
                    'assets/splash/splash.png',
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.school, color: Colors.white, size: 96),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Learnify',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Learn. Grow. Succeed.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
