import 'package:flutter/material.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color secondaryColor = Color(0xFF7C3AED);
  static const Color bgColor = Color(0xFFF8FAFC);
  static const Color textColor = Color(0xFF1E293B);
  static const Color mutedColor = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: bgColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final isWide = maxWidth > 900;

              final kpiCols = isWide ? 4 : (maxWidth > 550 ? 2 : 1);
              final kpiGap = 16.0 * (kpiCols - 1);
              final kpiTileWidth = (maxWidth - kpiGap) / kpiCols;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header
                  const AdminHeader(),
                  const SizedBox(height: 24),

                  // 2. KPI row
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(width: kpiTileWidth, child: AdminKpiCard(icon: Icons.group_outlined, label: 'Total Students', value: '1,240', color: primaryColor, trend: '12%', isUp: true)),
                      SizedBox(width: kpiTileWidth, child: AdminKpiCard(icon: Icons.school_outlined, label: 'Active Mentors', value: '86', color: const Color(0xFF06B6D4), trend: '4%', isUp: true)),
                      SizedBox(width: kpiTileWidth, child: AdminKpiCard(icon: Icons.menu_book_outlined, label: 'Live Courses', value: '312', color: const Color(0xFFF59E0B), trend: '2%', isUp: false)),
                      SizedBox(width: kpiTileWidth, child: AdminKpiCard(icon: Icons.account_balance_wallet_outlined, label: 'Total Revenue', value: '\$17.2K', color: const Color(0xFF10B981), trend: '18%', isUp: true)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 3. Charts Row
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(flex: 2, child: AdminPlatformGrowthChart()),
                        SizedBox(width: 16),
                        Expanded(flex: 1, child: AdminRevenuePieChart()),
                      ],
                    )
                  else
                    Column(
                      children: const [
                        AdminPlatformGrowthChart(),
                        SizedBox(height: 16),
                        AdminRevenuePieChart(),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // 4. Quick Actions & Activity
                  Builder(
                    builder: (context) {
                      final actionList = Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: AdminQuickActionCard(title: 'Users', icon: Icons.people_outline, color: primaryColor, route: AppRoutes.adminUsers)),
                                const SizedBox(width: 12),
                                Expanded(child: AdminQuickActionCard(title: 'Courses', icon: Icons.library_books_outlined, color: secondaryColor, route: AppRoutes.adminCourses)),
                                const SizedBox(width: 12),
                                Expanded(child: AdminQuickActionCard(title: 'Reports', icon: Icons.analytics_outlined, color: const Color(0xFF06B6D4), route: AppRoutes.adminAnalytics)),
                              ],
                            ),
                          ],
                        )
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 1, child: actionList),
                            const SizedBox(width: 16),
                            const Expanded(flex: 1, child: AdminRecentActivityList()),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            actionList,
                            const SizedBox(height: 16),
                            const AdminRecentActivityList(),
                          ],
                        );
                      }
                    }
                  ),

                  const SizedBox(height: 40), // Bottom padding
                ],
              );
            }
          ),
        ),
      ),
    );
  }
}

class AdminHeader extends StatelessWidget {
  const AdminHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AdminHomeScreen.primaryColor, AdminHomeScreen.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AdminHomeScreen.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_moon, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back, Admin!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here is what\'s happening with your platform today.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.adminUpload),
            icon: const Icon(Icons.cloud_upload, color: AdminHomeScreen.primaryColor),
            label: const Text('New Course', style: TextStyle(color: AdminHomeScreen.primaryColor, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminKpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String trend;
  final bool isUp;

  const AdminKpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.trend,
    required this.isUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isUp ? Colors.green : Colors.red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, color: isUp ? Colors.green : Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Text(trend, style: TextStyle(color: isUp ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AdminHomeScreen.textColor), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 14, color: AdminHomeScreen.mutedColor, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class AdminPlatformGrowthChart extends StatelessWidget {
  const AdminPlatformGrowthChart({super.key});

  @override
  Widget build(BuildContext context) {
    final spots = [const FlSpot(0, 50), const FlSpot(1, 60), const FlSpot(2, 55), const FlSpot(3, 80), const FlSpot(4, 75), const FlSpot(5, 100)];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform Growth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminHomeScreen.textColor)),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: false, 
                  horizontalInterval: 25, 
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(color: AdminHomeScreen.mutedColor, fontSize: 12)))),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AdminHomeScreen.primaryColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 3, strokeColor: AdminHomeScreen.primaryColor)),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AdminHomeScreen.primaryColor.withValues(alpha: 0.3), AdminHomeScreen.primaryColor.withValues(alpha: 0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminRevenuePieChart extends StatelessWidget {
  const AdminRevenuePieChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminHomeScreen.textColor)),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(value: 40, color: const Color(0xFF4F46E5), title: '40%', radius: 25, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  PieChartSectionData(value: 30, color: const Color(0xFF06B6D4), title: '30%', radius: 25, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  PieChartSectionData(value: 20, color: const Color(0xFFF59E0B), title: '20%', radius: 25, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  PieChartSectionData(value: 10, color: const Color(0xFF10B981), title: '10%', radius: 25, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminQuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  const AdminQuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, color: AdminHomeScreen.textColor, fontSize: 13), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminRecentActivityList extends StatelessWidget {
  const AdminRecentActivityList({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      {'title': 'New user registered.', 'name': 'John Doe', 'time': '5 mins ago', 'icon': Icons.person_add, 'color': AdminHomeScreen.primaryColor},
      {'title': 'Course approved.', 'name': 'Flutter Masterclass', 'time': '2 hours ago', 'icon': Icons.check_circle, 'color': const Color(0xFF10B981)},
      {'title': 'Payment received.', 'name': '\$120.00', 'time': '5 hours ago', 'icon': Icons.attach_money, 'color': const Color(0xFFF59E0B)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminHomeScreen.textColor)),
              TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: AdminHomeScreen.primaryColor, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 12),
          ...activities.map((act) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: (act['color'] as Color).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(act['icon'] as IconData, color: act['color'] as Color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(act['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: AdminHomeScreen.textColor, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(act['name'] as String, style: const TextStyle(color: AdminHomeScreen.mutedColor, fontSize: 12)),
                    ],
                  ),
                ),
                Text(act['time'] as String, style: const TextStyle(color: AdminHomeScreen.mutedColor, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ))
        ],
      ),
    );
  }
}
