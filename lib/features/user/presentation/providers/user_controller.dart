import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/repositories/user_repository.dart';

class UserListController extends AsyncNotifier<List<ManagedUser>> {
  UserRepository get _repo => ref.read(userRepositoryProvider);

  @override
  Future<List<ManagedUser>> build() => _repo.fetchUsers();

  Future<void> save(ManagedUser user) async {
    final saved = await _repo.saveUser(user);
    final current = state.valueOrNull ?? const <ManagedUser>[];
    final exists = current.any((u) => u.id == saved.id);
    state = AsyncData(
      exists ? [for (final u in current) u.id == saved.id ? saved : u] : [...current, saved],
    );
  }

  Future<void> setActive(ManagedUser user, bool active) => save(user.copyWith(active: active));
}

final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepositoryImpl());

final userListProvider =
    AsyncNotifierProvider<UserListController, List<ManagedUser>>(UserListController.new);
