import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/auth_controller.dart';
import '../pages.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static const String initialRoute = AppRoutes.splash;

  static final Map<String, WidgetBuilder> routes = {
    AppRoutes.home: (ctx) => const CoursesScreen(),
    AppRoutes.splash: (ctx) => const SplashScreen(),
    AppRoutes.courses: (ctx) => const CoursesScreen(),
    AppRoutes.courseList: (ctx) => const CourseListScreen(),
    AppRoutes.login: (ctx) => const LoginScreen(),
    AppRoutes.register: (ctx) => const RegistrationScreen(),
    AppRoutes.forgot: (ctx) => const ForgotPasswordScreen(),
    AppRoutes.about: (ctx) => const AboutScreen(),
    AppRoutes.mentors: (ctx) => const MentorListScreen(),
    AppRoutes.contact: (ctx) => const ContactUsScreen(),
    AppRoutes.faq: (ctx) => const FaqScreen(),
    AppRoutes.wishlist: (ctx) => const ComingSoonScreen(
      title: 'Wishlist',
      description: 'Save your favorite courses and track them here soon.',
      icon: Icons.favorite_border,
    ),
    AppRoutes.guestNotifications: (ctx) => const ComingSoonScreen(
      title: 'Notifications',
      description: 'Get updates and reminders in this section soon.',
      icon: Icons.notifications_outlined,
    ),
    AppRoutes.guestChat: (ctx) => const ComingSoonScreen(
      title: 'Chat & Support',
      description: 'Talk to support and mentors once this feature is launched.',
      icon: Icons.support_agent,
    ),

    AppRoutes.studentDashboard: (ctx) =>
        const _RoleProtectedScreen(role: 'student', child: StudentDashboard()),
    AppRoutes.studentBrowse: (ctx) => const CoursesPage(),
    AppRoutes.studentMyCourses: (ctx) => const MyCoursesPage(),
    AppRoutes.studentCourseDetail: (ctx) => const StudentCourseDetailPage(),
    AppRoutes.studentWishlist: (ctx) => const WishlistPage(),
    AppRoutes.studentVideo: (ctx) => const CourseVideoPlayerPage(),
    AppRoutes.studentProgress: (ctx) => const CourseProgressPage(),
    AppRoutes.studentNotifications: (ctx) => const NotificationsPage(),
    AppRoutes.studentChat: (ctx) => const ChatPage(),
    AppRoutes.studentProfile: (ctx) => const ProfileScreen(),
    AppRoutes.changePassword: (ctx) => const ChangePasswordPage(),
    AppRoutes.editProfile: (ctx) => const EditProfileScreen(),

    AppRoutes.mentorDashboard: (ctx) =>
        const _RoleProtectedScreen(role: 'mentor', child: MentorDashboard()),
    AppRoutes.mentorCreate: (ctx) => const CreateCoursePage(),
    AppRoutes.mentorUpload: (ctx) => const ContentUploadScreen(),
    AppRoutes.mentorManageCourses: (ctx) => const ManageCoursesScreen(),
    AppRoutes.mentorStudents: (ctx) => const EnrolledStudentsPage(),
    AppRoutes.mentorRatings: (ctx) => const MentorRatingsPage(),

    AppRoutes.admin: (ctx) => const AdminScaffold(),
    AppRoutes.adminHome: (ctx) => const AdminHomeScreen(),
    AppRoutes.adminDashboard: (ctx) =>
        const _RoleProtectedScreen(role: 'admin', child: AdminHomeScreen()),
    AppRoutes.adminUsers: (ctx) => const AdminManageUsersScreen(),
    AppRoutes.adminManageUsers: (ctx) => const AdminManageUsersScreen(),
    AppRoutes.adminCourses: (ctx) => const AdminManageCoursesScreen(),
    AppRoutes.adminManageCourses: (ctx) => const AdminManageCoursesScreen(),
    AppRoutes.adminUpload: (ctx) => const AdminContentUploadScreen(),
    AppRoutes.adminAnalytics: (ctx) => const AdminAnalyticsScreen(),
    AppRoutes.adminSettings: (ctx) => const AdminSettingsScreen(),
    AppRoutes.adminManageCategories: (ctx) => const ManageCategoriesPage(),
    AppRoutes.adminManageReviews: (ctx) => const ManageReviewsPage(),

    AppRoutes.manageCourses: (ctx) => const ManageCoursesScreen(),
    AppRoutes.manageUsers: (ctx) => const ManageUsersScreen(),
    AppRoutes.upload: (ctx) => const ContentUploadScreen(),
    AppRoutes.search: (ctx) => const SearchScreen(),
    AppRoutes.courseDetailPublic: (ctx) => const GuestCourseDetailScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == AppRoutes.courseDetail) {
      return MaterialPageRoute(
        builder: (_) => const CourseDetailScreen(),
        settings: settings,
      );
    }

    if (settings.name == AppRoutes.profile) {
      return MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
        settings: settings,
      );
    }

    return null;
  }
}

class _RoleProtectedScreen extends StatelessWidget {
  const _RoleProtectedScreen({required this.role, required this.child});

  final String role;
  final Widget child;

  Future<bool> _canAccessRole() async {
    final dummyRole = AuthController.activeDummyRole;
    if (dummyRole == role) {
      return true;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) {
      return false;
    }

    final data = doc.data()!;
    final userRole = (data['role'] ?? '').toString().toLowerCase();
    final isVerified = data['isVerified'] == true;

    if (role == 'student') {
      return userRole == 'student' && isVerified;
    }

    return userRole == role;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canAccessRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return child;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Access Restricted')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'You are not authorized to access this dashboard.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => false,
                      );
                    },
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
