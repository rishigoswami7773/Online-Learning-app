import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:online_learning_app/routes/app_routes.dart';
import '../../../controllers/student/course_controller.dart';
import '../../../models/student/course_model.dart';
import '../../../utils/animations.dart';
import '../../widgets/course_card.dart';

class StudentBrowseCourses extends StatefulWidget {
  const StudentBrowseCourses({super.key});

  @override
  State<StudentBrowseCourses> createState() => _StudentBrowseCoursesState();
}

class _StudentBrowseCoursesState extends State<StudentBrowseCourses> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _categories = ['All'];
  List<Map<String, dynamic>> _allCourses = [];
  int _selectedCategory = 0;
  final CourseController _courseController = CourseController();

  Future<List<LegacyCourseModel>> _coursesFuture = Future.value(const []);

  @override
  void initState() {
    super.initState();
    _coursesFuture = _courseController.fetchCourses();
    _loadCoursesAndCategories();
  }

  Future<void> _loadCoursesAndCategories() async {
    try {
      final courses = await _courseController.fetchCourses();
      final coursesList = courses.map((c) => c.toMap()).toList();
      final cats = [
        'All',
        ...(coursesList
            .map((c) => (c['category'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort()),
      ];
      setState(() {
        _allCourses = coursesList;
        _categories = cats;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final appBarBg =
        theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor;
    final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    const Color studentTeal = Color(0xFF0E7C86);
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.studentDashboard);
            }
          },
        ),
        title: Text(
          'Explore Courses',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: FutureBuilder<List<LegacyCourseModel>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 56,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load courses',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }
          final list = snapshot.data ?? [];
          if (_allCourses.isEmpty && list.isNotEmpty) {
            _allCourses = list.map((c) => c.toMap()).toList(growable: false);
          }

          final query = _searchController.text.toLowerCase();
          final filtered = query.isEmpty
              ? _allCourses
              : _allCourses
                    .where(
                      (c) =>
                          (c['title'] ?? '').toString().toLowerCase().contains(
                            query,
                          ) ||
                          (c['category'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(query),
                    )
                    .toList();

          final selectedCategory = _selectedCategory < _categories.length
              ? _categories[_selectedCategory]
              : 'All';
          final categoryFiltered = selectedCategory == 'All'
              ? filtered
              : filtered
                    .where(
                      (c) =>
                          (c['category'] ?? '').toString() == selectedCategory,
                    )
                    .toList();

          final width = MediaQuery.of(context).size.width;
          final crossAxisCount = width > 900 ? 3 : (width > 600 ? 2 : 1);

          return CustomScrollView(
            slivers: [
              // Search section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search bar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF52616B),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? AnimatedOpacity(
                                    duration: const Duration(milliseconds: 180),
                                    opacity: 1,
                                    child: IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    ),
                                  )
                                : null,
                            hintText: 'Search courses...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF52616B),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: theme.cardColor,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE4E8EB),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE4E8EB),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: studentTeal,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category label
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF52616B),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Categories chips
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final selected = i == _selectedCategory;
                            return FilterChip(
                              label: Text(
                                _categories[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              selected: selected,
                              onSelected: (_) {
                                setState(() => _selectedCategory = i);
                              },
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              selectedColor: studentTeal,
                              side: BorderSide(
                                color: selected
                                    ? studentTeal
                                    : Theme.of(context).colorScheme.outline,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Results header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${categoryFiltered.length} course${categoryFiltered.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF52616B),
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (categoryFiltered.isNotEmpty)
                            Text(
                              'Showing all',
                              style: TextStyle(
                                fontSize: 11,
                                color: subtitleColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Course grid
              if (categoryFiltered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.95, end: 1.05),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Transform.scale(scale: value, child: child);
                          },
                          child: Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: theme.dividerColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No courses found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Try adjusting your search or category filter',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF52616B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, idx) => PressableWidget(
                        child: CourseCard(data: categoryFiltered[idx]),
                      ),
                      childCount: categoryFiltered.length,
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        },
      ),
    );
  }
}
