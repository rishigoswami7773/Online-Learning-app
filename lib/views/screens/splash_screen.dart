import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
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
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        return;
      }

      final data = userDoc.data()!;
      final role = (data['role'] ?? '').toString().toLowerCase();
      final isVerified = data['isVerified'] == true;

      if (role == 'student' && isVerified) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.studentDashboard);
        return;
      }

      if (role == 'mentor') {
        Navigator.of(context).pushReplacementNamed(AppRoutes.mentorDashboard);
        return;
      }

      if (role == 'admin') {
        Navigator.of(context).pushReplacementNamed(AppRoutes.adminDashboard);
        return;
      }

      await auth.signOut();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    } catch (_) {
      await auth.signOut();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
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
                  'LearnSphere',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explore first. Enroll when ready.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
