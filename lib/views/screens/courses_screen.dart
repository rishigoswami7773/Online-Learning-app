import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controllers/home_controller.dart';
import '../../models/guest_home_content.dart';
import '../../models/mentor_model.dart';
import '../../theme/app_theme.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  static const Color _brand = AppColors.brand;

  final HomeController _controller = const HomeController();
  final PageController _pageController = PageController(viewportFraction: 0.88);

  int _featuredIndex = 0;
  bool _showQuickActions = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<GuestCourse> get _featuredCourses => _controller.getFeaturedCourses();

  List<MentorModel> get _topMentors => _controller.getTopMentors();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 700;
    final isCompactTopBar = width < 430;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0E7C86), Color(0xFF17A2B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              'LearnSphere',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF102A43),
              ),
            ),
          ],
        ),
        actions: isCompactTopBar
            ? [
                PopupMenuButton<String>(
                  tooltip: 'Account options',
                  onSelected: (value) {
                    if (value == 'login') {
                      _controller.openLogin(context);
                      return;
                    }
                    _controller.openRegister(context);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'login', child: Text('Login')),
                    PopupMenuItem(value: 'register', child: Text('Register')),
                  ],
                  icon: const Icon(Icons.account_circle_outlined),
                ),
                const SizedBox(width: 8),
              ]
            : [
                TextButton(
                  onPressed: () => _controller.openLogin(context),
                  child: const Text('Login'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => _controller.openRegister(context),
                  child: const Text('Register'),
                ),
                const SizedBox(width: 12),
              ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: _HeroSection(
                isNarrow: isNarrow,
                onJoinNow: () => _controller.openRegister(context),
                onLogin: () => _controller.openLogin(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD8E5EA)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0E7C86,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.dashboard_customize_outlined,
                            color: Color(0xFF0E7C86),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Actions',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF102A43),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tap to show useful options',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF52616B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showQuickActions = !_showQuickActions;
                            });
                          },
                          icon: Icon(
                            _showQuickActions
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                          ),
                          label: Text(_showQuickActions ? 'Hide' : 'Show'),
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final actions = <_GuestQuickAction>[
                              _GuestQuickAction(
                                label: 'Open Search',
                                subtitle: 'Find by keyword',
                                icon: Icons.search_rounded,
                                onTap: () => _controller.openSearch(context),
                              ),
                              _GuestQuickAction(
                                label: 'All Courses',
                                subtitle: 'Browse catalog',
                                icon: Icons.menu_book_outlined,
                                onTap: () =>
                                    _controller.openCourseList(context),
                              ),
                              _GuestQuickAction(
                                label: 'About',
                                subtitle: 'Platform story',
                                icon: Icons.info_outline,
                                onTap: () => _controller.openAbout(context),
                              ),
                              _GuestQuickAction(
                                label: 'Mentors',
                                subtitle: 'Meet experts',
                                icon: Icons.workspace_premium_outlined,
                                onTap: () => _controller.openMentors(context),
                              ),
                              _GuestQuickAction(
                                label: 'Contact',
                                subtitle: 'Get support',
                                icon: Icons.contact_support_outlined,
                                onTap: () => _controller.openContact(context),
                              ),
                              _GuestQuickAction(
                                label: 'FAQ',
                                subtitle: 'Common answers',
                                icon: Icons.quiz_outlined,
                                onTap: () => _controller.openFaq(context),
                              ),
                              _GuestQuickAction(
                                label: 'Wishlist',
                                subtitle: 'Save favorites',
                                icon: Icons.favorite_border,
                                onTap: () => _controller.openWishlist(context),
                              ),
                              _GuestQuickAction(
                                label: 'Notifications',
                                subtitle: 'Latest updates',
                                icon: Icons.notifications_none,
                                onTap: () =>
                                    _controller.openGuestNotifications(context),
                              ),
                              _GuestQuickAction(
                                label: 'Chat',
                                subtitle: 'Ask questions',
                                icon: Icons.chat_bubble_outline,
                                onTap: () => _controller.openGuestChat(context),
                              ),
                            ];

                            final columns = constraints.maxWidth < 560
                                ? 1
                                : constraints.maxWidth < 940
                                ? 2
                                : 3;

                            final aspect = columns == 1 ? 3.0 : 2.2;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: actions.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: aspect,
                                  ),
                              itemBuilder: (context, index) {
                                final action = actions[index];
                                return _GuestQuickActionTile(action: action);
                              },
                            );
                          },
                        ),
                      ),
                      crossFadeState: _showQuickActions
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 220),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: _SectionHeader(
                title: 'Featured Courses',
                subtitle:
                    'Curated editor picks with high learner engagement and outcomes.',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                height: isNarrow ? 305 : 330,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _featuredCourses.length,
                  onPageChanged: (index) =>
                      setState(() => _featuredIndex = index),
                  itemBuilder: (context, index) {
                    final course = _featuredCourses[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _FeaturedCourseCard(
                        course: course,
                        onTap: () =>
                            _controller.openGuestCourseDetail(context, course),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_featuredCourses.length, (index) {
                  final active = index == _featuredIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? _brand : const Color(0xFFD7E2EA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _FeaturedInfoChip(
                      icon: Icons.trending_up_rounded,
                      label: 'Top Rated Tracks',
                    ),
                    _FeaturedInfoChip(
                      icon: Icons.schedule_rounded,
                      label: 'New Batches Weekly',
                    ),
                    _FeaturedInfoChip(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Mentor-backed Learning',
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: _SectionHeader(
                title: 'Learning Roadmaps',
                subtitle:
                    'Choose a practical path based on your learning goal and time commitment.',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 700;
                  final itemWidth = wide
                      ? (constraints.maxWidth - 24) / 3
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: _RoadmapCard(
                          icon: Icons.rocket_launch_outlined,
                          title: 'Career Starter',
                          subtitle:
                              'Beginner-friendly path to build confidence',
                          duration: '4-6 weeks',
                          color: const Color(0xFF0E7C86),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _RoadmapCard(
                          icon: Icons.workspace_premium_outlined,
                          title: 'Pro Accelerator',
                          subtitle: 'Hands-on projects with mentor checkpoints',
                          duration: '6-8 weeks',
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _RoadmapCard(
                          icon: Icons.auto_graph_outlined,
                          title: 'Leadership Track',
                          subtitle:
                              'Strategy, communication, and growth skills',
                          duration: '8-10 weeks',
                          color: const Color(0xFFF97316),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: _SectionHeader(
                title: 'Popular Courses',
                subtitle:
                    'Trending guest picks. Tap a course to open full details and enroll options.',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: _featuredCourses
                    .map(
                      (course) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            onTap: () => _controller.openGuestCourseDetail(
                              context,
                              course,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: course.accentColor.withValues(
                                alpha: 0.12,
                              ),
                              child: Icon(
                                course.icon,
                                color: course.accentColor,
                              ),
                            ),
                            title: Text(course.title),
                            subtitle: Text(
                              '${course.instructor} • ${course.duration}',
                            ),
                            trailing: Text(
                              course.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: _SectionHeader(
                title: 'Top Mentors',
                subtitle:
                    'Meet highly-rated mentors guiding learners every day.',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                height: 176,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _topMentors.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final mentor = _topMentors[index];
                    return SizedBox(
                      width: math.min(width - 56, 290),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(
                                      0xFF0E7C86,
                                    ).withValues(alpha: 0.12),
                                    child: Text(
                                      mentor.name.substring(0, 1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0E7C86),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mentor.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          mentor.expertise,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF52616B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(mentor.rating.toStringAsFixed(1)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                mentor.bio,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(height: 1.35),
                              ),
                              const Spacer(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      _controller.openMentors(context),
                                  child: const Text('View Profile'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: _SectionHeader(
                title: 'Why Choose Us',
                subtitle:
                    'A guest experience that feels polished, clear, and easy to trust.',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 700;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: GuestHomeContent.benefits
                        .map(
                          (benefit) => SizedBox(
                            width: isCompact
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 24) / 3,
                            child: _BenefitCard(benefit: benefit),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: _SectionHeader(
                title: 'Learner Voices',
                subtitle:
                    'A quick glimpse of how guests and students feel about the experience.',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                height: 170,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: GuestHomeContent.testimonials.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: math.min(width - 48, 320),
                      child: _TestimonialCard(
                        testimonial: GuestHomeContent.testimonials[index],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
              child: _CallToActionSection(
                onJoinNow: () => _controller.openRegister(context),
                onLogin: () => _controller.openLogin(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
              child: _FooterSection(
                onLinkTap: (title) =>
                    _controller.openSectionLink(context, title),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.isNarrow,
    required this.onJoinNow,
    required this.onLogin,
  });

  final bool isNarrow;
  final VoidCallback onJoinNow;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E7C86), Color(0xFF17A2B8), Color(0xFF0B5D66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E7C86).withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroCopy(onJoinNow: onJoinNow, onLogin: onLogin),
                const SizedBox(height: 18),
                _HeroIllustration(),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _HeroCopy(onJoinNow: onJoinNow, onLogin: onLogin),
                ),
                const SizedBox(width: 16),
                const Expanded(flex: 4, child: _HeroIllustration()),
              ],
            ),
    );

    return content;
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onJoinNow, required this.onLogin});

  final VoidCallback onJoinNow;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Guest access enabled',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Learn Anytime, Anywhere',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Explore expert-led courses, preview lessons, and guided roadmaps before you sign in. Join only when you are ready to learn more.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: onJoinNow,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0E7C86),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              child: const Text('Join Now'),
            ),
            OutlinedButton(
              onPressed: onLogin,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              child: const Text('Login'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: const [
            _HeroMetric(label: '10K+', value: 'Learners'),
            SizedBox(width: 12),
            _HeroMetric(label: '250+', value: 'Courses'),
            SizedBox(width: 12),
            _HeroMetric(label: '4.8', value: 'Rating'),
          ],
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 18,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          Positioned(
            left: 52,
            bottom: 22,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/reference/image.png',
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: Colors.white.withValues(alpha: 0.12),
                  child: const Center(
                    child: Icon(
                      Icons.cast_for_education_rounded,
                      color: Colors.white,
                      size: 72,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Fresh learning paths',
                style: TextStyle(
                  color: Color(0xFF0E7C86),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF102A43),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF52616B),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _GuestQuickAction {
  const _GuestQuickAction({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _GuestQuickActionTile extends StatelessWidget {
  const _GuestQuickActionTile({required this.action});

  final _GuestQuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: action.onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF0E7C86).withValues(alpha: 0.24),
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF6FBFC)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E7C86).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(action.icon, color: const Color(0xFF0E7C86)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF102A43),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        action.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF52616B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF0E7C86),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedCourseCard extends StatelessWidget {
  const _FeaturedCourseCard({required this.course, required this.onTap});

  final GuestCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  course.thumbnailAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: course.accentColor.withValues(alpha: 0.12),
                      child: Center(
                        child: Icon(
                          course.icon,
                          size: 82,
                          color: course.accentColor.withValues(alpha: 0.85),
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            course.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            child: Icon(course.icon, color: course.accentColor),
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  course.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            course.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Editor Pick',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap anywhere on this card to view details',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedInfoChip extends StatelessWidget {
  const _FeaturedInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.brand),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadmapCard extends StatelessWidget {
  const _RoadmapCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.duration,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String subtitle;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              duration,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.benefit});

  final GuestBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: benefit.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(benefit.icon, color: benefit.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  benefit.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF52616B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.testimonial});

  final GuestTestimonial testimonial;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(
                  0xFF0E7C86,
                ).withValues(alpha: 0.12),
                child: Text(
                  testimonial.name[0],
                  style: const TextStyle(
                    color: Color(0xFF0E7C86),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimonial.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    Text(
                      testimonial.role,
                      style: const TextStyle(color: Color(0xFF52616B)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.star_rounded, color: Colors.amber),
              const SizedBox(width: 4),
              Text(testimonial.rating.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            testimonial.feedback,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF334E68),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CallToActionSection extends StatelessWidget {
  const _CallToActionSection({required this.onJoinNow, required this.onLogin});

  final VoidCallback onJoinNow;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF102A43), Color(0xFF0E7C86)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ready to start learning?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Create your account to unlock enrollment, progress tracking, and more.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton(
                          onPressed: onJoinNow,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0E7C86),
                          ),
                          child: const Text('Get Started'),
                        ),
                        OutlinedButton(
                          onPressed: onLogin,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                          ),
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready to start learning?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Create your account to unlock enrollment, progress tracking, and more.',
                            style: TextStyle(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.end,
                      children: [
                        FilledButton(
                          onPressed: onJoinNow,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0E7C86),
                          ),
                          child: const Text('Get Started'),
                        ),
                        OutlinedButton(
                          onPressed: onLogin,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                          ),
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection({required this.onLinkTap});

  final ValueChanged<String> onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        children: [
          Text(
            'LearnSphere • Explore first, learn better later.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF52616B)),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => onLinkTap('About Us'),
                child: const Text('About Us'),
              ),
              TextButton(
                onPressed: () => onLinkTap('Contact'),
                child: const Text('Contact'),
              ),
              TextButton(
                onPressed: () => onLinkTap('Mentors'),
                child: const Text('Mentors'),
              ),
              TextButton(
                onPressed: () => onLinkTap('FAQ'),
                child: const Text('FAQ'),
              ),
              TextButton(
                onPressed: () => onLinkTap('Privacy Policy'),
                child: const Text('Privacy Policy'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
