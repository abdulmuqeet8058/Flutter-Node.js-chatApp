class User {
  final String id;
  final String username;
  final String? createdAt;
  final bool online;

  const User({
    required this.id,
    required this.username,
    this.createdAt,
    this.online = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      createdAt: json['createdAt'] as String?,
      online: json['online'] as bool? ?? false,
    );
  }
}
