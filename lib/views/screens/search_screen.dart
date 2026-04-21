import 'package:flutter/material.dart';
import 'package:online_learning_app/models/guest_home_content.dart';

import '../../controllers/home_controller.dart';
import '../../theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final HomeController _controller = const HomeController();
  final _ctrl = TextEditingController();
  List<GuestCourse> results = GuestHomeContent.featuredCourses;
  String _query = '';

  void _search(String q) {
    setState(() {
      _query = q.trim();
      results = GuestHomeContent.featuredCourses
          .where(
            (c) =>
                c.title.toLowerCase().contains(q.toLowerCase()) ||
                c.category.toLowerCase().contains(q.toLowerCase()) ||
                c.description.toLowerCase().contains(q.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      appBar: AppBar(title: const Text('Search Courses')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandDark, AppColors.brand],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover Your Next Course',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Search by title, category, or keywords to find the best fit.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search by title, category, keyword',
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _ctrl.clear();
                            _search('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onChanged: _search,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(
                '${results.length} result${results.length == 1 ? '' : 's'} found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (results.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 52,
                        color: AppColors.brand.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'No courses found',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Try different keywords or clear the search.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (isWide)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 170,
                ),
                delegate: SliverChildBuilderDelegate((context, idx) {
                  final c = results[idx];
                  return _SearchResultCard(
                    course: c,
                    onTap: () => _controller.openGuestCourseDetail(context, c),
                  );
                }, childCount: results.length),
              ),
            )
          else
            SliverList.separated(
              itemBuilder: (context, idx) {
                final c = results[idx];
                return Padding(
                  padding: EdgeInsets.fromLTRB(14, idx == 0 ? 10 : 0, 14, 10),
                  child: _SearchResultCard(
                    course: c,
                    onTap: () => _controller.openGuestCourseDetail(context, c),
                  ),
                );
              },
              separatorBuilder: (context, idx) => const SizedBox.shrink(),
              itemCount: results.length,
            ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.course, required this.onTap});

  final GuestCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 86,
                  height: 86,
                  color: course.accentColor.withValues(alpha: 0.14),
                  child: Image.asset(
                    course.thumbnailAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(course.icon, size: 38, color: course.accentColor),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text(course.category)),
                        Chip(
                          avatar: const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Colors.amber,
                          ),
                          label: Text(course.rating.toStringAsFixed(1)),
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
