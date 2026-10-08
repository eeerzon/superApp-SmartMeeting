import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/session/meeting_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/providers/settings_controller.dart';
import '../providers/device_management_providers.dart';
import '../providers/room_devices_controller.dart';
import '../widgets/device_detail_panel.dart';
import '../widgets/device_type_tabs.dart';
import '../widgets/device_unit_list.dart';

class DeviceManagementPage extends ConsumerWidget {
  const DeviceManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomDevicesProvider);
    if (state.isLoading) return const Center(child: CircularProgressIndicator());

    final type = ref.watch(selectedDeviceTypeProvider);
    final selectedUnits = ref.watch(selectedUnitsProvider);
    final room = roomById(ref.watch(settingsControllerProvider).roomId);

    final units = state.ofType(type);
    final selectedId = selectedUnits[type] ?? units.first.id;
    final device = state.device(selectedId);
    final offlineTypes = state.devices.values.where((d) => !d.online).map((d) => d.type).toSet();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppLayout.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Manajemen Perangkat',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6),
          ),
          const SizedBox(height: 4),
          Text(
            'Konfigurasi detail setiap perangkat di ${room.name}',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          DeviceTypeTabs(
            selected: type,
            typesWithOfflineUnits: offlineTypes,
            onSelected: (t) => ref.read(selectedDeviceTypeProvider.notifier).state = t,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: AppLayout.unitListWidth,
                child: DeviceUnitList(
                  units: units,
                  selectedId: selectedId,
                  statusOf: state.statusOf,
                  onSelected: (id) => ref.read(selectedUnitsProvider.notifier).state = {...selectedUnits, type: id},
                ),
              ),
              const SizedBox(width: AppLayout.gap),
              Expanded(
                child: DeviceDetailPanel(
                  key: ValueKey(selectedId),
                  device: device,
                  status: state.statusOf(selectedId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
