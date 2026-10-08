import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_gradients.dart';
import '../../../../../core/utils/time_format.dart';
import '../../../domain/entities/device.dart';
import '../../../domain/entities/device_options.dart';
import '../../../domain/entities/device_type.dart';
import '../../device_commands.dart';
import '../../device_icons.dart';
import '../../providers/activity_log_provider.dart';
import '../common/option_pills.dart';
import '../common/setting_row.dart';

class DoorSetupPanel extends ConsumerWidget {
  const DoorSetupPanel({super.key, required this.device});

  final DoorDevice device;

  void _send(BuildContext context, WidgetRef ref, DoorDevice Function(DoorDevice d) update, String message) {
    sendDeviceCommand(context, ref, deviceId: device.id, update: (d) => update(d as DoorDevice), message: message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doorLog = ref
        .watch(activityLogProvider)
        .where((e) => e.deviceType == DeviceType.door)
        .take(5)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingRow(
          title: 'Status Kunci',
          subtitle: device.locked ? 'Terkunci, hanya bisa dibuka dengan akses' : 'Terbuka',
          trailing: _LockButton(
            locked: device.locked,
            onTap: () => setDoorLocked(context, ref, device, lock: !device.locked),
          ),
        ),
        const SizedBox(height: 12),
        SettingRow(
          title: 'Kunci Otomatis',
          subtitle: device.autoLock
              ? 'Mengunci ${device.autoLockDelay.label} setelah pintu tertutup'
              : 'Nonaktif',
          trailing: Switch(
            value: device.autoLock,
            onChanged: (v) => _send(
              context,
              ref,
              (d) => d.copyWith(autoLock: v),
              '${device.name}: kunci otomatis ${v ? 'aktif' : 'nonaktif'}',
            ),
          ),
          body: device.autoLock
              ? OptionPills<AutoLockDelay>(
                  options: AutoLockDelay.values,
                  isSelected: (s) => s == device.autoLockDelay,
                  labelOf: (s) => s.label,
                  onTap: (s) {
                    if (s == device.autoLockDelay) return;
                    _send(context, ref, (d) => d.copyWith(autoLockDelay: s), '${device.name}: jeda kunci ${s.label}');
                  },
                )
              : null,
        ),
        const SizedBox(height: 12),
        SettingRow(
          title: 'Metode Akses',
          subtitle: device.accessMethod.label,
          trailing: OptionPills<DoorAccessMethod>(
            options: DoorAccessMethod.values,
            isSelected: (m) => m == device.accessMethod,
            labelOf: (m) => m.label,
            iconOf: (m) => m.icon,
            onTap: (m) {
              if (m == device.accessMethod) return;
              _send(context, ref, (d) => d.copyWith(accessMethod: m), '${device.name}: metode akses ${m.label}');
            },
          ),
        ),
        const SizedBox(height: 12),
        SettingRow(
          title: 'Log Akses',
          subtitle: 'Aktivitas pintu hari ini',
          body: Column(
            children: [
              for (var i = 0; i < doorLog.length; i++) ...[
                if (i > 0) const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                        child: Icon(
                          doorLog[i].message.contains('kunci') ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doorLog[i].message, style: const TextStyle(fontSize: 13.5)),
                            Text(doorLog[i].actor, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Text(formatHm(doorLog[i].time), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Primary (gradient) when the action is "lock", outlined when "unlock".
class _LockButton extends StatelessWidget {
  const _LockButton({required this.locked, required this.onTap});

  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(locked ? Icons.lock_open_rounded : Icons.lock_outline_rounded, size: 18);
    final label = Text(locked ? 'Buka Pintu' : 'Kunci Pintu');
    if (locked) {
      return OutlinedButton.icon(onPressed: onTap, icon: icon, label: label);
    }
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(10)),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        onPressed: onTap,
        icon: icon,
        label: label,
      ),
    );
  }
}
