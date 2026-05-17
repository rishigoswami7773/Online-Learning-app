# Admin Panel - Complete Pages Guide

## Overview
This admin panel provides comprehensive management of the Online Learning Platform with full Firebase integration and dynamic data handling.

---

## 📊 Admin Panel Pages

### 1. **Dashboard** (`admin_home_screen.dart`)
**Route:** `/admin_dashboard`
**Icon:** Dashboard
- **Features:**
  - Real-time KPI cards (Total Users, Students, Courses, Enrollments)
  - Recent Users stream from Firebase
  - Recent Enrollments stream from Firebase
  - Quick Action buttons (Add Course, Add Staff, View Reports)
  - System Status toggle (Maintenance Mode)
  - Responsive design (Mobile & Desktop)
- **Firebase Collections Used:**
  - `users` - For user statistics
  - `students` - For student count
  - `courses` - For course statistics
  - `enrollments` - For enrollment data

---

### 2. **Users Management** (`admin_manage_users_screen.dart`)
**Route:** `/admin_users`
**Icon:** People
- **Features:**
  - View all users from Firebase
  - Filter users by role (Student, Mentor, Staff, Admin)
  - Search users by name/email
  - Edit user information
  - Delete users with confirmation
  - Bulk actions (optional)
- **Firebase Collections Used:**
  - `users` - Main user collection
- **Actions:**
  - Create new user
  - Edit user details
  - Change user role
  - Delete user

---

### 3. **User Approvals** (`admin_user_approvals_screen.dart`)
**Route:** `/admin_approvals`
**Icon:** Pending Actions
- **Features:**
  - View pending user registrations
  - Approve users to activate their accounts
  - Reject users with reason
  - Filter by status (Pending, Approved, Rejected)
  - Auto-load based on `status: 'pending'`
- **Firebase Collections Used:**
  - `users` - Filter by `status` field
- **Actions:**
  - Approve registration
  - Reject registration
  - Bulk approve/reject

---

### 4. **Staff Invites** (`admin_staff_invites_screen.dart`)
**Route:** `/admin_staff_invites`
**Icon:** Person Add
- **Features:**
  - Send staff invitations
  - Track invitation status
  - Resend invitations
  - Cancel pending invites
  - View accepted staff members
- **Firebase Collections Used:**
  - `invites` - Store invitation data
  - `staff` - View accepted staff
- **Actions:**
  - Generate and send invite links
  - View invite history
  - Track acceptance status

---

### 5. **Courses Management** (`admin_manage_courses_screen.dart`)
**Route:** `/admin_courses`
**Icon:** Menu Book
- **Features:**
  - View all courses
  - Filter by category, level, status
  - Search courses
  - Create new course
  - Edit course details
  - Delete courses
  - Publish/Unpublish courses
  - View course analytics
- **Firebase Collections Used:**
  - `courses` - Main course collection
  - `courses/{courseId}/videos` - Course videos
- **Actions:**
  - Create course
  - Edit course details
  - Upload course content
  - Manage course videos
  - Delete course

---

### 6. **Content Upload** (`admin_content_upload_screen.dart`)
**Route:** `/admin_upload`
**Icon:** Video Library
- **Features:**
  - Upload course videos
  - Manage course materials
  - Upload video subtitles
  - Set video duration/order
  - Mark videos as free/premium
  - Bulk upload support
- **Firebase Collections Used:**
  - `courses/{courseId}/videos` - Store video metadata
  - Firebase Storage - Store actual video files
- **Actions:**
  - Upload new video
  - Edit video details
  - Delete video
  - Reorder videos

---

### 7. **Analytics** (`admin_analytics_screen.dart`)
**Route:** `/admin_analytics`
**Icon:** Bar Chart
- **Features:**
  - Platform statistics dashboard
  - User engagement metrics
  - Course completion rates
  - Revenue/enrollment trends
  - Charts and visualizations
  - Export reports (PDF/CSV)
- **Firebase Collections Used:**
  - `users` - User data
  - `courses` - Course data
  - `enrollments` - Enrollment statistics
  - `progress` - User progress tracking
- **Actions:**
  - View analytics
  - Filter by date range
  - Export reports

---

### 8. **Reviews Management** (`manage_reviews.dart`)
**Route:** `/admin_manage_reviews`
**Icon:** Rate Review
- **Features:**
  - View all course reviews
  - Filter by rating, course, status
  - Approve/reject reviews
  - Delete inappropriate reviews
  - Respond to reviews
  - View review statistics
- **Firebase Collections Used:**
  - `reviews` - Store all reviews
  - `courses` - Associate with courses
- **Actions:**
  - Approve review
  - Reject review
  - Delete review
  - Reply to review

---

### 9. **Settings** (`admin_settings_screen.dart`)
**Route:** `/admin_settings`
**Icon:** Settings
- **Features:**
  - Platform settings configuration
  - Enable/Disable features
  - Configure email templates
  - Manage system notifications
  - Set commission rates (for mentors)
  - Configure API keys
  - Manage system parameters
