import '../../models/student/course_model.dart';
import '../services/firestore_service.dart';

class CourseController {
  final FirestoreService _firestoreService;
  List<LegacyCourseModel> _courses = [];
  bool _isLoading = false;

  CourseController({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  List<LegacyCourseModel> get courses => _courses;
  bool get isLoading => _isLoading;

  Future<List<LegacyCourseModel>> fetchCourses() async {
    _isLoading = true;
    try {
      final coursesList = await _firestoreService.getCollection('courses');
      _courses = coursesList
          .map(
            (courseData) => LegacyCourseModel.fromMap(
              courseData,
              fallbackId: courseData['id'],
            ),
          )
          .toList();
      _isLoading = false;
      return _courses;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching courses: $e');
      _isLoading = false;
      return [];
    }
  }

  Future<List<LegacyCourseModel>> fetchFeaturedCourses({int limit = 5}) async {
    try {
      final coursesList = await _firestoreService.getCollectionWithLimit(
        'courses',
        limit: limit,
      );
      return coursesList
          .map(
            (courseData) => LegacyCourseModel.fromMap(
              courseData,
              fallbackId: courseData['id'],
            ),
          )
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching featured courses: $e');
      return [];
    }
  }

  Future<LegacyCourseModel?> fetchCourseById(String courseId) async {
    try {
      final courseData = await _firestoreService.getDocument(
        'courses',
        courseId,
      );
      if (courseData == null) {
        return null;
      }
      return LegacyCourseModel.fromMap(
        courseData,
        fallbackId: courseData['id'],
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching course by id: $e');
      return null;
    }
  }

  Future<List<LegacyCourseModel>> filterCourses({
    String query = '',
    String? category,
  }) async {
    try {
      final allCourses = await fetchCourses();
      final normalizedQuery = query.trim().toLowerCase();

      return allCourses.where((course) {
        final matchesQuery =
            normalizedQuery.isEmpty ||
            course.title.toLowerCase().contains(normalizedQuery) ||
            course.description.toLowerCase().contains(normalizedQuery) ||
            course.category.toLowerCase().contains(normalizedQuery);
        final matchesCategory =
            category == null ||
            category.isEmpty ||
            course.category.toLowerCase() == category.toLowerCase();
        return matchesQuery && matchesCategory;
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error filtering courses: $e');
      return [];
    }
  }
}
