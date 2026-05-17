import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_widgets.dart';

class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, String> _studentNameCache = {};

  String _formatDate(dynamic value) {
    if (value is! Timestamp) return 'Unknown';
    final d = value.toDate().toLocal();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/${d.year} $hour:$minute';
  }

  Future<String> _getStudentName(String studentId) async {
    if (studentId.isEmpty) return 'Unknown student';
    final cached = _studentNameCache[studentId];
    if (cached != null) return cached;

    try {
      final snap = await _firestore.collection('users').doc(studentId).get();
      final name = (snap.data()?['name'] ?? 'Unknown student').toString();
      _studentNameCache[studentId] = name;
      return name;
    } catch (_) {
      return 'Unknown student';
    }
  }

  Widget _sectionHeader(String title) {
    return adminSectionHeader(title);
  }

  Widget _loadingCard() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: ShimmerBox(
        width: double.infinity,
        height: 84,
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageWrapper(
      title: 'Platform Activity',
      showBackButton: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            adminHeroHeader(
              title: 'Platform Activity',
              subtitle: 'Recent enrollments, registrations, and course updates',
            ),
            const SizedBox(height: 16),
            _sectionHeader('Recent Enrollments'),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('enrollments')
                  .orderBy('enrolledAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    children: List.generate(3, (_) => _loadingCard()),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('No enrollments yet'),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final doc = entry.value;
                    final data = doc.data();
                    final studentId = (data['studentId'] ?? '').toString();
                    final courseTitle =
                        (data['courseTitle'] ?? 'Unknown course').toString();

                    return FutureBuilder<String>(
                      future: _getStudentName(studentId),
                      builder: (context, nameSnap) {
                        final studentName =
                            nameSnap.data ?? 'Loading student...';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: StaggeredItem(
                            delay: Duration(milliseconds: index * 50),
                            child: adminListCard(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.school,
                                    color: AdminColors.brand,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$studentName enrolled in $courseTitle',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          _formatDate(data['enrolledAt']),
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            _sectionHeader('Recent Registrations'),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    children: List.generate(3, (_) => _loadingCard()),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('No registrations yet'),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final doc = entry.value;
                    final data = doc.data();
                    final name = (data['name'] ?? 'Unknown').toString();
                    final role = (data['role'] ?? 'student').toString();
                    final email = (data['email'] ?? 'No email').toString();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: StaggeredItem(
                        delay: Duration(milliseconds: index * 50),
                        child: adminListCard(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_add,
                                color: AdminColors.brand,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      '$role • $email • ${_formatDate(data['createdAt'])}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            _sectionHeader('Course Updates'),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('courses')
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    children: List.generate(3, (_) => _loadingCard()),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('No course updates yet'),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final doc = entry.value;
                    final data = doc.data();
                    final title = (data['title'] ?? 'Untitled').toString();
                    final instructor = (data['instructor'] ?? 'Unknown')
                        .toString();
                    final status = (data['status'] ?? 'pending').toString();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: StaggeredItem(
                        delay: Duration(milliseconds: index * 50),
                        child: adminListCard(
                          child: Row(
                            children: [
                              const Icon(Icons.book, color: AdminColors.brand),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'by $instructor • $status • ${_formatDate(data['createdAt'])}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
