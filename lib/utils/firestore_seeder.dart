import 'package:cloud_firestore/cloud_firestore.dart';

/// Seeds Firestore with realistic Indian demo data.
/// Run once from the admin panel. Safe to run multiple times (uses named IDs).
class FirestoreSeeder {
  static final _db = FirebaseFirestore.instance;

  // ── Fixed IDs so re-runs stay idempotent ──────────────────────────────────
  static const _mentorId1 = 'mentor_rahul_sharma';
  static const _mentorId2 = 'mentor_priya_patel';
  static const _studentId1 = 'student_aarav_mehta';
  static const _studentId2 = 'student_sneha_iyer';
  static const _studentId3 = 'student_rohan_das';
  static const _studentId4 = 'student_pooja_rao';
  static const _adminId = 'admin_vikram_admin';

  static Future<String> seed() async {
    final log = StringBuffer();
    try {
      await _seedCategories(log);
      await _seedUsers(log);
      await _seedCourses(log);
      await _seedEnrollments(log);
      await _seedReviews(log);
      await _seedNotifications(log);
      await _seedConversations(log);
      log.writeln('\nSeeding complete ✅');
    } catch (e, st) {
      log.writeln('Error: $e\n$st');
    }
    return log.toString();
  }

  // ── Categories ─────────────────────────────────────────────────────────────
  static Future<void> _seedCategories(StringBuffer log) async {
    final categories = [
      'Flutter Development',
      'Web Development',
      'Data Science',
      'UI/UX Design',
      'Python',
      'Machine Learning',
      'Android Development',
      'DevOps',
    ];
    final batch = _db.batch();
    for (final cat in categories) {
      final ref = _db
          .collection('categories')
          .doc(cat.replaceAll(' ', '_').replaceAll('/', '_').toLowerCase());
      batch.set(ref, {'name': cat}, SetOptions(merge: true));
    }
    await batch.commit();
    log.writeln('✔ Seeded ${categories.length} categories.');
  }

