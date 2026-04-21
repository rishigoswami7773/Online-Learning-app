import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  static const primaryColor = Color(0xff6C5CE7);
  static const accentColor = Color(0xff8E7CFF);

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  int _currentIndex = 0;

  // Mock data
  final List<Map<String, String>> upcoming = [
    {'title': 'Flutter Advanced', 'time': 'Today • 7:00 PM'},
    {'title': 'UI/UX Masterclass', 'time': 'Tomorrow • 5:30 PM'},
    {'title': 'Dart Tips & Tricks', 'time': 'Fri • 4:00 PM'},
  ];

  final List<Map<String, String>> recentActivity = [
    {'title': 'New student enrolled', 'subtitle': 'Flutter Advanced', 'time': '2m ago'},
    {'title': 'Assignment submitted', 'subtitle': 'UI/UX Masterclass', 'time': '1h ago'},
    {'title': 'Course published', 'subtitle': 'Dart Tips & Tricks', 'time': 'Yesterday'},
  ];

  void _onActionTap(int idx) {
    switch (idx) {
      case 0:
        Navigator.of(context).pushNamed(AppRoutes.mentorCreate);
        break;
      case 1:
        Navigator.of(context).pushNamed(AppRoutes.mentorUpload);
        break;
      case 2:
        Navigator.of(context).pushNamed(AppRoutes.mentorManageCourses);
        break;
      case 3:
        Navigator.of(context).pushNamed(AppRoutes.mentorStudents);
        break;
    }
  }

  void _onBottomNavTap(int idx) {
    setState(() => _currentIndex = idx);
    switch (idx) {
      case 0:
        break;
      case 1:
        Navigator.of(context).pushNamed(AppRoutes.mentorManageCourses);
        break;
      case 2:
        Navigator.of(context).pushNamed(AppRoutes.mentorStudents);
        break;
      case 3:
        Navigator.of(context).pushNamed(AppRoutes.profile, arguments: {'role': 'Mentor', 'name': 'You', 'email': 'mentor@example.com'});
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final edge = 16.0;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FB),

      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: MentorDashboard.primaryColor,
        title: Row(
          children: [
            const Icon(Icons.school, color: MentorDashboard.primaryColor),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Mentor Dashboard', style: TextStyle(color: MentorDashboard.primaryColor, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: _SimpleSearch());
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile, arguments: {'role': 'Mentor', 'name': 'You', 'email': 'mentor@example.com'}),
              borderRadius: BorderRadius.circular(20),
              child: const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
              ),
            ),
          )
        ],
      ),

      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(edge, edge, edge, edge + 90), // leave space for FAB & bottom nav
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [MentorDashboard.primaryColor, MentorDashboard.accentColor]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: const Icon(Icons.school, size: 34, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Good to see you, Mentor!', style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text('Your dashboard provides a quick overview of courses, students and activities.', style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.mentorCreate),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Course'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: MentorDashboard.primaryColor),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.mentorUpload),
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Upload Content'),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24)),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Overview + Actions Row
                isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _overviewCard(edge)),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _quickActionsCard(edge)),
                        ],
                      )
                    : Column(
                        children: [
                          _overviewCard(edge),
                          const SizedBox(height: 12),
                          _quickActionsCard(edge),
                        ],
                      ),

                const SizedBox(height: 18),

                // Upcoming classes + Recent activity
                isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _upcomingClassesCard(edge)),
                          const SizedBox(width: 16),
                          Expanded(child: _recentActivityCard(edge)),
                        ],
                      )
                    : Column(
                        children: [
                          _upcomingClassesCard(edge),
                          const SizedBox(height: 12),
                          _recentActivityCard(edge),
                        ],
                      ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.mentorCreate),
        backgroundColor: MentorDashboard.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('New Course'),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: MentorDashboard.primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _overviewCard(double edge) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(edge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            // Use Wrap so tiles will flow on small screens instead of overflowing
            LayoutBuilder(builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final cols = maxWidth > 500 ? 3 : 2;
              final gap = 12.0 * (cols - 1);
              final tileWidth = (maxWidth - gap) / cols;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _statTile('Courses', '4', Icons.menu_book, color: MentorDashboard.primaryColor, width: tileWidth),
                  _statTile('Students', '120', Icons.people, color: Colors.teal, width: tileWidth),
                  _statTile('Reviews', '35', Icons.star, color: Colors.amber, width: tileWidth),
                ],
              );
            }),
            const SizedBox(height: 14),
            const Text('Course performance', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: 0.7, color: MentorDashboard.primaryColor, backgroundColor: Colors.grey.shade200),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.trending_up, size: 16), const SizedBox(width: 6), const Text('+12% enrollments this month')])
          ],
        ),
      ),
    );
  }

  Widget _quickActionsCard(double edge) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(edge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final cols = maxWidth > 400 ? 2 : 1;
              final gap = 10.0 * (cols - 1);
              final tileWidth = (maxWidth - gap) / cols;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(width: tileWidth, child: _actionTile('Create Course', Icons.add_box, () => _onActionTap(0), gradient: const LinearGradient(colors: [Color(0xff6C5CE7), Color(0xff8E7CFF)]))),
                  SizedBox(width: tileWidth, child: _actionTile('Upload', Icons.cloud_upload, () => _onActionTap(1), gradient: const LinearGradient(colors: [Color(0xff4ECDC4), Color(0xff556270)]))),
                  SizedBox(width: tileWidth, child: _actionTile('Manage Courses', Icons.menu_book_outlined, () => _onActionTap(2), gradient: const LinearGradient(colors: [Color(0xffFF6B6B), Color(0xffFFD166)]))),
                  SizedBox(width: tileWidth, child: _actionTile('Students', Icons.people_alt, () => _onActionTap(3), gradient: const LinearGradient(colors: [Color(0xff00B4D8), Color(0xff90E0EF)]))),
                ],
              );
            })
          ],
        ),
      ),
    );
  }

  Widget _upcomingClassesCard(double edge) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(edge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Upcoming Classes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text('View all', style: TextStyle(color: Colors.blueAccent)),
              ],
            ),
            const SizedBox(height: 12),
            ...upcoming.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    tileColor: Colors.white,
                    leading: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: MentorDashboard.primaryColor.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.video_call, color: MentorDashboard.primaryColor),
                    ),
                    title: Text(c['title']!, overflow: TextOverflow.ellipsis),
                    subtitle: Text(c['time']!, style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis),
                    trailing: IconButton(icon: const Icon(Icons.play_circle_fill, color: MentorDashboard.primaryColor), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joining class (demo)')))),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _recentActivityCard(double edge) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(edge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...recentActivity.map((a) => Column(children: [
                  ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.grey.shade100, child: const Icon(Icons.notifications, color: MentorDashboard.primaryColor)),
                    title: Text(a['title']!),
                    subtitle: Text(a['subtitle']!),
                    trailing: Text(a['time']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    onTap: () {
                      showDialog(context: context, builder: (_) => AlertDialog(title: Text(a['title']!), content: Text('${a['subtitle']}\n\nDetails (demo)'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))]));
                    },
                  ),
                  const Divider()
                ])),
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cleared (demo)'))), child: const Text('Clear all')))
          ],
        ),
      ),
    );
  }

  Widget _statTile(String title, String value, IconData icon, {required Color color, double? width}) {
    return SizedBox(
      width: width ?? 140,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .03), blurRadius: 8)]),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color)),
            const SizedBox(width: 10),
            Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16), overflow: TextOverflow.ellipsis), const SizedBox(height: 2), Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)]))
          ],
        ),
      ),
    );
  }

  Widget _actionTile(String title, IconData icon, VoidCallback onTap, {Gradient? gradient}) {
    return Container(
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 8)]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48), // ensure visible tappable area
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white)),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                const Icon(Icons.chevron_right, color: Colors.white)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleSearch extends SearchDelegate<String> {
  final suggestions = ['Flutter', 'UI/UX', 'Dart', 'Design'];

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [if (query.isNotEmpty) IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(child: Text('Search results for "$query" (demo)'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final list = suggestions.where((s) => s.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) => ListTile(title: Text(list[i]), onTap: () => query = list[i]),
    );
  }
}