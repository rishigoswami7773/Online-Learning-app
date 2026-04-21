// Barrel file: import this single file to access common screens and widgets

// Core screens
export 'firebase_options.dart';
export 'views/screens/splash_screen.dart';
export 'views/screens/login_screen.dart';
export 'views/screens/registration_screen.dart';
export 'views/screens/forgot_password_screen.dart';

// Public / catalog
export 'views/screens/courses_screen.dart';
export 'views/screens/course_list_screen.dart';
export 'views/screens/course_detail_screen.dart';
export 'views/screens/guest_course_detail_screen.dart';
export 'views/screens/about_screen.dart';
export 'views/screens/mentor_list_screen.dart';
export 'views/screens/contact_us_screen.dart';
export 'views/screens/faq_screen.dart';
export 'views/screens/coming_soon_screen.dart';

// Tabs / panels
export 'views/screens/dashboard_screen.dart';
export 'views/screens/admin_panel.dart';
export 'views/screens/mentor_panel.dart';
export 'views/screens/student_panel.dart';

// Student screens
export 'views/screens/student/dashboard.dart';
export 'views/screens/student/browse_courses.dart';
export 'views/screens/student/my_courses.dart';
export 'views/screens/student/wishlist_page.dart';
export 'views/screens/student/video_player.dart';
export 'views/screens/student/progress.dart';
export 'views/screens/student/notifications.dart';
export 'views/screens/student/student_profile.dart';
export 'views/screens/student/change_password.dart';
export 'views/screens/edit_profile_screen.dart';
export 'views/screens/student/help_support.dart';
export 'views/screens/student/notifications_detail.dart';
export 'views/screens/student/chat_page.dart';
export 'views/screens/student/tasks_page.dart';
export 'views/screens/student/courses_page.dart';
export 'views/screens/student/course_detail_page.dart';

// Mentor screens
export 'views/screens/mentor/dashboard.dart';
export 'views/screens/mentor/create_course.dart';
export 'views/screens/mentor/enrolled_students.dart';
export 'views/screens/mentor/ratings.dart';
export 'views/screens/content_upload_screen.dart';
export 'views/screens/manage_courses_screen.dart';

// Admin screens
export 'views/screens/admin/dashboard.dart';
export 'views/screens/admin/admin_scaffold.dart';
export 'views/screens/admin/admin_home_screen.dart';
export 'views/screens/admin/admin_manage_users_screen.dart';
export 'views/screens/admin/admin_manage_courses_screen.dart'
    hide CourseDetailScreen;
export 'views/screens/admin/admin_content_upload_screen.dart';
export 'views/screens/admin/admin_analytics_screen.dart';
export 'views/screens/admin/admin_settings_screen.dart';
export 'views/screens/manage_users_screen.dart';
export 'views/screens/admin/manage_categories.dart';
export 'views/screens/admin/analytics.dart';
export 'views/screens/admin/manage_reviews.dart';

// Utilities & widgets
export 'views/screens/search_screen.dart';
export 'views/screens/profile_screen.dart';
export 'views/widgets/course_card.dart' hide CourseCard;
export 'views/widgets/header.dart';
export 'views/widgets/sidebar.dart';
export 'views/widgets/responsive_scaffold.dart';

// Guest models
export 'models/course_model.dart';
export 'models/mentor_model.dart';
