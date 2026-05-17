import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../utils/uid_resolver.dart';

class MentorEnrolledStudentsScreenNew extends StatefulWidget {
  const MentorEnrolledStudentsScreenNew({super.key});

  @override
  State<MentorEnrolledStudentsScreenNew> createState() =>
      _MentorEnrolledStudentsScreenNewState();
}

class _MentorEnrolledStudentsScreenNewState
    extends State<MentorEnrolledStudentsScreenNew> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!UidResolver.isLoggedIn && mounted) {
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!UidResolver.isLoggedIn) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final courseId = args?['courseId']?.toString() ?? '';
    final courseTitle = args?['courseTitle']?.toString() ?? 'Course';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.mentorDashboard);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.mentorDashboard);
              }
            },
          ),
          title: Text('Enrolled in $courseTitle'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Search
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search students...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('enrollments')
                      .where('courseId', isEqualTo: courseId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No data yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    final query = _searchCtrl.text.toLowerCase();
                    final enrollments = snapshot.data!.docs.where((e) {
                      final data = e.data() as Map<String, dynamic>;
                      final studentId = data['studentId']?.toString() ?? '';
                      return studentId.contains(query);
                    }).toList();

                    if (enrollments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            const Text('No students found'),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: enrollments.length,
                      itemBuilder: (context, idx) {
                        final e = enrollments[idx];
                        final data = e.data() as Map<String, dynamic>;
                        final progress =
                            ((data['progressPercent'] ?? 0) / 100).clamp(
                                  0.0,
                                  1.0,
                                )
                                as double;
                        final completed = data['lessonsCompleted'] ?? 0;
                        final total = data['totalLessons'] ?? 0;
                        final status = (data['status'] ?? 'active').toString();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      child: Text(
                                        (data['studentId']?.toString() ?? 'S')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['studentId'] ?? 'Student',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: status == 'completed'
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Chip(label: Text('$completed/$total')),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
