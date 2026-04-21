class MentorModel {
  const MentorModel({
    required this.name,
    required this.expertise,
    required this.rating,
    required this.bio,
  });

  final String name;
  final String expertise;
  final double rating;
  final String bio;

  static const List<MentorModel> dummyMentors = [
    MentorModel(
      name: 'Priya Nair',
      expertise: 'Flutter Development',
      rating: 4.9,
      bio: 'Builds production Flutter apps and mentors mobile developers.',
    ),
    MentorModel(
      name: 'Rahul Verma',
      expertise: 'Data Analytics',
      rating: 4.8,
      bio:
          'Specializes in turning business questions into data-driven decisions.',
    ),
    MentorModel(
      name: 'Aisha Khan',
      expertise: 'UI/UX Design',
      rating: 4.7,
      bio: 'Helps teams design user-friendly interfaces and seamless journeys.',
    ),
    MentorModel(
      name: 'Arjun Patel',
      expertise: 'Business Strategy',
      rating: 4.8,
      bio: 'Guides professionals in strategic planning and execution.',
    ),
  ];
}
