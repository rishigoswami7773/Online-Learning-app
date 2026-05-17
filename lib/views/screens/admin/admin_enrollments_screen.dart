import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/theme_helper.dart';

class AdminEnrollmentsScreen extends StatefulWidget {
  const AdminEnrollmentsScreen({super.key});

  @override
  State<AdminEnrollmentsScreen> createState() => _AdminEnrollmentsScreenState();
}

class _AdminEnrollmentsScreenState extends State<AdminEnrollmentsScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '—';
    try {
      final dt = (timestamp as Timestamp).toDate().toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enrollments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin/home');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // ── Search + filter bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search student or course…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _search = v.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    borderRadius: BorderRadius.circular(10),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Completed'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _statusFilter = v!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ── Live enrollment list from Firestore ────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('enrollments')
                  .orderBy('enrolledAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading enrollments',
                      style: TextStyle(color: context.textSecondary),
                    ),
                  );
                }

                final all = snapshot.data?.docs ?? [];

                // Client-side filter
                final filtered = all.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final student =
                      (data['studentName'] ?? data['studentId'] ?? '')
                          .toString()
                          .toLowerCase();
                  final course =
                      (data['courseTitle'] ?? data['courseName'] ?? '')
                          .toString()
                          .toLowerCase();
                  final status = (data['status'] ?? 'active')
                      .toString()
                      .toLowerCase();

                  final matchSearch =
                      _search.isEmpty ||
                      student.contains(_search) ||
                      course.contains(_search);
                  final matchStatus =
                      _statusFilter == 'all' || status == _statusFilter;

                  return matchSearch && matchStatus;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.how_to_reg_outlined,
                          size: 56,
                          color: context.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          all.isEmpty
                              ? 'No enrollments yet'
                              : 'No results for "$_search"',
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Count badge
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${filtered.length} enrollment${filtered.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (all.length != filtered.length)
                            Text(
                              ' of ${all.length}',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final data =
                              filtered[i].data() as Map<String, dynamic>;
                          final studentName = (data['studentName'] ?? '')
                              .toString();
                          final courseTitle =
                              (data['courseTitle'] ??
                                      data['courseName'] ??
                                      'Unknown Course')
                                  .toString();
                          final status = (data['status'] ?? 'active')
                              .toString();
                          final paid = data['paid'] == true;
                          final enrolledAt = _formatDate(data['enrolledAt']);

                          final statusColor = status == 'completed'
                              ? Colors.green
                              : status == 'active'
                              ? Colors.blue
                              : Colors.grey;

                          return Card(
                            elevation: 0,
                            color: Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                                width: 0.8,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(
                                      0xFF0E7C86,
                                    ).withValues(alpha: 0.12),
                                    child: Text(
                                      studentName.isNotEmpty
                                          ? studentName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Color(0xFF0E7C86),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          studentName.isNotEmpty
                                              ? studentName
                                              : 'Unknown Student',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: context.textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          courseTitle,
                                          style: TextStyle(
                                            color: context.textSecondary,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            _chip(status, statusColor),
                                            if (paid)
                                              _chip('Paid', Colors.green),
                                            _chip(
                                              'Enrolled $enrolledAt',
                                              Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
    ),
  );
}
