import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/devices/presentation/pages/device_management_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/user/presentation/pages/user_page.dart';
import '../../shared/layout/app_shell.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Bridges auth state to go_router so redirects re-run on login/logout.
  final loggedIn = ValueNotifier<bool>(ref.read(authControllerProvider).isAuthenticated);
  ref.listen<AuthState>(
    authControllerProvider,
    (_, next) => loggedIn.value = next.isAuthenticated,
  );
  ref.onDispose(loggedIn.dispose);

  return GoRouter(
    initialLocation: RoutePaths.login,
    refreshListenable: loggedIn,
    redirect: (context, state) {
      final atLogin = state.matchedLocation == RoutePaths.login;
      if (!loggedIn.value) return atLogin ? null : RoutePaths.login;
      if (atLogin) return RoutePaths.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.dashboard,
              pageBuilder: (context, state) => const NoTransitionPage(child: DashboardPage()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.devices,
              pageBuilder: (context, state) => const NoTransitionPage(child: DeviceManagementPage()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.settings,
              pageBuilder: (context, state) => const NoTransitionPage(child: SettingsPage()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.user,
              pageBuilder: (context, state) => const NoTransitionPage(child: UserPage()),
            ),
          ]),
        ],
      ),
    ],
  );
});
