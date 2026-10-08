import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/realtime/connection_status.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import 'widgets/connection_banner.dart';
import 'widgets/side_nav.dart';
import 'widgets/top_bar.dart';

/// Layout after login (landscape): sidebar | top bar + page.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(serverConnectionProvider);

    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SideNav(
              currentIndex: navigationShell.currentIndex,
              onSelect: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
              onLogout: () => _logout(context, ref),
            ),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TopBar(onAvatarTap: () => navigationShell.goBranch(3)),
                  if (!online) const ConnectionBanner(),
                  Expanded(child: navigationShell),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
