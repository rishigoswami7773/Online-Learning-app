class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String profileImage;
  final String password;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.profileImage = '',
    this.password = '',
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: (map['email'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      role: (map['role'] ?? 'student').toString().toLowerCase(),
      profileImage: (map['profileImage'] ?? '').toString(),
      password: (map['password'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': uid,
      'email': email,
      'name': name,
      'role': role,
      'profileImage': profileImage,
      'password': password,
    };
  }
}
