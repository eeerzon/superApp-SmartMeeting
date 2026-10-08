import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../devices/domain/entities/device.dart';
import '../../../../devices/domain/entities/device_type.dart';
import '../../../../devices/presentation/device_commands.dart';
import '../../../../devices/presentation/device_icons.dart';
import '../../../../devices/presentation/providers/room_devices_controller.dart';
import 'tile_controls.dart';
import 'tile_frame.dart';

/// Door has no power switch: it shows the lock state and lock/unlock buttons.
class DoorTile extends ConsumerWidget {
  const DoorTile({super.key, required this.device, required this.linkStatus});

  final DoorDevice device;
  final DeviceLinkStatus linkStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = device.locked;
    return DashboardTileFrame(
      title: DeviceType.door.title,
      icon: DeviceType.door.icon,
      linkStatus: linkStatus,
      active: true,
      statusText: locked ? 'Terkunci' : 'Terbuka',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                  child: Icon(
                    locked ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                    size: 24,
                    color: locked ? AppColors.red600 : AppColors.online,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locked ? 'Pintu terkunci' : 'Pintu terbuka',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        device.autoLock
                            ? 'Kunci otomatis ${device.autoLockDelay.seconds} detik'
                            : 'Kunci otomatis nonaktif',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TileChoiceButton(
                  horizontal: true,
                  icon: Icons.lock_open_rounded,
                  label: 'Buka',
                  selected: !locked,
                  onTap: () => setDoorLocked(context, ref, device, lock: false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TileChoiceButton(
                  horizontal: true,
                  icon: Icons.lock_outline_rounded,
                  label: 'Kunci',
                  selected: locked,
                  onTap: () => setDoorLocked(context, ref, device, lock: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
