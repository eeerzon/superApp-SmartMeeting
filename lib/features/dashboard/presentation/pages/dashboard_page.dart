import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/session/meeting_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../devices/domain/entities/device_type.dart';
import '../../../devices/presentation/providers/room_devices_controller.dart';
import '../../../scenes/presentation/widgets/quick_scene_bar.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/device_grid.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomDevicesProvider);
    if (state.isLoading) return const Center(child: CircularProgressIndicator());

    final name = ref.watch(authControllerProvider).user?.name ?? '';
    final meeting = ref.watch(currentMeetingProvider);
    const powered = [DeviceType.ac, DeviceType.light, DeviceType.audio, DeviceType.ifp, DeviceType.camera];
    final poweredOn = powered.where((t) => state.ofType(t).first.isOn).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppLayout.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardHeader(
            title: 'Selamat ${greetingFor(DateTime.now())}, $name',
            subtitle: '$poweredOn dari ${powered.length} perangkat menyala · ${meeting.title} sedang berlangsung',
          ),
          const SizedBox(height: 16),
          const DashboardSectionTitle(
            title: 'Quick Scene',
            trailing: Text(
              'Satu sentuhan untuk mengatur semua perangkat',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 6),
          const QuickSceneBar(),
          const SizedBox(height: 20),
          DashboardSectionTitle(
            title: 'Perangkat Ruangan',
            trailing: TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.red600, minimumSize: const Size(0, 44)),
              onPressed: () => context.go(RoutePaths.devices),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Kelola perangkat', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          DeviceGrid(state: state),
        ],
      ),
    );
  }
}
