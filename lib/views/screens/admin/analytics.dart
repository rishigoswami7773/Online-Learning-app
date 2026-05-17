import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../utils/theme_helper.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late Future<_AnalyticsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<_AnalyticsData> _load() async {
    final fs = FirebaseFirestore.instance;
    final results = await Future.wait([
      fs.collection('users').get(),
      fs.collection('courses').get(),
      fs.collection('enrollments').get(),
      fs
          .collection('enrollments')
          .orderBy('createdAt', descending: false)
          .get(),
    ]);

    final users = results[0].docs;
    final courses = results[1].docs;
    final enrollments = results[2].docs;
    final enrollmentsTimeline = results[3].docs;

    final categoryCounts = <String, int>{};
    for (final doc in courses) {
      final data = doc.data();
      final category = (data['category'] ?? 'General').toString();
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    final monthlyEnrollments = <int, int>{};
    for (final doc in enrollmentsTimeline) {
      final createdAt = doc.data()['createdAt'];
      if (createdAt is Timestamp) {
        final month = createdAt.toDate().month;
        monthlyEnrollments[month] = (monthlyEnrollments[month] ?? 0) + 1;
      }
    }

    return _AnalyticsData(
      totalUsers: users.length,
      totalCourses: courses.length,
      totalEnrollments: enrollments.length,
      categoryCounts: categoryCounts,
      monthlyEnrollments: monthlyEnrollments,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Analytics'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<_AnalyticsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 56),
                  const SizedBox(height: 12),
                  Text('Failed to load analytics: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _reload, child: const Text('Retry')),
                ],
              ),
            );
          }

          final data = snapshot.data;
          if (data == null ||
              data.totalUsers + data.totalCourses + data.totalEnrollments ==
                  0) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insights_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No analytics data yet'),
                  SizedBox(height: 6),
                  Text('Add users, courses, and enrollments to see trends.'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _summaryCard('Users', data.totalUsers, Icons.people),
                    _summaryCard('Courses', data.totalCourses, Icons.menu_book),
                    _summaryCard(
                      'Enrollments',
                      data.totalEnrollments,
                      Icons.playlist_add_check,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Enrollments over time',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: _buildEnrollmentsChart(data.monthlyEnrollments),
                ),
                const SizedBox(height: 24),
                Text(
                  'Course categories',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: _buildCategoryChart(data.categoryCounts),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard(String label, int value, IconData icon) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnrollmentsChart(Map<int, int> counts) {
    if (counts.isEmpty) {
      return const Center(child: Text('No enrollment timeline data'));
    }

    final sortedMonths = counts.keys.toList()..sort();
    final spots = <FlSpot>[];
    for (var i = 0; i < sortedMonths.length; i++) {
      spots.add(FlSpot(i.toDouble(), counts[sortedMonths[i]]!.toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingVerticalLine: (_) => FlLine(color: context.dividerColor),
          getDrawingHorizontalLine: (_) => FlLine(color: context.dividerColor),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 36),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= sortedMonths.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'M${sortedMonths[index]}',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: Theme.of(context).colorScheme.primary,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(Map<String, int> counts) {
    if (counts.isEmpty) {
      return const Center(child: Text('No course categories yet'));
    }

    final entries = counts.entries.toList();
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.purple,
    ];

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    title: entries[i].key,
                    color: colors[i % colors.length],
                    radius: 60,
                    titleStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < entries.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: colors[i % colors.length],
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entries[i].key)),
                      Text(entries[i].value.toString()),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalyticsData {
  _AnalyticsData({
    required this.totalUsers,
    required this.totalCourses,
    required this.totalEnrollments,
    required this.categoryCounts,
    required this.monthlyEnrollments,
  });

  final int totalUsers;
  final int totalCourses;
  final int totalEnrollments;
  final Map<String, int> categoryCounts;
  final Map<int, int> monthlyEnrollments;
}
