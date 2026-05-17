class UserStats {
  const UserStats({
    required this.streakDays,
    required this.totalCoursesEnrolled,
    required this.totalCoursesCompleted,
    required this.totalLearningHours,
    required this.currentWeekLearningHours,
    required this.averageRating,
    required this.lastActiveAt,
  });

  final int streakDays;
  final int totalCoursesEnrolled;
  final int totalCoursesCompleted;
  final double totalLearningHours;
  final double currentWeekLearningHours;
  final double averageRating;
  final DateTime? lastActiveAt;

  String get streakDisplay {
    if (streakDays == 0) return 'Start your streak today!';
    if (streakDays == 1) return '1 day streak! 🔥';
    return '$streakDays days in a row! 🔥';
  }

  double get completionRate {
    if (totalCoursesEnrolled == 0) return 0;
    return (totalCoursesCompleted / totalCoursesEnrolled) * 100;
  }

  factory UserStats.fromMap(Map<String, dynamic> data) {
    return UserStats(
      streakDays: _safeInt(data['streakDays'], fallback: 0),
      totalCoursesEnrolled: _safeInt(data['totalCoursesEnrolled'], fallback: 0),
      totalCoursesCompleted: _safeInt(
        data['totalCoursesCompleted'],
        fallback: 0,
      ),
      totalLearningHours: _safeDouble(
        data['totalLearningHours'],
        fallback: 0.0,
      ),
      currentWeekLearningHours: _safeDouble(
        data['currentWeekLearningHours'],
        fallback: 0.0,
      ),
      averageRating: _safeDouble(data['averageRating'], fallback: 0.0),
      lastActiveAt: _safeDate(data['lastActiveAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'streakDays': streakDays,
      'totalCoursesEnrolled': totalCoursesEnrolled,
      'totalCoursesCompleted': totalCoursesCompleted,
      'totalLearningHours': totalLearningHours,
      'currentWeekLearningHours': currentWeekLearningHours,
      'averageRating': averageRating,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    };
  }

  static int _safeInt(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _safeDouble(Object? value, {required double fallback}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime? _safeDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class CourseStats {
  const CourseStats({
    required this.courseId,
    required this.isTrending,
    required this.isNew,
    required this.studentCount,
    required this.completionRate,
    required this.difficulty,
  });

  final String courseId;
  final bool isTrending;
  final bool isNew;
  final int studentCount;
  final double completionRate;
  final String difficulty; // 'Beginner', 'Intermediate', 'Advanced'

  String get difficultyBadge {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return '🟢 Beginner';
      case 'intermediate':
        return '🟡 Intermediate';
      case 'advanced':
        return '🔴 Advanced';
      default:
        return '⚪ Not specified';
    }
  }

  factory CourseStats.fromMap(Map<String, dynamic> data) {
    return CourseStats(
      courseId: (data['courseId'] ?? '').toString(),
      isTrending: data['isTrending'] == true,
      isNew: data['isNew'] == true,
      studentCount: _safeInt(data['studentCount'], fallback: 0),
      completionRate: _safeDouble(data['completionRate'], fallback: 0.0),
      difficulty: (data['difficulty'] ?? 'Beginner').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'isTrending': isTrending,
      'isNew': isNew,
      'studentCount': studentCount,
      'completionRate': completionRate,
      'difficulty': difficulty,
    };
  }

  static int _safeInt(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _safeDouble(Object? value, {required double fallback}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
