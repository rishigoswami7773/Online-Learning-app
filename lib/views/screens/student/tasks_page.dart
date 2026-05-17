import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/uid_resolver.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

const Color _primary = Color(0xff6A5AE0);

class _TasksPageState extends State<TasksPage> {
  String _formatDueDate(Timestamp? dueDate) {
    if (dueDate == null) {
      return 'No due date';
    }

    final date = dueDate.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _toggleTaskDone(String docId, bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('tasks/$uid/items')
        .doc(docId)
        .update({'isDone': value});
  }

  Future<void> _deleteTask(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('tasks/$uid/items')
        .doc(docId)
        .delete();
  }

  Future<void> _showAddTaskDialog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    // FIX: initialise to non-null so showDatePicker initialDate never gets null
    DateTime selectedDate = DateTime.now();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Add Task'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a task title'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatDueDate(Timestamp.fromDate(selectedDate)),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                // FIX: selectedDate is now non-nullable DateTime
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 1),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              // picked can still be null if user cancels — handle safely
                              if (picked == null) return;
                              setDialogState(() => selectedDate = picked);
                            },
                            child: const Text('Pick date'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (!(formKey.currentState?.validate() ?? false)) {
                        return;
                      }

                      await FirebaseFirestore.instance
                          .collection('tasks/$uid/items')
                          .add({
                            'title': titleController.text.trim(),
                            'dueDate': Timestamp.fromDate(selectedDate),
                            'isDone': false,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      titleController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),

      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text("Tasks"),
        backgroundColor: _primary,
        elevation: 0,
      ),

      body: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff6A5AE0), Color(0xff8E7BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Tasks",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Complete your learning tasks",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          /// TASK LIST
          Expanded(
            child: UidResolver.uid == null
                ? const Center(child: Text('Sign in to manage your tasks.'))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('tasks/${UidResolver.uid}/items')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Unable to load tasks.'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final tasks = snapshot.data?.docs ?? const [];
                      if (tasks.isEmpty) {
                        return const Center(
                          child: Text('No tasks yet. Tap + to add one.'),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: tasks.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final taskDoc = tasks[idx];
                          final data = taskDoc.data();
                          final title = (data['title'] ?? 'Untitled Task')
                              .toString();
                          final dueDate = data['dueDate'] as Timestamp?;
                          final done = data['isDone'] == true;

                          return Dismissible(
                            key: ValueKey(taskDoc.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) => _deleteTask(taskDoc.id),
                            child: _taskCard(
                              context,
                              docId: taskDoc.id,
                              title: title,
                              due: _formatDueDate(dueDate),
                              done: done,
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _taskCard(
    BuildContext context, {
    required String docId,
    required String title,
    required String due,
    required bool done,
  }) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text("Due: $due"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),

          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          children: [
            /// STATUS ICON
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: done
                    ? Colors.green.withValues(alpha: .1)
                    : _primary.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check_circle : Icons.pending_actions,
                color: done ? Colors.green : _primary,
              ),
            ),

            const SizedBox(width: 14),

            /// TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(due, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),

            /// CHECKBOX
            Checkbox(
              value: done,
              fillColor: WidgetStatePropertyAll(_primary),
              onChanged: (bool? v) async {
                if (v == null) return;
                await _toggleTaskDone(docId, v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
