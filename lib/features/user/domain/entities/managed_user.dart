import '../../../auth/domain/entities/user.dart';

/// A user account as shown in "Kelola User".
class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roomAccess,
    this.active = true,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;

  /// Human readable, e.g. "Semua ruangan" or "Inovasi, Kolaborasi".
  final String roomAccess;
  final bool active;

  String get initials => initialsOf(name);

  ManagedUser copyWith({String? name, String? email, UserRole? role, String? roomAccess, bool? active}) {
    return ManagedUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      roomAccess: roomAccess ?? this.roomAccess,
      active: active ?? this.active,
    );
  }
}
