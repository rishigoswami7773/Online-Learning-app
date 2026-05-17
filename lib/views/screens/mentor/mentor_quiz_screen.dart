import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/app_auth_controller.dart';

/// Mentor quiz creation and management screen
class MentorQuizScreen extends StatefulWidget {
  const MentorQuizScreen({super.key, this.courseId = '', this.moduleId = ''});

  final String courseId;
  final String moduleId;

  @override
  State<MentorQuizScreen> createState() => _MentorQuizScreenState();
}

class _MentorQuizScreenState extends State<MentorQuizScreen> {
  CollectionReference<Map<String, dynamic>> get _quizzesCollection =>
      FirebaseFirestore.instance.collection('quizzes');

  String get _mentorId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _openQuizEditor({
    QueryDocumentSnapshot<Map<String, dynamic>>? quiz,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuizEditorSheet(
        courseId: widget.courseId,
        moduleId: widget.moduleId,
        mentorId: _mentorId,
        quizId: quiz?.id,
        initialTitle: quiz?.data()['title']?.toString() ?? '',
        initialQuestions: _parseQuestions(quiz?.data()['questions']),
      ),
    );
  }

  List<Map<String, dynamic>> _parseQuestions(Object? rawQuestions) {
    if (rawQuestions is! List) return const [];
    return rawQuestions
        .whereType<Map>()
        .map((question) => Map<String, dynamic>.from(question))
        .toList();
  }

  Future<void> _deleteQuiz(String quizId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Quiz?'),
        content: Text('Delete "$title" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _quizzesCollection.doc(quizId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Quiz deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _quizzesCollection
            .where('courseId', isEqualTo: widget.courseId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load quizzes: ${snapshot.error}'),
              ),
            );
          }

          final quizzes = snapshot.data?.docs ?? const [];
          if (quizzes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No quizzes yet. Tap + to create one.'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              final data = quiz.data();
              final questions =
                  (data['questions'] as List<dynamic>? ?? const []).length;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(data['title']?.toString() ?? 'Untitled Quiz'),
                  subtitle: Text('$questions question(s)'),
                  onTap: () => _openQuizEditor(quiz: quiz),
                  onLongPress: () => _deleteQuiz(
                    quiz.id,
                    data['title']?.toString() ?? 'Untitled Quiz',
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Role guard: Only mentors can add quizzes
          final role = AppAuthController().currentUser.value?.role ?? '';
          if (role != 'mentor') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Only mentors can create quizzes.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          _openQuizEditor();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _QuizEditorSheet extends StatefulWidget {
  const _QuizEditorSheet({
    required this.courseId,
    required this.moduleId,
    required this.mentorId,
    required this.quizId,
    required this.initialTitle,
    required this.initialQuestions,
  });

  final String courseId;
  final String moduleId;
  final String mentorId;
  final String? quizId;
  final String initialTitle;
  final List<Map<String, dynamic>> initialQuestions;

  @override
  State<_QuizEditorSheet> createState() => _QuizEditorSheetState();
}

class _QuizEditorSheetState extends State<_QuizEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final List<_QuestionDraft> _questions;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _questions = widget.initialQuestions.isEmpty
        ? [_QuestionDraft.empty()]
        : widget.initialQuestions.map(_QuestionDraft.fromMap).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionDraft.empty());
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length == 1) return;
    setState(() {
      final removed = _questions.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.courseId.isEmpty || widget.mentorId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing course or mentor information')),
      );
      return;
    }

    final payload = <String, dynamic>{
      'courseId': widget.courseId,
      'moduleId': widget.moduleId,
      'mentorId': widget.mentorId,
      'title': _titleController.text.trim(),
      'questions': _questions
          .map(
            (question) => {
              'question': question.questionController.text.trim(),
              'options': question.optionControllers
                  .map((controller) => controller.text.trim())
                  .toList(),
              'correctIndex': question.correctIndex,
            },
          )
          .toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    setState(() => _saving = true);
    try {
      final docRef = widget.quizId == null
          ? FirebaseFirestore.instance.collection('quizzes').doc()
          : FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId);
      await docRef.set(payload);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save quiz: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.98,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.quizId == null ? 'Create Quiz' : 'Edit Quiz',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Quiz Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Quiz title required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ..._questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Question ${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (_questions.length > 1)
                                    IconButton(
                                      onPressed: () => _removeQuestion(index),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: question.questionController,
                                decoration: const InputDecoration(
                                  labelText: 'Question text',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                    ? 'Question required'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(4, (optionIndex) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () {
                                          setState(() {
                                            question.correctIndex = optionIndex;
                                          });
                                        },
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          margin: const EdgeInsets.only(
                                            right: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  question.correctIndex ==
                                                      optionIndex
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                  : Colors.grey.shade400,
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Container(
                                              width: 16,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    question.correctIndex ==
                                                        optionIndex
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Colors.transparent,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextFormField(
                                          controller: question
                                              .optionControllers[optionIndex],
                                          decoration: InputDecoration(
                                            labelText:
                                                'Option ${optionIndex + 1}',
                                            border: const OutlineInputBorder(),
                                          ),
                                          validator: (value) =>
                                              (value == null ||
                                                  value.trim().isEmpty)
                                              ? 'Option required'
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Question'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveQuiz,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuestionDraft {
  _QuestionDraft({
    required this.questionController,
    required this.optionControllers,
    required this.correctIndex,
  });

  factory _QuestionDraft.empty() {
    return _QuestionDraft(
      questionController: TextEditingController(),
      optionControllers: List.generate(4, (_) => TextEditingController()),
      correctIndex: 0,
    );
  }

  factory _QuestionDraft.fromMap(Map<String, dynamic> data) {
    final options = (data['options'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();

    return _QuestionDraft(
      questionController: TextEditingController(
        text: data['question']?.toString() ?? '',
      ),
      optionControllers: List.generate(
        4,
        (index) => TextEditingController(
          text: index < options.length ? options[index] : '',
        ),
      ),
      correctIndex: (data['correctIndex'] as num?)?.toInt() ?? 0,
    );
  }

  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  int correctIndex;

  void dispose() {
    questionController.dispose();
    for (final controller in optionControllers) {
      controller.dispose();
    }
  }
}
