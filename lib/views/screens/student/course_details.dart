import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CourseReview {
  final String id;
  final String courseId;
  final String studentId;
  final String studentName;
  final double rating; // 1-5 stars
  final String reviewText;
  final DateTime createdAt;

  CourseReview({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.studentName,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
  });

  factory CourseReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseReview(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewText: data['reviewText'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'courseId': courseId,
    'studentId': studentId,
    'studentName': studentName,
    'rating': rating,
    'reviewText': reviewText,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class CourseDetailsPage extends StatefulWidget {
  final String courseId;

  const CourseDetailsPage({super.key, required this.courseId});

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  String? _existingReviewId;
  bool _hasReviewed = false;

  @override
  void initState() {
    super.initState();
    _loadExistingReview();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingReview() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snap = await _firestore
          .collection('course_reviews')
          .where('studentId', isEqualTo: user.uid)
          .where('courseId', isEqualTo: widget.courseId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty && mounted) {
        final data = snap.docs.first.data();
        setState(() {
          _selectedRating = (data['rating'] as num?)?.toInt() ?? 0;
          _reviewController.text = (data['reviewText'] as String?) ?? '';
          _existingReviewId = snap.docs.first.id;
          _hasReviewed = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0 || _reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide rating and review')),
      );
      return;
    }

    try {
      final wasExistingReview = _existingReviewId != null;
      final user = _auth.currentUser;
      if (user == null) return;

      final userData = await _firestore.collection('users').doc(user.uid).get();

      // Check if user already reviewed this course
      final existingReview = await _firestore
          .collection('course_reviews')
          .where('courseId', isEqualTo: widget.courseId)
          .where('studentId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existingReview.docs.isNotEmpty) {
        // Update existing review
        await _firestore
            .collection('course_reviews')
            .doc(existingReview.docs[0].id)
            .update({
              'rating': _selectedRating,
              'reviewText': _reviewController.text,
              'createdAt': Timestamp.now(),
            });
      } else {
        // Create new review
        await _firestore.collection('course_reviews').add({
          'courseId': widget.courseId,
          'studentId': user.uid,
          'studentName': userData['name'] ?? 'Student',
          'rating': _selectedRating,
          'reviewText': _reviewController.text,
          'createdAt': Timestamp.now(),
        });
      }

      // The UI stayed editable before the local review state flipped.
      _hasReviewed = true;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasExistingReview
                ? 'Review updated successfully!'
                : 'Review submitted successfully!',
          ),
          // The saved review now renders read-only instead of staying editable.
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff6A5AE0);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Course Details'),
          backgroundColor: primaryColor,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'About'),
              Tab(text: 'Reviews'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAboutTab(primaryColor),
            _buildReviewsTab(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab(Color primaryColor) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('courses').doc(widget.courseId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Course not found'));
        }

        final course = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Title
              Text(
                course['title'] ?? 'Course Title',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Rating Summary
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    course['averageRating']?.toStringAsFixed(1) ?? '4.5',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${course['reviewCount'] ?? 0} reviews)',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'About this course',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                course['description'] ??
                    'This is a comprehensive course designed to teach you everything you need to know.',
                style: const TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 20),

              // Course Details
              Text(
                'Course Details',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailItem(
                Icons.person,
                'Instructor',
                course['mentorName'] ?? 'Expert Mentor',
              ),
              _buildDetailItem(
                Icons.leaderboard,
                'Level',
                course['level'] ?? 'Intermediate',
              ),
              _buildDetailItem(
                Icons.timer,
                'Duration',
                '${course['durationHours'] ?? 10} hours',
              ),
              _buildDetailItem(
                Icons.book,
                'Lessons',
                '${course['lessonCount'] ?? 8} lessons',
              ),
              const SizedBox(height: 20),

              // What You'll Learn
              Text(
                'What You\'ll Learn',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...(course['learningPoints'] as List? ?? []).map<Widget>(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(point as String)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(Color primaryColor) {
    final user = _auth.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user != null) ...[
            if (_hasReviewed)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Review',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _hasReviewed = false),
                            child: const Text('Edit Review'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 32,
                            color: index < _selectedRating
                                ? Colors.amber
                                : Colors.grey,
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _reviewController.text.trim().isEmpty
                            ? 'No review text provided.'
                            : _reviewController.text.trim(),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Text(
                'Write a Review',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Star Rating
              Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRating = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.star,
                        size: 32,
                        color: index < _selectedRating
                            ? Colors.amber
                            : Colors.grey,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Review Text
              TextField(
                controller: _reviewController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your experience with this course...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: Text(
                    _existingReviewId == null
                        ? 'Submit Review'
                        : 'Update Review',
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Divider(),
            const SizedBox(height: 16),
          ],

          Text(
            'All Reviews',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Reviews List
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('course_reviews')
                .where('courseId', isEqualTo: widget.courseId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final reviews = snapshot.data?.docs ?? [];

              if (reviews.isEmpty) {
                return const Center(
                  child: Text('No reviews yet. Be the first to review!'),
                );
              }

              return Column(
                children: reviews.map((doc) {
                  final review = CourseReview.fromFirestore(doc);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: primaryColor.withValues(
                                  alpha: .2,
                                ),
                                child: Text(
                                  review.studentName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review.studentName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          Icons.star,
                                          size: 16,
                                          color: index < review.rating.toInt()
                                              ? Colors.amber
                                              : Colors.grey,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                review.createdAt.toString().split('.')[0],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(review.reviewText),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
