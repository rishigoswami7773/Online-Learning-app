import 'package:flutter/material.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

const Color _primary = Color(0xff6A5AE0);

class _TasksPageState extends State<TasksPage> {
  // Mutable list of todos kept in state so checkboxes and interactions work
  final List<Map<String, dynamic>> _todos = [
    {'title': 'Submit Assignment 2', 'due': 'Today 11:59 PM', 'done': false},
    {'title': 'Watch Lesson 6', 'due': 'Tomorrow', 'done': true},
    {'title': 'Participate in Quiz', 'due': 'Friday', 'done': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
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
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _todos.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),

              itemBuilder: (context, idx) {
                final task = _todos[idx];
                final done = task['done'] as bool;

                return _taskCard(
                  context,
                  index: idx,
                  title: task['title'] as String,
                  due: task['due'] as String,
                  done: done,
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
    required int index,
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
              activeColor: _primary,
              onChanged: (bool? v) {
                if (v == null) return;
                setState(() {
                  _todos[index]['done'] = v;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
