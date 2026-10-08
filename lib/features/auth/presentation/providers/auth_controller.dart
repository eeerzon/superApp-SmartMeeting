import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.error});

  final User? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> login({required String email, required String password}) async {
    state = const AuthState(isLoading: true);
    try {
      final user = await ref.read(authRepositoryProvider).login(email: email, password: password);
      state = AuthState(user: user);
      return true;
    } on AuthException catch (e) {
      state = AuthState(error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl());

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
