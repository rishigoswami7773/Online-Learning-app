import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../controllers/app_auth_controller.dart';
import '../pages.dart'
    hide
        AdminAnalyticsScreen,
        ManageCategoriesPage,
        MentorStudentProgressScreen;
import '../views/screens/admin/admin_analytics_screen.dart';
import '../views/screens/admin/admin_activity_screen.dart';
import '../views/screens/admin/manage_categories.dart';
import '../views/profile/change_password_page.dart' as newchange;
import '../views/screens/admin/admin_profile_screen.dart';
import '../views/screens/admin/admin_add_mentor_screen.dart';
import '../views/screens/mentor/mentor_notifications.dart';
import '../views/screens/mentor/mentor_chat.dart';
import '../views/screens/mentor/mentor_profile.dart';
import '../views/screens/mentor/mentor_student_progress_screen.dart';
import '../views/screens/admin/admin_manage_courses_new.dart';
import '../views/screens/admin/admin_manage_users_new.dart';
import '../views/screens/admin/admin_send_notification_screen.dart';
import 'app_routes.dart';
import 'admin_routes.dart';

class AppRouter {
  AppRouter._();

  static const String initialRoute = AppRoutes.splash;

  static final GoRouter router = GoRouter(
    initialLocation: initialRoute,
    refreshListenable: Listenable.merge([
      AppAuthController().currentUser,
      AppAuthController().isLoadingRole,
    ]),
    redirect: (context, state) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final appUser = AppAuthController().currentUser.value;
      final isLoadingRole = AppAuthController().isLoadingRole.value;
      final isLoggedIn = firebaseUser != null || appUser != null;
      final path = state.uri.toString();
      final publicPaths = ['/login', '/register', '/splash', '/forgot'];

      // If NOT logged in and trying to access a protected route, go to /login
      if (!isLoggedIn && !publicPaths.contains(path)) {
        return '/login';
      }

      // While role is still loading, stay on splash â€” but let dashboard paths through
      if (isLoggedIn && isLoadingRole) {
        final isDashboard =
            path.startsWith('/student_') ||
            path.startsWith('/mentor_') ||
            path.startsWith('/admin');
        return (path == '/splash' || isDashboard) ? null : '/splash';
      }

      // If logged in but still on a public path, redirect to role dashboard
      if (isLoggedIn &&
          (path == '/login' || path == '/register' || path == '/')) {
        final role = appUser?.role;
        if (role == 'admin') return AppRoutes.adminHome;
        if (role == 'mentor') return AppRoutes.mentorDashboard;
        return AppRoutes.studentDashboard;
      }

      // Role-based protection
      final role = appUser?.role;
      if (role != null) {
        if (path.startsWith('/mentor_') && role != 'mentor') {
          if (role == 'admin') return AppRoutes.adminHome;
          return AppRoutes.studentDashboard;
        }
        if (path.startsWith('/student_') && role == 'admin') {
          return AppRoutes.adminHome;
        }
        if (path.startsWith('/admin') && role != 'admin') {
          if (role == 'mentor') {
            return AppRoutes.mentorDashboard;
          }
          return AppRoutes.studentDashboard;
        }
      }

      return null;
    },

    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const CoursesScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgot,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.courses,
        builder: (context, state) => const CoursesScreen(),
      ),
      GoRoute(
        path: AppRoutes.courseList,
        builder: (context, state) => const CourseListScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.contact,
        builder: (context, state) => const ContactUsScreen(),
      ),
      GoRoute(
        path: AppRoutes.faq,
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: AppRoutes.mentors,
        builder: (context, state) => const MentorListScreen(),
      ),
      GoRoute(
        path: AppRoutes.wishlist,
        builder: (context, state) => const WishlistPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EditProfileScreen(
            userProfile:
                extra?['userProfile'] as Map<String, dynamic>? ??
                const <String, dynamic>{},
            studentProfile:
                extra?['studentProfile'] as Map<String, dynamic>? ??
                const <String, dynamic>{},
          );
        },
      ),
      GoRoute(
        path: AppRoutes.manageCourses,
        builder: (context, state) => const ManageCoursesScreen(),
      ),
      GoRoute(
        path: AppRoutes.manageUsers,
        builder: (context, state) => const ManageUsersScreen(),
      ),
      GoRoute(
        path: AppRoutes.upload,
        builder: (context, state) => const CreateCoursePage(),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminManageCourses,
        builder: (context, state) => const AdminManageCoursesScreenNew(),
      ),
      GoRoute(
        path: AppRoutes.adminManageUsers,
        builder: (context, state) => const AdminManageUsersScreenNew(),
      ),
      GoRoute(
        path: AppRoutes.guestNotifications,
        builder: (context, state) => const ComingSoonScreen(
          title: 'Guest Notifications',
          description:
              'Guest notification support is not implemented yet. Please sign in to continue.',
        ),
      ),
      GoRoute(
        path: AppRoutes.guestChat,
        builder: (context, state) => const ComingSoonScreen(
          title: 'Guest Chat',
          description:
              'Guest chat support is not implemented yet. Please sign in to continue.',
        ),
      ),

      ShellRoute(
        builder: (context, state, child) {
          final location = GoRouterState.of(context).uri.toString();
          int currentIndex = _indexForLocation(location);
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (int idx) {
                final path = _pathForIndex(idx);
                if (path != null) context.go(path);
              },
              elevation: 8,
              backgroundColor: Theme.of(context).colorScheme.surface,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_filled),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: 'Browse',
                ),
                NavigationDestination(
                  icon: Icon(Icons.book_outlined),
                  selectedIcon: Icon(Icons.book_rounded),
                  label: 'My Courses',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.studentDashboard,
            builder: (context, state) => const StudentDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.studentBrowse,
            builder: (context, state) => const StudentBrowseCourses(),
          ),
          GoRoute(
            path: AppRoutes.studentMyCourses,
            builder: (context, state) => const MyCoursesPage(),
          ),
          GoRoute(
            path: AppRoutes.studentProfile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.studentCourseDetail,
        builder: (context, state) =>
            StudentCourseDetailPage(extra: state.extra),
      ),
      GoRoute(
        path: AppRoutes.studentWishlist,
        builder: (context, state) => const WishlistPage(),
      ),
      GoRoute(
        path: AppRoutes.studentVideo,
        builder: (context, state) => const CourseVideoPlayerPage(),
      ),
      GoRoute(
        path: AppRoutes.studentProgress,
        builder: (context, state) => const CourseProgressPage(),
      ),
      GoRoute(
        path: AppRoutes.studentNotifications,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra != null) {
            return NotificationDetailPage(
              title: extra['title']?.toString() ?? 'Notification',
              body: extra['body']?.toString() ?? '',
            );
          }
          return const NotificationsPage();
        },
      ),
      GoRoute(
        path: AppRoutes.studentChat,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra != null) {
            return ChatDetailPage(
              chatId: extra['chatId']?.toString() ?? '',
              title: extra['title']?.toString() ?? 'Chat',
            );
          }
          return const ChatPage();
        },
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const newchange.ChangePasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CheckoutScreen(
            courseId: extra['courseId'] as String,
            courseName: extra['courseName'] as String,
            price: (extra['price'] as num).toDouble(),
            mentorName: extra['mentorName'] as String? ?? '',
            thumbnailUrl: extra['thumbnailUrl'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.studentQuiz,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return StudentQuizScreen(
            quizId: extra?['quizId']?.toString() ?? '',
            courseId: extra?['courseId']?.toString() ?? '',
            moduleId: extra?['moduleId']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.studentAssignment,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return StudentAssignmentScreen(
            assignmentId: extra?['assignmentId']?.toString() ?? '',
            courseId: extra?['courseId']?.toString() ?? '',
            moduleId: extra?['moduleId']?.toString() ?? '',
          );
        },
      ),

      GoRoute(
        path: AppRoutes.mentorDashboard,
        builder: (context, state) => const MentorDashboard(),
      ),
      GoRoute(
        path: AppRoutes.mentorCreate,
        builder: (context, state) => const MentorCreateCourseScreenNew(),
      ),
      GoRoute(
        path: AppRoutes.mentorQuiz,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MentorQuizScreen(
            courseId: extra?['courseId']?.toString() ?? '',
            moduleId: extra?['moduleId']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.mentorLessons,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MentorLessonsScreen(
            courseId: extra?['courseId']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.mentorNotifications,
        builder: (context, state) => const MentorNotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.mentorChat,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return MentorChatPage(
            conversationId: args?['conversationId']?.toString() ?? '',
            toId: args?['toId']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.mentorProfile,
        builder: (context, state) => const MentorProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.mentorUpload,
        builder: (context, state) => const ContentUploadScreen(),
      ),
      GoRoute(
        path: AppRoutes.mentorManageCourses,
        builder: (context, state) => const MentorDashboard(),
      ),
      GoRoute(
        path: AppRoutes.mentorStudents,
        builder: (context, state) => const EnrolledStudentsPage(),
      ),
      GoRoute(
        path: AppRoutes.mentorStudentProgress,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MentorStudentProgressScreen(
            initialCourseId: extra?['courseId']?.toString(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.mentorRatings,
        builder: (context, state) => const MentorRatingsPage(),
      ),

      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminShell(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminProfile,
        builder: (context, state) => const AdminProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAddMentor,
        builder: (context, state) => const AdminAddMentorScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (context, state) => const AdminManageUsersScreenNew(),
      ),
      GoRoute(
        path: AppRoutes.adminApprovals,
        builder: (context, state) => const AdminUserApprovalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminMentorInvites,
        builder: (context, state) => const AdminMentorInvitesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCourses,
        builder: (context, state) => const AdminManageCoursesScreenNew(),
      ),
      GoRoute(
        path: AppRoutes.adminUpload,
        builder: (context, state) => const AdminContentUploadScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAnalytics,
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminActivity,
        builder: (context, state) => const AdminActivityScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        builder: (context, state) => const AdminSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminMentorPanel,
        builder: (context, state) => const AdminMentorPanelScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminManageCategories,
        builder: (context, state) => const ManageCategoriesPage(),
      ),
      GoRoute(
        path: AppRoutes.adminManageReviews,
        builder: (context, state) => const ManageReviewsPage(),
      ),
      GoRoute(
        path: AppRoutes.adminSendNotification,
        builder: (context, state) => const AdminSendNotificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminModules,
        builder: (context, state) => const AdminModulesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminQuizzes,
        builder: (context, state) => const AdminQuizzesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminEnrollments,
        builder: (context, state) => const AdminEnrollmentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCourseDetail,
        builder: (context, state) {
          final courseData = state.extra as Map<String, dynamic>?;
          return AdminCourseDetailScreen(
            courseData:
                courseData ?? {'title': 'Unknown', 'category': 'General'},
          );
        },
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.courseDetailPublic,
        builder: (context, state) => const GuestCourseDetailScreen(),
      ),
      GoRoute(
        name: AppRoutes.courseDetail,
        path: AppRoutes.courseDetail,
        builder: (context, state) =>
            StudentCourseDetailPage(extra: state.extra),
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Page not found'))),
  );

  static int _indexForLocation(String location) {
    if (location.startsWith(AppRoutes.studentBrowse)) return 1;
    if (location.startsWith(AppRoutes.studentMyCourses)) return 2;
    if (location.startsWith(AppRoutes.studentProfile)) return 3;
    return 0;
  }

  static String? _pathForIndex(int index) {
    switch (index) {
      case 0:
        return AppRoutes.studentDashboard;
      case 1:
        return AppRoutes.studentBrowse;
      case 2:
        return AppRoutes.studentMyCourses;
      case 3:
        return AppRoutes.studentProfile;
    }
    return null;
  }
}
