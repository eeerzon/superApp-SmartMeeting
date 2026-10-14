import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/layout/app_layout.dart';
import '../../core/realtime/connection_status.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import 'widgets/connection_banner.dart';
import 'widgets/side_nav.dart';
import 'widgets/side_nav_toggle.dart';
import 'widgets/top_bar.dart';

/// Layout after login (landscape): sidebar | top bar + page.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _collapsedWidth = 12.0;
  static const _animation = Duration(milliseconds: 250);

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
    final collapsed = ref.watch(sideNavCollapsedProvider);
    // Sidebar width incl. its 1px right border; collapsed keeps a thin strip
    // so the floating chevron is anchored to something.
    final sideWidth = collapsed ? _collapsedWidth : AppLayout.sidebarWidth + 1;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: _animation,
                  curve: Curves.easeOut,
                  width: sideWidth,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(right: BorderSide(color: AppColors.border)),
                  ),
                  // Keep the menu at full width while the container animates,
                  // so its content is clipped instead of reflowing.
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: AppLayout.sidebarWidth,
                    maxWidth: AppLayout.sidebarWidth,
                    child: IgnorePointer(
                      ignoring: collapsed,
                      child: AnimatedOpacity(
                        duration: _animation,
                        opacity: collapsed ? 0 : 1,
                        child: SideNav(
                          currentIndex: navigationShell.currentIndex,
                          onSelect: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
                          onLogout: () => _logout(context, ref),
                        ),
                      ),
                    ),
                  ),
                ),
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
            // Floating chevron, vertically centred on the sidebar edge.
            AnimatedPositioned(
              duration: _animation,
              curve: Curves.easeOut,
              left: sideWidth - 1,
              top: 0,
              bottom: 0,
              child: Center(
                child: SideNavToggle(
                  collapsed: collapsed,
                  onTap: () => ref.read(sideNavCollapsedProvider.notifier).state = !collapsed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
