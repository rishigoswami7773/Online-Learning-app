import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  static const primaryColor = Color(0xff6A5AE0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      /// 🔹 APP BAR
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text("Admin Dashboard"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundImage:
                  NetworkImage("https://i.pravatar.cc/150?img=10"),
            ),
          )
        ],
      ),

      /// 🔹 BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔥 HEADER (MODERN)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff6A5AE0), Color(0xff8E7BFF)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const [
                  Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 40),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Admin Control Panel\nManage everything efficiently",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 📊 OVERVIEW
            const Text("Overview",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),

            LayoutBuilder(builder: (context, constraints) {
              final cols = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: const [
                  AdminStatCard(title: "Students", value: "420", icon: Icons.people),
                  AdminStatCard(title: "Mentors", value: "35", icon: Icons.school),
                  AdminStatCard(title: "Courses", value: "60", icon: Icons.menu_book),
                  AdminStatCard(title: "Revenue", value: "₹12K", icon: Icons.currency_rupee),
                ],
              );
            }),

            const SizedBox(height: 24),

            /// ⚙️ MANAGEMENT
            const Text("Management",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),

            LayoutBuilder(builder: (context, constraints) {
              final cols = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
                children: const [
                  AdminActionCard(title: "Users", icon: Icons.people),
                  AdminActionCard(title: "Courses", icon: Icons.menu_book),
                  AdminActionCard(title: "Reports", icon: Icons.bar_chart),
                  AdminActionCard(title: "Settings", icon: Icons.settings),
                ],
              );
            }),

            const SizedBox(height: 24),

            /// 🔔 RECENT ACTIVITY
            const Text("Recent Activity",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),

            const AdminActivityCard(title: "New student registered", time: "2 min ago"),
            const AdminActivityCard(title: "Mentor uploaded course", time: "10 min ago"),
            const AdminActivityCard(title: "Course approved", time: "30 min ago"),
          ],
        ),
      ),

      /// 🔹 BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book), label: "Courses"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}

/// 📊 STAT CARD
class AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AdminDashboard.primaryColor, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(title, style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// ⚙️ ACTION CARD
class AdminActionCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const AdminActionCard({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (title == "Users") Navigator.pushNamed(context, AppRoutes.adminUsers);
            if (title == "Courses") Navigator.pushNamed(context, AppRoutes.adminCourses);
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: AdminDashboard.primaryColor),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔔 ACTIVITY CARD
class AdminActivityCard extends StatelessWidget {
  final String title;
  final String time;

  const AdminActivityCard({
    super.key,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 6)
        ],
      ),
      child: ListTile(
        leading: const Icon(Icons.notifications, color: AdminDashboard.primaryColor),
        title: Text(title),
        subtitle: Text(time),
      ),
    );
  }
}