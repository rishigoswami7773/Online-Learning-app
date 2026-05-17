import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreSetup {
  FirestoreSetup._();

  /// Ensures the required collections and at-least-one-document exist.
  /// This is safe to run on app startup in development or as a lightweight
  /// migration step. It will not overwrite existing documents.
  static Future<void> ensureCollections() async {
    final fs = FirebaseFirestore.instance;

    try {
      // Create a primary admin user if users collection is empty.
      DocumentReference? adminUserRef;
      final usersSnap = await fs.collection('users').limit(1).get();
      if (usersSnap.docs.isEmpty) {
        adminUserRef = await fs.collection('users').add({
          'name': 'Super Admin',
          'email': 'admin@local.test',
          'phone': '',
          'role': 'admin',
          'photoURL': '',
          'authProvider': 'password',
          'isPhoneVerified': false,
          'isEmailVerified': true,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      } else {
        adminUserRef = usersSnap.docs.first.reference;
      }

      // Ensure there is at least one student profile (students collection)
      final studentsSnap = await fs.collection('students').limit(1).get();
      if (studentsSnap.docs.isEmpty) {
        await fs.collection('students').add({
          'userId': '',
          'dob': '',
          'gender': '',
          'educationLevel': '',
          'classYear': '',
          'stream': '',
          'learningGoals': [],
          'preferences': {},
          'location': {'city': '', 'state': '', 'country': ''},
          'enrolledCourses': [],
        });
      }

      // Ensure there is at least one mentor user and mentor profile
      DocumentReference? mentorUserRef;
      final mentorSnap = await fs.collection('mentors').limit(1).get();
      if (mentorSnap.docs.isEmpty) {
        // Create a corresponding user for the mentor if none exists
        final mentorUsersSnap = await fs
            .collection('users')
            .where('role', isEqualTo: 'mentor')
            .limit(1)
            .get();
        if (mentorUsersSnap.docs.isEmpty) {
          mentorUserRef = await fs.collection('users').add({
            'name': 'Sample Mentor',
            'email': 'mentor@local.test',
            'phone': '',
            'role': 'mentor',
            'photoURL': '',
            'authProvider': 'google',
            'isPhoneVerified': false,
            'isEmailVerified': false,
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        } else {
          mentorUserRef = mentorUsersSnap.docs.first.reference;
        }

        await fs.collection('mentors').add({
          'userId': mentorUserRef.id,
          'role': 'mentor',
          'name': 'Priya Sharma',
          'email': 'priya.sharma@example.com',
          'phone': '+91 98765 43210',
          'department': 'Engineering',
          'specialization': 'Flutter',
          'designation': 'Senior Flutter Mentor',
          'experience': 6,
          'qualification': 'MSc Computer Science',
          'bio':
              'Helping learners build real-world Flutter apps with Firebase.',
          'photoURL': '',
          'employmentType': 'Full-time',
          'gender': 'Female',
          'isBlocked': false,
          'assignedCourses': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Admins collection (permissions map)
      final adminsSnap = await fs.collection('admins').limit(1).get();
      if (adminsSnap.docs.isEmpty) {
        await fs.collection('admins').add({
          'userId': adminUserRef.id,
          'permissions': {
            'users:manage': true,
            'courses:manage': true,
            'settings:manage': true,
          },
          'roleLevel': 'superadmin',
          'lastAccess': FieldValue.serverTimestamp(),
        });
      }

      // Courses collection - create a sample course and add a videos subcollection
      DocumentReference? sampleCourseRef;
      final coursesSnap = await fs.collection('courses').limit(1).get();
      if (coursesSnap.docs.isEmpty) {
        sampleCourseRef = await fs.collection('courses').add({
          'title': 'Flutter Development Bootcamp',
          'description':
              'A practical, project-based path to mastering Flutter and Firebase.',
          'category': 'General',
          'level': 'Beginner',
          'language': 'English',
          'thumbnailURL': '',
          'mentorId': mentorUserRef?.id ?? adminUserRef.id,
          'instructor': 'Priya Sharma',
          'price': 4999,
          'averageRating': 4.8,
          'reviewCount': 24,
          'enrollmentCount': 148,
          'status': 'active',
          'syllabus': [
            'Dart fundamentals',
            'Widget tree and layouts',
            'State management with streams',
            'Firestore integration',
            'Authentication and navigation',
          ],
          'createdBy': mentorUserRef?.id ?? adminUserRef.id,
          'isPublished': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // add a videos subcollection under the new course
        await sampleCourseRef.collection('videos').add({
          'title': 'Intro Video',
          'videoURL': '',
          'duration': 0,
          'orderIndex': 0,
          'isFree': true,
          'uploadedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // If courses exist, ensure at least one course has a videos subcollection entry
        final existingCourse = coursesSnap.docs.first.reference;
        final vids = await existingCourse.collection('videos').limit(1).get();
        if (vids.docs.isEmpty) {
          await existingCourse.collection('videos').add({
            'title': 'Intro Video',
            'videoURL': '',
            'duration': 0,
            'orderIndex': 0,
            'isFree': true,
            'uploadedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      final materialsSnap = await fs
          .collection('course_materials')
          .limit(1)
          .get();
      if (materialsSnap.docs.isEmpty && sampleCourseRef != null) {
        await fs.collection('course_materials').add({
          'courseId': sampleCourseRef.id,
          'mentorId': mentorUserRef?.id ?? adminUserRef.id,
          'title': 'Getting Started Guide',
          'description': 'Installation, setup, and first app walkthrough.',
          'resourceUrl': 'https://example.com/flutter-guide',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Enrollments
      final enrollSnap = await fs.collection('enrollments').limit(1).get();
      if (enrollSnap.docs.isEmpty) {
        await fs.collection('enrollments').add({
          'userId': adminUserRef.id,
          'courseId': sampleCourseRef?.id ?? '',
          'mentorId': mentorUserRef?.id ?? adminUserRef.id,
          'studentId': adminUserRef.id,
          'courseTitle': 'Flutter Development Bootcamp',
          'progressPercent': 42,
          'lessonsCompleted': 4,
          'totalLessons': 12,
          'progress': 0,
          'completedLessons': [],
          'enrolledAt': FieldValue.serverTimestamp(),
          'status': 'active',
        });
      }

      // Progress
      final progSnap = await fs.collection('progress').limit(1).get();
      if (progSnap.docs.isEmpty) {
        await fs.collection('progress').add({
          'userId': '',
          'courseId': sampleCourseRef?.id,
          'videoId': null,
          'watchTime': 0,
          'completed': false,
          'lastWatchedAt': FieldValue.serverTimestamp(),
        });
      }

      // Wishlist
      final wishSnap = await fs.collection('wishlist').limit(1).get();
      if (wishSnap.docs.isEmpty) {
        await fs.collection('wishlist').add({
          'userId': '',
          'courseId': sampleCourseRef?.id,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      // Notifications
      final notSnap = await fs.collection('notifications').limit(1).get();
      if (notSnap.docs.isEmpty) {
        await fs.collection('notifications').add({
          'userId': 'all',
          'title': 'Welcome',
          'message': 'Welcome to the platform',
          'type': 'system',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Reviews
      final revSnap = await fs.collection('course_reviews').limit(1).get();
      if (revSnap.docs.isEmpty) {
        await fs.collection('course_reviews').add({
          'userId': adminUserRef.id,
          'courseId': sampleCourseRef?.id,
          'reviewerName': 'Aarav Mehta',
          'rating': 5,
          'reviewText': 'Excellent practical explanations and projects.',
          'comment': 'Excellent practical explanations and projects.',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Activity Logs
      final actSnap = await fs.collection('activityLogs').limit(1).get();
      if (actSnap.docs.isEmpty) {
        await fs.collection('activityLogs').add({
          'userId': adminUserRef.id,
          'action': 'create',
          'target': 'system:init',
          'details': 'Initialized collections',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Auth Sessions
      final authSnap = await fs.collection('authSessions').limit(1).get();
      if (authSnap.docs.isEmpty) {
        await fs.collection('authSessions').add({
          'userId': adminUserRef.id,
          'deviceInfo': {'platform': 'dev', 'device': 'initializer'},
          'loginTime': FieldValue.serverTimestamp(),
          'active': false,
        });
      }

      // Modules (course subcollection)
      if (sampleCourseRef != null) {
        final modulesSnap = await sampleCourseRef
            .collection('modules')
            .limit(1)
            .get();
        if (modulesSnap.docs.isEmpty) {
          final moduleRef = await sampleCourseRef.collection('modules').add({
            'title': 'Introduction to Flutter',
            'order': 1,
            'description': 'Learn the basics of Flutter development',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Add lessons under this module
          await moduleRef.collection('lessons').add({
            'title': 'What is Flutter?',
            'type': 'video',
            'contentUrl': 'https://example.com/flutter-intro.mp4',
            'order': 1,
            'duration': 15,
            'description': 'Introduction to Flutter framework',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Quizzes
      final quizzesSnap = await fs.collection('quizzes').limit(1).get();
      if (quizzesSnap.docs.isEmpty && sampleCourseRef != null) {
        final quizRef = await fs.collection('quizzes').add({
          'title': 'Flutter Basics Quiz',
          'courseId': sampleCourseRef.id,
          'moduleId': 'sample-module-1',
          'passingScore': 70.0,
          'description': 'Test your Flutter knowledge',
          'maxAttempts': 3,
          'timeLimit': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Add questions to quiz
        final questionRef = await quizRef.collection('questions').add({
          'text': 'What is Flutter?',
          'order': 1,
          'explanation': 'Flutter is an open-source UI framework by Google',
          'quizId': quizRef.id,
        });

        // Add options to question
        await questionRef.collection('options').add({
          'text': 'A mobile UI framework by Google',
          'isCorrect': true,
          'questionId': questionRef.id,
        });
        await questionRef.collection('options').add({
          'text': 'A web browser',
          'isCorrect': false,
          'questionId': questionRef.id,
        });
      }

      // Assignments
      final assignmentsSnap = await fs.collection('assignments').limit(1).get();
      if (assignmentsSnap.docs.isEmpty && sampleCourseRef != null) {
        await fs.collection('assignments').add({
          'title': 'Build Your First App',
          'courseId': sampleCourseRef.id,
          'moduleId': 'sample-module-1',
          'description': 'Create a simple Flutter counter app',
          'dueDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 7)),
          ),
          'maxScore': 100,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Settings (system document) - follow schema settings/system
      final settingsRef = fs.collection('settings').doc('system');
      final settingsDoc = await settingsRef.get();
      if (!settingsDoc.exists) {
        await settingsRef.set({
          'maintenanceMode': false,
          'appVersion': '1.0.0',
          'supportEmail': 'support@example.com',
          'systemStatus': 'ok',
          'featureFlags': {},
        });
      }
    } catch (e) {
      // Do not crash the app if this runs in production; just log.
      // In development you can inspect logs to confirm collections were created.
      // ignore: avoid_print
      print('FirestoreSetup.ensureCollections failed: $e');
    }
  }
}
