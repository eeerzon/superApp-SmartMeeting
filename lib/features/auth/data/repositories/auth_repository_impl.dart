import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Demo account accepted by the mock repository.
abstract final class DemoAccount {
  static const email = 'admin@ruangmeeting.local';
  static const password = 'admin123';
  static const name = 'Administrator';
}

/// Mock implementation. TODO: call AuthRemoteDataSource and store the token
/// in SecureStorage.
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<User> login({required String email, required String password}) async {
    await Future<void>.delayed(AppConstants.mockLoginLatency);
    if (email.toLowerCase() != DemoAccount.email || password != DemoAccount.password) {
      throw const AuthException('Email atau password salah.');
    }
    return User(
      id: 'u-001',
      name: DemoAccount.name,
      email: DemoAccount.email,
      role: UserRole.admin,
      signedInAt: DateTime.now(),
    );
  }

  @override
  Future<void> logout() async {}
}
