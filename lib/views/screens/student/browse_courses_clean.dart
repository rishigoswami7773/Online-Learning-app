import 'package:flutter/material.dart';
import '../../../controllers/student/course_controller.dart';
import '../../../models/student/course_model.dart';
import '../../../utils/theme_helper.dart';
import '../../widgets/course_card.dart';

class StudentBrowseCourses extends StatefulWidget {
  const StudentBrowseCourses({super.key});

  @override
  State<StudentBrowseCourses> createState() => _StudentBrowseCoursesState();
}

class _StudentBrowseCoursesState extends State<StudentBrowseCourses> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = ['All'];
  int _selectedCategory = 0;
  final CourseController _courseController = CourseController();

  Future<List<LegacyCourseModel>> _coursesFuture = Future.value(const []);

  @override
  void initState() {
    super.initState();
    _coursesFuture = _courseController.fetchCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Courses'), elevation: 0),
      body: FutureBuilder<List<LegacyCourseModel>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          final courses = list.map((c) => c.toMap()).toList(growable: false);

          final width = MediaQuery.of(context).size.width;
          final crossAxisCount = width > 900 ? 3 : (width > 600 ? 2 : 1);

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search courses, instructors, topics...',
                    filled: true,
                    fillColor: context.bgColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 12.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 12),

                // Categories (derived from fetched courses)
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final selected = i == _selectedCategory;
                      return ChoiceChip(
                        label: Text(_categories[i]),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = i),
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha((0.12 * 255).round()),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Results header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    '${courses.length} course${courses.length == 1 ? '' : 's'} found',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),

                const SizedBox(height: 8),

                // Course grid / empty state
                Expanded(
                  child: courses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 56,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'No courses found',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                          itemCount: courses.length,
                          itemBuilder: (context, idx) =>
                              CourseCard(data: courses[idx]),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
