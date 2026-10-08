import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/feedback/app_feedback.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../devices/domain/entities/device.dart';
import '../../../../devices/domain/entities/device_options.dart';
import '../../../../devices/domain/entities/device_type.dart';
import '../../../../devices/presentation/device_commands.dart';
import '../../../../devices/presentation/device_icons.dart';
import '../../../../devices/presentation/providers/room_devices_controller.dart';
import 'tile_controls.dart';
import 'tile_frame.dart';

class AcTile extends ConsumerWidget {
  const AcTile({super.key, required this.device, required this.linkStatus});

  final AcDevice device;
  final DeviceLinkStatus linkStatus;

  static const _modes = [AcMode.cool, AcMode.heat, AcMode.fan, AcMode.auto];

  void _step(BuildContext context, WidgetRef ref, int delta) {
    final target = device.temperature + delta;
    if (target < AcDevice.minTemperature || target > AcDevice.maxTemperature) {
      showAppToast(
        context,
        'Sudah di batas ${delta > 0 ? 'maksimum' : 'minimum'} (${device.temperature}°C)',
        kind: ToastKind.info,
      );
      return;
    }
    adjustDevice(
      context,
      ref,
      deviceId: device.id,
      update: (d) {
        final ac = d as AcDevice;
        return ac.copyWith(temperature: ac.temperature + delta);
      },
      describe: (d) => '${d.name}: suhu ${(d as AcDevice).temperature}°C',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardTileFrame(
      title: DeviceType.ac.title,
      icon: DeviceType.ac.icon,
      linkStatus: linkStatus,
      active: device.isOn,
      statusText: device.isOn
          ? 'Aktif · ${device.mode.label} · Kipas ${device.fanSpeed.label.toLowerCase()}'
          : 'Mati',
      powerValue: device.power,
      onPowerChanged: (on) => sendDeviceCommand(
        context,
        ref,
        deviceId: device.id,
        update: (d) => (d as AcDevice).copyWith(power: on),
        message: '${device.name} ${on ? 'dinyalakan' : 'dimatikan'}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TileRoundButton(icon: Icons.remove_rounded, tooltip: 'Turunkan suhu', onTap: () => _step(context, ref, -1)),
              SizedBox(
                width: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${device.temperature}',
                      style: const TextStyle(fontSize: 44, height: 1, fontWeight: FontWeight.w800, letterSpacing: -2),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 2, left: 2),
                      child: Text(
                        '°C',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              TileRoundButton(icon: Icons.add_rounded, tooltip: 'Naikkan suhu', onTap: () => _step(context, ref, 1)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final mode in _modes) ...[
                if (mode != _modes.first) const SizedBox(width: 8),
                Expanded(
                  child: TileChoiceButton(
                    icon: mode.icon,
                    label: mode.label,
                    selected: device.mode == mode,
                    onTap: () {
                      if (device.mode == mode) return;
                      sendDeviceCommand(
                        context,
                        ref,
                        deviceId: device.id,
                        update: (d) => (d as AcDevice).copyWith(mode: mode),
                        message: '${device.name}: mode ${mode.label}',
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
