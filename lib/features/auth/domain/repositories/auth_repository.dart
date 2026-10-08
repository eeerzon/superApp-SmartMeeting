import '../entities/user.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

abstract interface class AuthRepository {
  /// Throws [AuthException] when the credentials are rejected.
  Future<User> login({required String email, required String password});

  Future<void> logout();
}