- **Firebase Collections Used:**
  - `settings` - System configuration
- **Actions:**
  - Update settings
  - Save configuration
  - Reset to defaults

---

### 10. **Admin Profile** (`admin_profile_screen.dart`)
**Route:** `/admin_profile`
**Icon:** Person
- **Features:**
  - View admin profile
  - Edit admin information
  - Change password
  - View login history
  - Manage API tokens
- **Firebase Collections Used:**
  - `users` - Admin user data
  - `authSessions` - Login history
- **Actions:**
  - Update profile
  - Change password
  - View security log

---

## 🔄 Complete Navigation Flow

```
Login Page
    ↓
Admin Dashboard (Home)
    ├── Users Management
    │   ├── View/Edit Users
    │   └── Delete Users
    ├── User Approvals
    │   ├── Approve Users
    │   └── Reject Users
    ├── Staff Invites
    │   ├── Send Invites
    │   └── Track Status
    ├── Courses Management
    │   ├── Create Course
    │   ├── Edit Course
    │   └── Delete Course
    ├── Content Upload
    │   ├── Upload Videos
    │   └── Manage Materials
    ├── Analytics
    │   ├── View Statistics
    │   └── Export Reports
    ├── Reviews
    │   ├── Approve Reviews
    │   └── Manage Responses
    ├── Settings
    │   └── Configure Platform
    ├── Profile
    │   ├── Edit Profile
    │   └── Change Password
    └── Logout
```

---

## 📱 Responsive Design

All admin pages support:
- **Desktop (>900px):** Sidebar + Main Content
- **Tablet (700px-900px):** Drawer + Main Content
- **Mobile (<700px):** Bottom Navigation + Content

---

## 🔐 Role-Based Access Control

```dart
// Admin Shell checks user role automatically
- Only users with role: 'admin' can access admin panel
- Non-admin users are redirected to student dashboard
- Session validation on app startup
```

---

## 🚀 Firebase Integration Points

### Collections Used:
1. **users** - User accounts and profiles
2. **students** - Student-specific data
3. **staff** - Staff member information
4. **courses** - Course catalog
5. **enrollments** - User course enrollments
6. **reviews** - Course reviews
7. **progress** - User learning progress
8. **settings** - System configuration
9. **authSessions** - Login history
10. **activityLogs** - Admin action logs
11. **invites** - Staff invitation tracking

### Real-time Updates:
- Dashboard updates in real-time using StreamBuilder
- User list refreshes automatically
- Course data syncs with database
- Analytics update on enrollment changes

---

## 🔘 Quick Action Buttons

From Dashboard:
- **Add Course** → Routes to Content Upload
- **Add Staff** → Routes to User Management
- **View Reports** → Routes to Analytics

---

## 📊 Data Flow Example

```dart
// Dashboard KPI Cards - Real-time
StreamBuilder<QuerySnapshot>(
  stream: _firestore.collection('users').snapshots(),
  builder: (context, snapshot) {
    final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
    return _buildKPICard('Total Users', '$count', Icons.people, Colors.blue);
  },
)

// Navigation on Tap
onTap: () {
  GoRouter.of(context).go(AppRoutes.adminUsers);
}
```

---

## 🛡️ Security Features

- Role verification on page load
- Session management
- Activity logging
- Confirmation dialogs for destructive actions
- Input validation
- Error handling with user feedback

---

## 📝 Implementation Checklist

- [x] Dashboard with real-time statistics
- [x] Users Management page
- [x] User Approvals workflow
- [x] Staff Invites system
- [x] Courses Management
- [x] Content Upload interface
- [x] Analytics dashboard
- [x] Reviews management
- [x] System Settings
- [x] Admin Profile page
- [x] Logout functionality
- [x] Responsive design
- [x] Firebase integration
- [x] Navigation routing
- [x] Error handling

---

## 🔗 Route Constants (app_routes.dart)

```dart
static const String adminDashboard = '/admin_dashboard';
static const String adminUsers = '/admin_users';
static const String adminApprovals = '/admin_approvals';
static const String adminStaffInvites = '/admin_staff_invites';
static const String adminCourses = '/admin_courses';
static const String adminUpload = '/admin_upload';
static const String adminAnalytics = '/admin_analytics';
static const String adminManageReviews = '/admin_manage_reviews';
static const String adminSettings = '/admin_settings';
static const String adminProfile = '/admin_profile';
```

---

## 📞 Support & Maintenance

All pages are designed to be maintainable and extensible. To add new features:
1. Create the feature page in `lib/views/screens/admin/`
2. Add route in `app_routes.dart`
3. Add navigation in `admin_routes.dart` sidebar
4. Implement Firebase collection integration
5. Add unit tests

---

## 🎯 Performance Optimization

- StreamBuilder for real-time updates
- Pagination for large lists
- Lazy loading of data
- Caching where applicable
- Efficient Firestore queries with limits
- Index optimization for searches

---

Last Updated: May 2, 2026
