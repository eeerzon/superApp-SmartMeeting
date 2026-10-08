enum UserRole {
  admin('Admin'),
  operator('Operator'),
  guest('Tamu');

  const UserRole(this.label);
  final String label;
}

/// "Rina Kartika" -> "RK"
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.signedInAt,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime signedInAt;

  String get initials => initialsOf(name);
}
