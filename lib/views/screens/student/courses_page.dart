import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';

import '../../../controllers/student/course_controller.dart';
import '../../../models/student/course_model.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  static const Color _brand = Color(0xFF0F766E);

  final CourseController _controller = CourseController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  late Future<List<CourseModel>> _courseFuture;

  @override
  void initState() {
    super.initState();
    _courseFuture = _controller.fetchCourses();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.surface, const Color(0xFFEFF7F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<CourseModel>>(
          future: _courseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _courseFuture = _controller.fetchCourses();
                    });
                  },
                  child: const Text('Retry loading courses'),
                ),
              );
            }

            final courses = snapshot.data!;
            final categories = _controller.extractCategories(courses);
            final filtered = _applyFilters(courses);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x220F766E),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find your next skill',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${filtered.length} results • ${categories.length - 1} categories',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search title, category, or instructor',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: const Icon(Icons.filter_list),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final selected = _selectedCategory == category;
                      return ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        selectedColor: const Color(0x220F766E),
                        side: BorderSide(
                          color: selected ? _brand : Colors.transparent,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No courses match the current filters.'),
                    ),
                  )
                else
                  ...filtered.asMap().entries.map(
                    (entry) => _CourseCard(
                      course: entry.value,
                      animationDelayMs: 70 * entry.key,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        indicatorColor: const Color(0x220F766E),
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.studentDashboard);
            return;
          }
          if (index == 2) {
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.studentMyCourses);
            return;
          }
          if (index == 3) {
            Navigator.of(context).pushNamed(AppRoutes.studentProfile);
            return;
          }
          if (index == 4) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon.')),
            );
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_lesson_outlined),
            label: 'My Learning',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }

  List<CourseModel> _applyFilters(List<CourseModel> source) {
    final query = _searchController.text.trim().toLowerCase();

    return source.where((course) {
      final categoryMatches =
          _selectedCategory == 'All' || course.category == _selectedCategory;
      if (!categoryMatches) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return course.title.toLowerCase().contains(query) ||
          course.category.toLowerCase().contains(query) ||
          course.instructor.toLowerCase().contains(query);
    }).toList();
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.animationDelayMs});

  final CourseModel course;
  final int animationDelayMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.97, end: 1),
      duration: Duration(milliseconds: 260 + animationDelayMs),
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 102,
                  height: 92,
                  child: course.thumbnailUrl.isEmpty
                      ? Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.auto_stories_outlined),
                        )
                      : Image.network(
                          course.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) {
                            return Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.auto_stories_outlined),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${course.category} • ${course.durationHours} hrs'),
                    const SizedBox(height: 4),
                    Text('By ${course.instructor} • ⭐ ${course.rating}'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        FilledButton.tonal(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enrollment flow coming soon.'),
                              ),
                            );
                          },
                          child: const Text('Enroll'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.studentCourseDetail,
                              arguments: {'course': course.toMap()},
                            );
                          },
                          child: const Text('Details'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
