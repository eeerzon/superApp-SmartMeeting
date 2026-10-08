import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/layout/app_layout.dart';
import '../../../../core/session/meeting_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../devices/presentation/providers/activity_log_provider.dart';
import '../../../settings/presentation/providers/settings_controller.dart';
import '../../domain/entities/managed_user.dart';
import '../providers/user_controller.dart';
import '../widgets/activity_card.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/profile_card.dart';
import '../widgets/user_form_dialog.dart';
import '../widgets/user_management_card.dart';

class UserPage extends ConsumerWidget {
  const UserPage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Keluar dari aplikasi?',
      message: 'Perangkat di ruangan tetap berjalan. Anda perlu masuk lagi untuk mengendalikannya.',
      confirmLabel: 'Keluar',
      icon: Icons.logout_rounded,
      destructive: true,
    );
    if (confirmed) await ref.read(authControllerProvider.notifier).logout();
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final changed = await showChangePasswordDialog(context, repository: ref.read(userRepositoryProvider));
    if (changed && context.mounted) showAppToast(context, 'Password berhasil diubah');
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref, List<ManagedUser> users, {ManagedUser? initial}) async {
    final room = roomById(ref.read(settingsControllerProvider).roomId);
    final result = await showUserFormDialog(
      context,
      initial: initial,
      takenEmails: {
        for (final u in users)
          if (u.id != initial?.id) u.email.toLowerCase(),
      },
      defaultRoomAccess: room.name.replaceFirst('Ruang ', ''),
    );
    if (result == null || !context.mounted) return;
    await ref.read(userListProvider.notifier).save(result);
    if (context.mounted) {
      showAppToast(context, initial == null ? 'User ${result.name} ditambahkan' : 'Data user diperbarui');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const SizedBox.shrink();

    final room = roomById(ref.watch(settingsControllerProvider).roomId);
    final activity = ref.watch(activityLogProvider);
    final usersAsync = ref.watch(userListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppLayout.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('User', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
          const SizedBox(height: 4),
          const Text(
            'Profil Anda dan pengelolaan akses pengguna',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: AppLayout.profileColumnWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileCard(
                      user: user,
                      roomName: room.name,
                      onChangePassword: () => _changePassword(context, ref),
                      onLogout: () => _logout(context, ref),
                    ),
                    const SizedBox(height: AppLayout.gap),
                    ActivityCard(entries: activity),
                  ],
                ),
              ),
              const SizedBox(width: AppLayout.gap),
              Expanded(
                child: usersAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('Gagal memuat user: $e'),
                  data: (users) => UserManagementCard(
                    users: users,
                    currentUserId: user.id,
                    onAdd: () => _openForm(context, ref, users),
                    onEdit: (u) => _openForm(context, ref, users, initial: u),
                    onToggleActive: (u, active) async {
                      await ref.read(userListProvider.notifier).setActive(u, active);
                      if (context.mounted) {
                        showAppToast(context, '${u.name} ${active ? 'diaktifkan' : 'dinonaktifkan'}');
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
