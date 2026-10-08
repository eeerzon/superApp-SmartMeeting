import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/repositories/user_repository.dart';

/// Mock implementation. TODO: user management API.
class UserRepositoryImpl implements UserRepository {
  final List<ManagedUser> _users = [
    const ManagedUser(
      id: 'u-001',
      name: DemoAccount.name,
      email: DemoAccount.email,
      role: UserRole.admin,
      roomAccess: 'Semua ruangan',
    ),
    const ManagedUser(
      id: 'u-002',
      name: 'Rina Kartika',
      email: 'rina.k@ruangmeeting.local',
      role: UserRole.operator,
      roomAccess: 'Inovasi, Kolaborasi',
    ),
    const ManagedUser(
      id: 'u-003',
      name: 'Budi Santoso',
      email: 'budi.s@ruangmeeting.local',
      role: UserRole.operator,
      roomAccess: 'Inovasi',
    ),
    const ManagedUser(
      id: 'u-004',
      name: 'Akun Tamu',
      email: 'tamu.inovasi@ruangmeeting.local',
      role: UserRole.guest,
      roomAccess: 'Inovasi',
      active: false,
    ),
  ];

  @override
  Future<List<ManagedUser>> fetchUsers() async => List.of(_users);

  @override
  Future<ManagedUser> saveUser(ManagedUser user) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      _users[index] = user;
    } else {
      _users.add(user);
    }
    return user;
  }

  @override
  Future<void> changePassword({required String current, required String next}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (current != DemoAccount.password) throw const UserException('Password saat ini salah.');
  }
}