  // ── Users ──────────────────────────────────────────────────────────────────
  static Future<void> _seedUsers(StringBuffer log) async {
    final now = FieldValue.serverTimestamp();
    final users = <String, Map<String, dynamic>>{
      _mentorId1: {
        'uid': _mentorId1,
        'name': 'Rahul Sharma',
        'email': 'rahul.sharma@learnhub.in',
        'role': 'mentor',
        'status': 'active',
        'isVerified': true,
        'bio':
            'Senior Flutter developer with 8 years of experience building production apps.',
        'department': 'Engineering',
        'designation': 'Senior Engineer',
        'photoURL': '',
        'createdAt': now,
      },
      _mentorId2: {
        'uid': _mentorId2,
        'name': 'Priya Patel',
        'email': 'priya.patel@learnhub.in',
        'role': 'mentor',
        'status': 'active',
        'isVerified': true,
        'bio':
            'Full-stack developer specialising in MERN stack and cloud deployments.',
        'department': 'Engineering',
        'designation': 'Lead Developer',
        'photoURL': '',
        'createdAt': now,
      },
      _studentId1: {
        'uid': _studentId1,
        'name': 'Aarav Mehta',
        'email': 'aarav.mehta@student.in',
        'role': 'student',
        'status': 'active',
        'isVerified': true,
        'photoURL': '',
        'createdAt': now,
      },
      _studentId2: {
        'uid': _studentId2,
        'name': 'Sneha Iyer',
        'email': 'sneha.iyer@student.in',
        'role': 'student',
        'status': 'active',
        'isVerified': true,
        'photoURL': '',
        'createdAt': now,
      },
      _studentId3: {
        'uid': _studentId3,
        'name': 'Rohan Das',
        'email': 'rohan.das@student.in',
        'role': 'student',
        'status': 'active',
        'isVerified': true,
        'photoURL': '',
        'createdAt': now,
      },
      _studentId4: {
        'uid': _studentId4,
        'name': 'Pooja Rao',
        'email': 'pooja.rao@student.in',
        'role': 'student',
        'status': 'active',
        'isVerified': true,
        'photoURL': '',
        'createdAt': now,
      },
      _adminId: {
        'uid': _adminId,
        'name': 'Vikram Admin',
        'email': 'admin@learnhub.in',
        'role': 'admin',
        'status': 'active',
        'isVerified': true,
        'photoURL': '',
        'createdAt': now,
      },
    };

    final batch = _db.batch();
    for (final entry in users.entries) {
      batch.set(
        _db.collection('users').doc(entry.key),
        entry.value,
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    log.writeln('✔ Seeded ${users.length} users.');
  }

  // ── Courses + lessons subcollection ────────────────────────────────────────
  static Future<void> _seedCourses(StringBuffer log) async {
    final now = FieldValue.serverTimestamp();

    final courses = <Map<String, dynamic>>[
      {
        'id': 'course_flutter_bootcamp',
        'title': 'Flutter Bootcamp: Build 10 Real Apps',
        'description':
            'Master Flutter and Dart from scratch. Build 10 production-quality apps including e-commerce, chat, and social media apps. Includes Firebase, state management, and deployment.',
        'category': 'Flutter Development',
        'instructor': 'Rahul Sharma',
        'mentorId': _mentorId1,
        'price': 1299.0,
        'currency': '₹',
        'priceDisplay': '₹1299',
        'durationHours': 42.0,
        'totalLessons': 8,
        'thumbnailUrl': '',
        'videoUrl': '',
        'averageRating': 4.7,
        'reviewCount': 3,
        'enrollmentCount': 3,
        'status': 'active',
        'isPublished': true,
        'syllabus': [
          'Dart Fundamentals',
          'Flutter Widgets Deep Dive',
          'State Management with Provider',
          'Firebase Integration',
          'Building a Chat App',
          'Building an E-Commerce App',
          'Animations and Custom Painting',
          'Deployment to Play Store',
        ],
        'lessons': [
          {'title': 'Dart Fundamentals', 'durationMinutes': 45, 'order': 1},
          {
            'title': 'Flutter Widgets Deep Dive',
            'durationMinutes': 60,
            'order': 2,
          },
          {
            'title': 'State Management with Provider',
            'durationMinutes': 55,
            'order': 3,
          },
          {'title': 'Firebase Integration', 'durationMinutes': 70, 'order': 4},
          {'title': 'Building a Chat App', 'durationMinutes': 90, 'order': 5},
          {
            'title': 'Building an E-Commerce App',
            'durationMinutes': 120,
            'order': 6,
          },
          {
            'title': 'Animations and Custom Painting',
            'durationMinutes': 60,
            'order': 7,
          },
          {
            'title': 'Deployment to Play Store',
            'durationMinutes': 40,
            'order': 8,
          },
        ],
      },
      {
        'id': 'course_mern_stack',
        'title': 'MERN Stack Web Development',
        'description':
            'Complete guide to building full-stack web applications using MongoDB, Express.js, React, and Node.js. Covers REST APIs, JWT auth, and AWS deployment.',
        'category': 'Web Development',
        'instructor': 'Priya Patel',
        'mentorId': _mentorId2,
        'price': 999.0,
        'currency': '₹',
        'priceDisplay': '₹999',
        'durationHours': 36.0,
        'totalLessons': 8,
        'thumbnailUrl': '',
        'videoUrl': '',
        'averageRating': 4.5,
        'reviewCount': 2,
        'enrollmentCount': 2,
        'status': 'active',
        'isPublished': true,
        'syllabus': [
          'HTML, CSS & JavaScript Refresh',
          'React.js Fundamentals',
          'Node.js & Express',
          'MongoDB & Mongoose',
          'REST API Design',
          'Authentication with JWT',
          'Redux State Management',
          'Deployment on AWS EC2',
        ],
        'lessons': [
          {
            'title': 'HTML, CSS & JavaScript Refresh',
            'durationMinutes': 50,
            'order': 1,
          },
          {'title': 'React.js Fundamentals', 'durationMinutes': 75, 'order': 2},
          {'title': 'Node.js & Express', 'durationMinutes': 65, 'order': 3},
          {'title': 'MongoDB & Mongoose', 'durationMinutes': 55, 'order': 4},
          {'title': 'REST API Design', 'durationMinutes': 60, 'order': 5},
          {
            'title': 'Authentication with JWT',
            'durationMinutes': 50,
            'order': 6,
          },
          {
            'title': 'Redux State Management',
            'durationMinutes': 70,
            'order': 7,
          },
          {'title': 'Deployment on AWS EC2', 'durationMinutes': 45, 'order': 8},
        ],
      },
      {
        'id': 'course_data_science_python',
        'title': 'Data Science with Python — From Zero to Hero',
        'description':
            'Learn data analysis, visualization, and machine learning with Python. Covers NumPy, Pandas, Matplotlib, and Scikit-learn with real Indian market datasets.',
        'category': 'Data Science',
        'instructor': 'Rahul Sharma',
        'mentorId': _mentorId1,
        'price': 1499.0,
        'currency': '₹',
        'priceDisplay': '₹1499',
        'durationHours': 50.0,
        'totalLessons': 8,
        'thumbnailUrl': '',
        'videoUrl': '',
        'averageRating': 4.8,
        'reviewCount': 3,
        'enrollmentCount': 3,
        'status': 'active',
        'isPublished': true,
        'syllabus': [
          'Python for Data Science',
          'NumPy Arrays & Operations',
          'Pandas DataFrames',
          'Data Cleaning & Wrangling',
          'Matplotlib & Seaborn Visualization',
          'Statistical Analysis',
          'Machine Learning with Scikit-learn',
          'Capstone: Stock Market Analysis',
        ],
        'lessons': [
          {
            'title': 'Python for Data Science',
            'durationMinutes': 50,
            'order': 1,
          },
          {
            'title': 'NumPy Arrays & Operations',
            'durationMinutes': 45,
            'order': 2,
          },
          {'title': 'Pandas DataFrames', 'durationMinutes': 55, 'order': 3},
          {
            'title': 'Data Cleaning & Wrangling',
            'durationMinutes': 60,
            'order': 4,
          },
          {
            'title': 'Matplotlib & Seaborn Visualization',
            'durationMinutes': 50,
            'order': 5,
          },
          {'title': 'Statistical Analysis', 'durationMinutes': 65, 'order': 6},
          {
            'title': 'Machine Learning with Scikit-learn',
            'durationMinutes': 80,
            'order': 7,
          },
          {
            'title': 'Capstone: Stock Market Analysis',
            'durationMinutes': 90,
            'order': 8,
          },
        ],
      },
      {
        'id': 'course_ui_ux',
        'title': 'UI/UX Design: From Wireframe to Prototype',
        'description':
            'Master modern UI/UX design principles using Figma. Learn user research, wireframing, prototyping, and design systems. Build a portfolio with 5 real projects.',
        'category': 'UI/UX Design',
        'instructor': 'Priya Patel',
        'mentorId': _mentorId2,
        'price': 799.0,
        'currency': '₹',
        'priceDisplay': '₹799',
        'durationHours': 28.0,
        'totalLessons': 8,
        'thumbnailUrl': '',
        'videoUrl': '',
        'averageRating': 4.6,
        'reviewCount': 2,
        'enrollmentCount': 2,
        'status': 'active',
        'isPublished': true,
        'syllabus': [
          'Design Thinking & User Research',
          'Figma Fundamentals',
          'Wireframing & Lo-fi Prototypes',
          'Design Systems & Components',
          'Hi-fi Prototyping',
          'Usability Testing',
          'Portfolio Project 1: Food Delivery App',
          'Portfolio Project 2: EdTech Dashboard',
        ],
        'lessons': [
          {
            'title': 'Design Thinking & User Research',
            'durationMinutes': 40,
            'order': 1,
          },
          {'title': 'Figma Fundamentals', 'durationMinutes': 55, 'order': 2},
          {
            'title': 'Wireframing & Lo-fi Prototypes',
            'durationMinutes': 50,
            'order': 3,
          },
          {
            'title': 'Design Systems & Components',
            'durationMinutes': 60,
            'order': 4,
          },
          {'title': 'Hi-fi Prototyping', 'durationMinutes': 65, 'order': 5},
          {'title': 'Usability Testing', 'durationMinutes': 45, 'order': 6},
          {
            'title': 'Portfolio Project 1: Food Delivery App',
            'durationMinutes': 70,
            'order': 7,
          },
          {
            'title': 'Portfolio Project 2: EdTech Dashboard',
            'durationMinutes': 75,
            'order': 8,
          },
        ],
      },
      {
        'id': 'course_android_kotlin',
        'title': 'Android Development with Kotlin',
        'description':
            'Build professional Android apps using Kotlin and Jetpack Compose. Covers MVVM architecture, Room database, Retrofit, and Google Play publishing.',
        'category': 'Android Development',
        'instructor': 'Rahul Sharma',
        'mentorId': _mentorId1,
        'price': 1199.0,
        'currency': '₹',
        'priceDisplay': '₹1199',
        'durationHours': 38.0,
        'totalLessons': 8,
        'thumbnailUrl': '',
        'videoUrl': '',
        'averageRating': 4.4,
        'reviewCount': 2,
        'enrollmentCount': 2,
        'status': 'active',
        'isPublished': true,
        'syllabus': [
          'Kotlin Fundamentals',
          'Android Studio Setup',
          'Jetpack Compose Basics',
          'Navigation Component',
          'MVVM Architecture',
          'Room Database',
          'Retrofit & REST APIs',
          'Publishing to Play Store',
        ],
        'lessons': [
          {'title': 'Kotlin Fundamentals', 'durationMinutes': 55, 'order': 1},
          {'title': 'Android Studio Setup', 'durationMinutes': 30, 'order': 2},
          {
            'title': 'Jetpack Compose Basics',
            'durationMinutes': 70,
            'order': 3,
          },
          {'title': 'Navigation Component', 'durationMinutes': 50, 'order': 4},
          {'title': 'MVVM Architecture', 'durationMinutes': 65, 'order': 5},
          {'title': 'Room Database', 'durationMinutes': 55, 'order': 6},
          {'title': 'Retrofit & REST APIs', 'durationMinutes': 60, 'order': 7},
          {
            'title': 'Publishing to Play Store',
            'durationMinutes': 40,
            'order': 8,
          },
        ],
      },
      {
        'id': 'course_ml_tensorflow',
        'title': 'Machine Learning with TensorFlow & Keras',
        'description':
            'Deep dive into machine learning using Python, TensorFlow, and Keras. Build neural networks for image classification, NLP, and time series prediction.',
        'category': 'Machine Learning',
        'instructor': 'Priya Patel',
        'mentorId': _mentorId2,
        'price': 1799.0,
        'currency': '₹',
        'priceDisplay': '₹1799',
        'durationHours': 55.0,
        'totalLessons': 8,
        'thumbnailUrl': '',
        'videoUrl': '',
        'averageRating': 4.9,
        'reviewCount': 2,
        'enrollmentCount': 2,
        'status': 'active',
        'isPublished': true,
        'syllabus': [
          'ML Fundamentals & Math Review',
          'Python for ML',
          'Supervised Learning Algorithms',
          'Neural Networks from Scratch',
          'TensorFlow & Keras Basics',
          'Convolutional Neural Networks',
          'Natural Language Processing',
          'Capstone: Image Classifier',
        ],
        'lessons': [
          {
            'title': 'ML Fundamentals & Math Review',
            'durationMinutes': 60,
            'order': 1,
          },
          {'title': 'Python for ML', 'durationMinutes': 50, 'order': 2},
          {
            'title': 'Supervised Learning Algorithms',
            'durationMinutes': 70,
            'order': 3,
          },
          {
            'title': 'Neural Networks from Scratch',
            'durationMinutes': 80,
            'order': 4,
          },
          {
            'title': 'TensorFlow & Keras Basics',
            'durationMinutes': 65,
            'order': 5,
          },
          {
            'title': 'Convolutional Neural Networks',
            'durationMinutes': 75,
            'order': 6,
          },
          {
            'title': 'Natural Language Processing',
            'durationMinutes': 80,
            'order': 7,
          },
          {
            'title': 'Capstone: Image Classifier',
            'durationMinutes': 90,
            'order': 8,
          },
        ],
      },
    ];

    for (final course in courses) {
      final id = course['id'] as String;
      final lessons = course['lessons'] as List<Map<String, dynamic>>;
      final data = Map<String, dynamic>.from(course)
        ..remove('id')
        ..remove('lessons')
        ..['createdAt'] = now
        ..['updatedAt'] = now;

      // Write course doc
      await _db
          .collection('courses')
          .doc(id)
          .set(data, SetOptions(merge: true));

      // Write lessons subcollection
      final lessonBatch = _db.batch();
      for (final lesson in lessons) {
        final lessonRef = _db
            .collection('courses')
            .doc(id)
            .collection('lessons')
            .doc('lesson_${lesson['order']}');
        lessonBatch.set(lessonRef, {
          ...lesson,
          'courseId': id,
          'videoUrl': '',
          'isPreview': lesson['order'] == 1,
          'createdAt': now,
        }, SetOptions(merge: true));
      }
      await lessonBatch.commit();
    }
    log.writeln(
      '✔ Seeded ${courses.length} courses with lessons subcollections.',
    );
  }

  // ── Enrollments ────────────────────────────────────────────────────────────
  static Future<void> _seedEnrollments(StringBuffer log) async {
    final now = FieldValue.serverTimestamp();

    // student → [courseId, completedLessons, progress]
    final enrollments = [
      {
        'id': 'enroll_aarav_flutter',
        'studentId': _studentId1,
        'studentName': 'Aarav Mehta',
        'courseId': 'course_flutter_bootcamp',
        'courseTitle': 'Flutter Bootcamp: Build 10 Real Apps',
        'completedLessons': 5,
        'totalLessons': 8,
        'progressPercent': 62.5,
        'isCompleted': false,
      },
      {
        'id': 'enroll_aarav_data',
        'studentId': _studentId1,
        'studentName': 'Aarav Mehta',
        'courseId': 'course_data_science_python',
        'courseTitle': 'Data Science with Python — From Zero to Hero',
        'completedLessons': 8,
        'totalLessons': 8,
        'progressPercent': 100.0,
        'isCompleted': true,
      },
      {
        'id': 'enroll_sneha_mern',
        'studentId': _studentId2,
        'studentName': 'Sneha Iyer',
        'courseId': 'course_mern_stack',
        'courseTitle': 'MERN Stack Web Development',
        'completedLessons': 3,
        'totalLessons': 8,
        'progressPercent': 37.5,
        'isCompleted': false,
      },
      {
        'id': 'enroll_sneha_ui',
        'studentId': _studentId2,
        'studentName': 'Sneha Iyer',
        'courseId': 'course_ui_ux',
        'courseTitle': 'UI/UX Design: From Wireframe to Prototype',
        'completedLessons': 8,
        'totalLessons': 8,
        'progressPercent': 100.0,
        'isCompleted': true,
      },
      {
        'id': 'enroll_rohan_android',
        'studentId': _studentId3,
        'studentName': 'Rohan Das',
        'courseId': 'course_android_kotlin',
        'courseTitle': 'Android Development with Kotlin',
        'completedLessons': 2,
        'totalLessons': 8,
        'progressPercent': 25.0,
        'isCompleted': false,
      },
      {
        'id': 'enroll_rohan_flutter',
        'studentId': _studentId3,
        'studentName': 'Rohan Das',
        'courseId': 'course_flutter_bootcamp',
        'courseTitle': 'Flutter Bootcamp: Build 10 Real Apps',
        'completedLessons': 0,
        'totalLessons': 8,
        'progressPercent': 0.0,
        'isCompleted': false,
      },
      {
        'id': 'enroll_pooja_ml',
        'studentId': _studentId4,
        'studentName': 'Pooja Rao',
        'courseId': 'course_ml_tensorflow',
        'courseTitle': 'Machine Learning with TensorFlow & Keras',
        'completedLessons': 6,
        'totalLessons': 8,
        'progressPercent': 75.0,
        'isCompleted': false,
      },
      {
        'id': 'enroll_pooja_data',
        'studentId': _studentId4,
        'studentName': 'Pooja Rao',
        'courseId': 'course_data_science_python',
        'courseTitle': 'Data Science with Python — From Zero to Hero',
        'completedLessons': 4,
        'totalLessons': 8,
        'progressPercent': 50.0,
        'isCompleted': false,
      },
      {
        'id': 'enroll_sneha_ml',
        'studentId': _studentId2,
        'studentName': 'Sneha Iyer',
        'courseId': 'course_ml_tensorflow',
        'courseTitle': 'Machine Learning with TensorFlow & Keras',
        'completedLessons': 8,
        'totalLessons': 8,
        'progressPercent': 100.0,
        'isCompleted': true,
      },
      {
        'id': 'enroll_aarav_android',
        'studentId': _studentId1,
        'studentName': 'Aarav Mehta',
        'courseId': 'course_android_kotlin',
        'courseTitle': 'Android Development with Kotlin',
        'completedLessons': 0,
        'totalLessons': 8,
        'progressPercent': 0.0,
        'isCompleted': false,
      },
    ];

    final batch = _db.batch();
    for (final e in enrollments) {
      final id = e['id'] as String;
      final data = Map<String, dynamic>.from(e)
        ..remove('id')
        ..['enrolledAt'] = now;
      batch.set(
        _db.collection('enrollments').doc(id),
        data,
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    log.writeln('✔ Seeded ${enrollments.length} enrollments.');
  }

  // ── Reviews ────────────────────────────────────────────────────────────────
  static Future<void> _seedReviews(StringBuffer log) async {
    final now = FieldValue.serverTimestamp();

    final reviews = [
      // Flutter Bootcamp — 3 reviews
      {
        'id': 'review_flutter_aarav',
        'courseId': 'course_flutter_bootcamp',
        'courseTitle': 'Flutter Bootcamp: Build 10 Real Apps',
        'reviewerId': _studentId1,
        'reviewerName': 'Aarav Mehta',
        'rating': 5.0,
        'comment':
            'Outstanding course! The Firebase integration module alone was worth the price. Rahul explains concepts clearly.',
        'status': 'approved',
      },
      {
        'id': 'review_flutter_rohan',
        'courseId': 'course_flutter_bootcamp',
        'courseTitle': 'Flutter Bootcamp: Build 10 Real Apps',
        'reviewerId': _studentId3,
        'reviewerName': 'Rohan Das',
        'rating': 4.5,
        'comment':
            'Very detailed and well-structured. The hands-on projects helped solidify my understanding.',
        'status': 'approved',
      },
      {
        'id': 'review_flutter_sneha',
        'courseId': 'course_flutter_bootcamp',
        'courseTitle': 'Flutter Bootcamp: Build 10 Real Apps',
        'reviewerId': _studentId2,
        'reviewerName': 'Sneha Iyer',
        'rating': 4.5,
        'comment': 'Great content, especially the state management section.',
        'status': 'approved',
      },
      // MERN Stack — 2 reviews
      {
        'id': 'review_mern_sneha',
        'courseId': 'course_mern_stack',
        'courseTitle': 'MERN Stack Web Development',
        'reviewerId': _studentId2,
        'reviewerName': 'Sneha Iyer',
        'rating': 4.5,
        'comment':
            'Priya is a fantastic teacher. The JWT auth module was super helpful.',
        'status': 'approved',
      },
      {
        'id': 'review_mern_aarav',
        'courseId': 'course_mern_stack',
        'courseTitle': 'MERN Stack Web Development',
        'reviewerId': _studentId1,
        'reviewerName': 'Aarav Mehta',
        'rating': 4.5,
        'comment': 'Solid course. AWS deployment section could use more depth.',
        'status': 'approved',
      },
      // Data Science — 3 reviews
      {
        'id': 'review_ds_aarav',
        'courseId': 'course_data_science_python',
        'courseTitle': 'Data Science with Python',
        'reviewerId': _studentId1,
        'reviewerName': 'Aarav Mehta',
        'rating': 5.0,
        'comment':
            'Best data science course I have taken. The stock market capstone was real-world and engaging.',
        'status': 'approved',
      },
      {
        'id': 'review_ds_pooja',
        'courseId': 'course_data_science_python',
        'courseTitle': 'Data Science with Python',
        'reviewerId': _studentId4,
        'reviewerName': 'Pooja Rao',
        'rating': 5.0,
        'comment': 'Excellent pacing and great practical examples.',
        'status': 'approved',
      },
      {
        'id': 'review_ds_sneha',
        'courseId': 'course_data_science_python',
        'courseTitle': 'Data Science with Python',
        'reviewerId': _studentId2,
        'reviewerName': 'Sneha Iyer',
        'rating': 4.5,
        'comment': 'Very comprehensive. Pandas section is gold.',
        'status': 'approved',
      },
      // UI/UX — 2 reviews
      {
        'id': 'review_ui_sneha',
        'courseId': 'course_ui_ux',
        'courseTitle': 'UI/UX Design: From Wireframe to Prototype',
        'reviewerId': _studentId2,
        'reviewerName': 'Sneha Iyer',
        'rating': 4.5,
        'comment':
            'Transformed my design skills. Portfolio projects are really impressive.',
        'status': 'approved',
      },
      {
        'id': 'review_ui_pooja',
        'courseId': 'course_ui_ux',
        'courseTitle': 'UI/UX Design: From Wireframe to Prototype',
        'reviewerId': _studentId4,
        'reviewerName': 'Pooja Rao',
        'rating': 4.5,
        'comment': 'Great intro to Figma and design systems.',
        'status': 'approved',
      },
      // Android — 2 reviews
      {
        'id': 'review_android_rohan',
        'courseId': 'course_android_kotlin',
        'courseTitle': 'Android Development with Kotlin',
        'reviewerId': _studentId3,
        'reviewerName': 'Rohan Das',
        'rating': 4.5,
        'comment':
            'Jetpack Compose section is top-notch. MVVM made crystal clear.',
        'status': 'approved',
      },
      {
        'id': 'review_android_aarav',
        'courseId': 'course_android_kotlin',
        'courseTitle': 'Android Development with Kotlin',
        'reviewerId': _studentId1,
        'reviewerName': 'Aarav Mehta',
        'rating': 4.0,
        'comment': 'Good course. Would love more content on Coroutines.',
        'status': 'approved',
      },
      // ML — 2 reviews
      {
        'id': 'review_ml_pooja',
        'courseId': 'course_ml_tensorflow',
        'courseTitle': 'Machine Learning with TensorFlow & Keras',
        'reviewerId': _studentId4,
        'reviewerName': 'Pooja Rao',
        'rating': 5.0,
        'comment':
            'Mind-blowing content. CNNs section is incredibly well explained.',
        'status': 'approved',
      },
      {
        'id': 'review_ml_sneha',
        'courseId': 'course_ml_tensorflow',
        'courseTitle': 'Machine Learning with TensorFlow & Keras',
        'reviewerId': _studentId2,
        'reviewerName': 'Sneha Iyer',
        'rating': 4.5,
        'comment':
            'Excellent deep learning course. Best investment in my career.',
        'status': 'approved',
      },
    ];

    final batch = _db.batch();
    for (final r in reviews) {
      final id = r['id'] as String;
      final data = Map<String, dynamic>.from(r)
        ..remove('id')
        ..['createdAt'] = now;
      batch.set(
        _db.collection('course_reviews').doc(id),
        data,
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    log.writeln('✔ Seeded ${reviews.length} reviews.');
  }

  // ── Notifications ──────────────────────────────────────────────────────────
  static Future<void> _seedNotifications(StringBuffer log) async {
    final now = FieldValue.serverTimestamp();

    final notifications = [
      // Mentor 1 notifications
      {
        'id': 'notif_m1_enroll1',
        'recipientId': _mentorId1,
        'type': 'enrollment',
        'title': 'New Enrollment',
        'body': 'Aarav Mehta enrolled in Flutter Bootcamp',
        'isRead': false,
      },
      {
        'id': 'notif_m1_review1',
        'recipientId': _mentorId1,
        'type': 'review',
        'title': 'New Review',
        'body': 'Aarav Mehta left a 5★ review on Flutter Bootcamp',
        'isRead': true,
      },
      {
        'id': 'notif_m1_enroll2',
        'recipientId': _mentorId1,
        'type': 'enrollment',
        'title': 'New Enrollment',
        'body': 'Rohan Das enrolled in Flutter Bootcamp',
        'isRead': false,
      },
      // Mentor 2 notifications
      {
        'id': 'notif_m2_enroll1',
        'recipientId': _mentorId2,
        'type': 'enrollment',
        'title': 'New Enrollment',
        'body': 'Sneha Iyer enrolled in MERN Stack',
        'isRead': false,
      },
      {
        'id': 'notif_m2_review1',
        'recipientId': _mentorId2,
        'type': 'review',
        'title': 'New Review',
        'body': 'Sneha Iyer left a 4.5★ review on MERN Stack',
        'isRead': true,
      },
      {
        'id': 'notif_m2_message1',
        'recipientId': _mentorId2,
        'type': 'message',
        'title': 'New Message',
        'body': 'Pooja Rao sent you a message about ML course',
        'isRead': false,
      },
      // Student notifications
      {
        'id': 'notif_s1_welcome',
        'recipientId': _studentId1,
        'type': 'system',
        'title': 'Welcome to Learnify!',
        'body': 'Start learning with 1000+ courses from expert mentors.',
        'isRead': true,
      },
      {
        'id': 'notif_s1_enroll',
        'recipientId': _studentId1,
        'type': 'enrollment',
        'title': 'Enrollment Confirmed',
        'body': 'You are now enrolled in Flutter Bootcamp. Happy learning!',
        'isRead': true,
      },
      {
        'id': 'notif_s1_progress',
        'recipientId': _studentId1,
        'type': 'achievement',
        'title': '🎉 Course Completed!',
        'body':
            'You completed Data Science with Python. Download your certificate.',
        'isRead': false,
      },
      {
        'id': 'notif_s2_welcome',
        'recipientId': _studentId2,
        'type': 'system',
        'title': 'Welcome to Learnify!',
        'body': 'Start learning with 1000+ courses from expert mentors.',
        'isRead': true,
      },
      {
        'id': 'notif_s2_complete',
        'recipientId': _studentId2,
        'type': 'achievement',
        'title': '🎉 Course Completed!',
        'body': 'You completed UI/UX Design course. Great work!',
        'isRead': false,
      },
      {
        'id': 'notif_s2_promo',
        'recipientId': _studentId2,
        'type': 'promotion',
        'title': 'Special Offer 🎁',
        'body': 'Get 30% off on Machine Learning course this weekend.',
        'isRead': false,
      },
      {
        'id': 'notif_s3_welcome',
        'recipientId': _studentId3,
        'type': 'system',
        'title': 'Welcome to Learnify!',
        'body': 'Start learning with 1000+ courses from expert mentors.',
        'isRead': true,
      },
      {
        'id': 'notif_s3_enroll',
        'recipientId': _studentId3,
        'type': 'enrollment',
        'title': 'Enrollment Confirmed',
        'body': 'You are now enrolled in Android Development with Kotlin.',
        'isRead': true,
      },
      {
        'id': 'notif_s3_reminder',
        'recipientId': _studentId3,
        'type': 'reminder',
        'title': 'Continue Learning 📚',
        'body':
            'You have not continued Android Development in 3 days. Pick up where you left off!',
        'isRead': false,
      },
      {
        'id': 'notif_s4_welcome',
        'recipientId': _studentId4,
        'type': 'system',
        'title': 'Welcome to Learnify!',
        'body': 'Start learning with 1000+ courses from expert mentors.',
        'isRead': true,
      },
      {
        'id': 'notif_s4_enroll',
        'recipientId': _studentId4,
        'type': 'enrollment',
        'title': 'Enrollment Confirmed',
        'body': 'You are now enrolled in Machine Learning with TensorFlow.',
        'isRead': true,
      },
      {
        'id': 'notif_s4_progress',
        'recipientId': _studentId4,
        'type': 'achievement',
        'title': '🏆 75% Complete!',
        'body': 'You are 75% through Machine Learning. Almost there!',
        'isRead': false,
      },
    ];

    final batch = _db.batch();
    for (final n in notifications) {
      final id = n['id'] as String;
      final data = Map<String, dynamic>.from(n)
        ..remove('id')
        ..['createdAt'] = now;
      batch.set(
        _db.collection('notifications').doc(id),
        data,
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    log.writeln('✔ Seeded ${notifications.length} notifications.');
  }

  // ── Conversations + messages ───────────────────────────────────────────────
  static Future<void> _seedConversations(StringBuffer log) async {
    final now = FieldValue.serverTimestamp();

    final conversations = [
      {
        'id': 'conv_aarav_rahul',
        'mentorId': _mentorId1,
        'mentorName': 'Rahul Sharma',
        'studentId': _studentId1,
        'studentName': 'Aarav Mehta',
        'lastMessage': 'Thank you for the explanation on Provider!',
        'messages': [
          {
            'id': 'msg_ar_1',
            'fromId': _studentId1,
            'toId': _mentorId1,
            'text':
                'Hi Rahul, I am having trouble understanding Provider state management.',
          },
          {
            'id': 'msg_ar_2',
            'fromId': _mentorId1,
            'toId': _studentId1,
            'text':
                'Sure Aarav! Provider is essentially an InheritedWidget wrapper. Think of it as a way to lift state up to the widget tree.',
          },
          {
            'id': 'msg_ar_3',
            'fromId': _studentId1,
            'toId': _mentorId1,
            'text': 'Thank you for the explanation on Provider!',
          },
        ],
      },
      {
        'id': 'conv_rohan_rahul',
        'mentorId': _mentorId1,
        'mentorName': 'Rahul Sharma',
        'studentId': _studentId3,
        'studentName': 'Rohan Das',
        'lastMessage':
            'Got it, I will try Jetpack Compose with a simple counter.',
        'messages': [
          {
            'id': 'msg_rr_1',
            'fromId': _studentId3,
            'toId': _mentorId1,
            'text':
                'Rahul sir, should I start with XML layouts or directly with Jetpack Compose?',
          },
          {
            'id': 'msg_rr_2',
            'fromId': _mentorId1,
            'toId': _studentId3,
            'text':
                'Start with Compose directly — it is the modern approach and you will land jobs faster.',
          },
          {
            'id': 'msg_rr_3',
            'fromId': _studentId3,
            'toId': _mentorId1,
            'text': 'Got it, I will try Jetpack Compose with a simple counter.',
          },
        ],
      },
      {
        'id': 'conv_sneha_priya',
        'mentorId': _mentorId2,
        'mentorName': 'Priya Patel',
        'studentId': _studentId2,
        'studentName': 'Sneha Iyer',
        'lastMessage': 'The Redux section finally clicked for me!',
        'messages': [
          {
            'id': 'msg_sp_1',
            'fromId': _studentId2,
            'toId': _mentorId2,
            'text':
                'Priya, I am struggling with Redux. Actions, reducers, store — it is overwhelming!',
          },
          {
            'id': 'msg_sp_2',
            'fromId': _mentorId2,
            'toId': _studentId2,
            'text':
                'Think of Redux as a single source of truth. Actions describe what happened, reducers describe how state changes.',
          },
          {
            'id': 'msg_sp_3',
            'fromId': _studentId2,
            'toId': _mentorId2,
            'text': 'The Redux section finally clicked for me!',
          },
        ],
      },
      {
        'id': 'conv_pooja_priya',
        'mentorId': _mentorId2,
        'mentorName': 'Priya Patel',
        'studentId': _studentId4,
        'studentName': 'Pooja Rao',
        'lastMessage':
            'I will check the TF documentation and come back to you.',
        'messages': [
          {
            'id': 'msg_pp_1',
            'fromId': _studentId4,
            'toId': _mentorId2,
            'text': 'Priya, how do I handle overfitting in my CNN model?',
          },
          {
            'id': 'msg_pp_2',
            'fromId': _mentorId2,
            'toId': _studentId4,
            'text':
                'Try dropout layers and data augmentation. Also, reduce your learning rate. What is your current model architecture?',
          },
          {
            'id': 'msg_pp_3',
            'fromId': _studentId4,
            'toId': _mentorId2,
            'text': 'I will check the TF documentation and come back to you.',
          },
        ],
      },
    ];

    int msgCount = 0;
    for (final conv in conversations) {
      final convId = conv['id'] as String;
      final messages = conv['messages'] as List<Map<String, dynamic>>;

      // Write conversation doc
      final convData = <String, dynamic>{
        'mentorId': conv['mentorId'],
        'mentorName': conv['mentorName'],
        'studentId': conv['studentId'],
        'studentName': conv['studentName'],
        'lastMessage': conv['lastMessage'],
        'updatedAt': now,
        'createdAt': now,
      };
      await _db
          .collection('chat_conversations')
          .doc(convId)
          .set(convData, SetOptions(merge: true));

      // Write messages subcollection
      final msgBatch = _db.batch();
      for (final msg in messages) {
        final msgId = msg['id'] as String;
        msgBatch.set(
          _db
              .collection('chat_conversations')
              .doc(convId)
              .collection('chat_messages')
              .doc(msgId),
          {
            'fromId': msg['fromId'],
            'toId': msg['toId'],
            'text': msg['text'],
            'sentAt': now,
          },
          SetOptions(merge: true),
        );
        msgCount++;
      }
      await msgBatch.commit();
    }
    log.writeln(
      '✔ Seeded ${conversations.length} conversations with $msgCount messages.',
    );
  }
}
