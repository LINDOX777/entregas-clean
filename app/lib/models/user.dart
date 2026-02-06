class UserPublic {
  final int id;
  final String name;
  final String username;
  final String role;
  final List<String> companies;

  UserPublic({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.companies = const [],
  });

  factory UserPublic.fromJson(Map<String, dynamic> json) {
    return UserPublic(
      id: json["id"],
      name: json["name"],
      username: json["username"],
      role: json["role"],
      companies: List<String>.from(json["companies"] ?? []),
    );
  }
}
