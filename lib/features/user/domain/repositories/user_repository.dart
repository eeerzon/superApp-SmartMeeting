import '../entities/managed_user.dart';

abstract interface class UserRepository {
  Future<List<ManagedUser>> fetchUsers();
  Future<ManagedUser> saveUser(ManagedUser user);
  Future<void> changePassword({required String current, required String next});
}

class UserException implements Exception {
  const UserException(this.message);
  final String message;
}
