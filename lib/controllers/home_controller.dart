import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/course_model.dart';
import '../models/guest_home_content.dart';
import '../models/mentor_model.dart';
import '../routes/app_routes.dart';

class HomeController {
  const HomeController();

  List<GuestCourse> getFeaturedCourses() => GuestHomeContent.featuredCourses;

  List<CourseModel> getCourseModels() => CourseModel.dummyCourses;

  List<MentorModel> getTopMentors() => MentorModel.dummyMentors;

  List<GuestCourse> filterCourses({required String query, String? category}) {
    final normalizedQuery = query.trim().toLowerCase();

    return GuestHomeContent.featuredCourses.where((course) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          course.title.toLowerCase().contains(normalizedQuery) ||
          course.description.toLowerCase().contains(normalizedQuery) ||
          course.category.toLowerCase().contains(normalizedQuery);
      final matchesCategory =
          category == null || category.isEmpty || course.category == category;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  void openLogin(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.login);
  }

  void openRegister(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.register);
  }

  void openSearch(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.search);
  }

  void openCourseList(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.courseList);
  }

  void openAbout(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.about);
  }

  void openMentors(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.mentors);
  }

  void openContact(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.contact);
  }

  void openFaq(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.faq);
  }

  void openWishlist(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.of(context).pushNamed(AppRoutes.studentWishlist);
      return;
    }
    showGuestLoginPrompt(context);
    openLogin(context);
  }

  void openGuestNotifications(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.of(context).pushNamed(AppRoutes.studentNotifications);
      return;
    }
    showGuestLoginPrompt(context);
    openLogin(context);
  }

  void openGuestChat(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.of(context).pushNamed(AppRoutes.studentChat);
      return;
    }
    showGuestLoginPrompt(context);
    openLogin(context);
  }

  void bookMentorship(BuildContext context, MentorModel mentor) {
    if (FirebaseAuth.instance.currentUser == null) {
      showGuestLoginPrompt(context);
      openLogin(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connecting you with ${mentor.name} in chat...')),
    );
    Navigator.of(context).pushNamed(AppRoutes.studentChat);
  }

  void showGuestLoginPrompt(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Please login to continue')));
  }

  void openGuestCourseDetail(BuildContext context, GuestCourse course) {
    Navigator.of(context).pushNamed(
      AppRoutes.courseDetailPublic,
      arguments: {
        'title': course.title,
        'category': course.category,
        'instructor': course.instructor,
        'description': course.description,
        'rating': course.rating,
        'thumbnailAsset': course.thumbnailAsset,
        'duration': course.duration,
        'level': course.level,
        'priceLabel': course.priceLabel,
        'highlights': course.highlights,
      },
    );
  }

  void openGuestCourseDetailFromModel(
    BuildContext context,
    CourseModel course,
  ) {
    Navigator.of(context).pushNamed(
      AppRoutes.courseDetailPublic,
      arguments: {
        'title': course.title,
        'category': course.category,
        'instructor': course.instructorName,
        'description': course.description,
        'rating': course.rating,
        'thumbnailAsset': course.thumbnailAsset,
        'duration': course.duration,
        'level': course.level,
        'priceLabel': course.priceLabel,
        'highlights': course.highlights,
      },
    );
  }

  void requireAuthenticationForEnrollment(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Login required'),
          content: const Text('Please login to continue'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openLogin(context);
              },
              child: const Text('Login'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openRegister(context);
              },
              child: const Text('Register'),
            ),
          ],
        );
      },
    );
  }

  void promptGuestAccess(BuildContext context, GuestCourse course) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            course.thumbnailAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: course.accentColor.withValues(
                                  alpha: 0.16,
                                ),
                                child: Center(
                                  child: Icon(
                                    course.icon,
                                    size: 56,
                                    color: course.accentColor,
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.45),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                course.category,
                                style: TextStyle(
                                  color: course.accentColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Text(
                              course.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Instructor: ${course.instructor}',
                    style: Theme.of(sheetContext).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.star, size: 16),
                        label: Text(course.rating.toStringAsFixed(1)),
                      ),
                      Chip(
                        avatar: const Icon(Icons.schedule, size: 16),
                        label: Text(course.duration),
                      ),
                      Chip(
                        avatar: const Icon(Icons.trending_up, size: 16),
                        label: Text(course.level),
                      ),
                      Chip(
                        avatar: const Icon(Icons.payments, size: 16),
                        label: Text(course.priceLabel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    course.description,
                    style: Theme.of(
                      sheetContext,
                    ).textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'What you will learn',
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...course.highlights.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.check_circle, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Guest preview is available. Log in or register to enroll and continue.',
                    style: Theme.of(sheetContext).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            openRegister(context);
                          },
                          child: const Text('Join Now'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            openLogin(context);
                          },
                          child: const Text('Login'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void openSectionLink(BuildContext context, String title) {
    if (title == 'About Us') {
      openAbout(context);
      return;
    }

    if (title == 'Browse Courses') {
      openCourseList(context);
      return;
    }

    if (title == 'Mentors') {
      openMentors(context);
      return;
    }

    if (title == 'FAQ') {
      openFaq(context);
      return;
    }

    if (title == 'Contact') {
      openContact(context);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title will be available soon.')));
  }
}
