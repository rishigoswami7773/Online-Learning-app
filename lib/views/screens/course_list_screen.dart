import 'package:flutter/material.dart';

import '../../controllers/home_controller.dart';
import '../../models/course_model.dart';
import '../../models/guest_home_content.dart';
import '../../theme/app_theme.dart';
import '../widgets/guest_course_card.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final HomeController _controller = const HomeController();
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  String? _selectedCategory;
  bool _useGrid = true;
  String _sortBy = 'Rating';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CourseModel> get _courses => (() {
    final normalized = _query.trim().toLowerCase();
    final data = _controller.getCourseModels().where((course) {
      final matchesQuery =
          normalized.isEmpty ||
          course.title.toLowerCase().contains(normalized) ||
          course.category.toLowerCase().contains(normalized) ||
          course.instructorName.toLowerCase().contains(normalized);
      final matchesCategory =
          _selectedCategory == null || _selectedCategory == course.category;
      return matchesQuery && matchesCategory;
    }).toList();
    data.sort((a, b) {
      switch (_sortBy) {
        case 'Title':
          return a.title.compareTo(b.title);
        case 'Category':
          return a.category.compareTo(b.category);
        case 'Rating':
        default:
          return b.rating.compareTo(a.rating);
      }
    });
    return data;
  })();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Courses'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _useGrid = !_useGrid),
            icon: Icon(_useGrid ? Icons.view_list : Icons.grid_view),
            tooltip: _useGrid ? 'Switch to list' : 'Switch to grid',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandDark, AppColors.brand],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_stories_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_courses.length} courses available for guest preview',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search courses',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                ),
                ...GuestHomeContent.categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(category.title),
                      selected: _selectedCategory == category.title,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory =
                              _selectedCategory == category.title
                              ? null
                              : category.title;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DropdownButtonFormField<String>(
              initialValue: _sortBy,
              decoration: const InputDecoration(
                labelText: 'Sort by',
                prefixIcon: Icon(Icons.filter_alt_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'Rating', child: Text('Top Rated')),
                DropdownMenuItem(value: 'Title', child: Text('Title A-Z')),
                DropdownMenuItem(value: 'Category', child: Text('Category')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _sortBy = value);
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _courses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 46,
                          color: AppColors.brand.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 10),
                        const Text('No matching courses found.'),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _query = '';
                              _selectedCategory = null;
                              _searchController.clear();
                            });
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  )
                : _useGrid
                ? GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.82,
                        ),
                    itemCount: _courses.length,
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      return GuestCourseCard(
                        course: GuestCourse(
                          title: course.title,
                          category: course.category,
                          instructor: course.instructorName,
                          description: course.description,
                          rating: course.rating,
                          duration: course.duration,
                          level: course.level,
                          priceLabel: course.priceLabel,
                          highlights: course.highlights,
                          thumbnailAsset: course.thumbnailAsset,
                          icon: course.icon,
                          accentColor: const Color(0xFF0E7C86),
                        ),
                        onTap: () => _controller.openGuestCourseDetailFromModel(
                          context,
                          course,
                        ),
                      );
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _courses.length,
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CourseListTile(
                          course: course,
                          onTap: () => _controller
                              .openGuestCourseDetailFromModel(context, course),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CourseListTile extends StatelessWidget {
  const _CourseListTile({required this.course, required this.onTap});

  final CourseModel course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0E7C86).withValues(alpha: 0.12),
          child: Icon(course.icon, color: const Color(0xFF0E7C86)),
        ),
        title: Text(course.title),
        subtitle: Text('${course.category} • ${course.instructorName}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, size: 16, color: Colors.amber),
            Text(course.rating.toStringAsFixed(1)),
          ],
        ),
      ),
    );
  }
}
