class User {
  final int userId;
  final String username;
  final String email;
  final String role;
  final DateTime createdAt;

  User({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
