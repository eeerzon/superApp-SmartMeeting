import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../devices/domain/entities/device.dart';
import '../../../../devices/domain/entities/device_options.dart';
import '../../../../devices/domain/entities/device_type.dart';
import '../../../../devices/presentation/device_commands.dart';
import '../../../../devices/presentation/device_icons.dart';
import '../../../../devices/presentation/providers/room_devices_controller.dart';
import 'tile_controls.dart';
import 'tile_frame.dart';

class LightingTile extends ConsumerWidget {
  const LightingTile({super.key, required this.device, required this.linkStatus});

  final LightDevice device;
  final DeviceLinkStatus linkStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardTileFrame(
      title: DeviceType.light.title,
      icon: DeviceType.light.icon,
      linkStatus: linkStatus,
      active: device.isOn,
      statusText: device.isOn ? 'Aktif · ${device.color.label}' : 'Mati',
      powerValue: device.power,
      onPowerChanged: (on) => sendDeviceCommand(
        context,
        ref,
        deviceId: device.id,
        update: (d) => (d as LightDevice).copyWith(power: on),
        message: '${device.name} ${on ? 'dinyalakan' : 'dimatikan'}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TileSlider(
            label: 'Kecerahan',
            icon: Icons.wb_sunny_outlined,
            value: device.brightness,
            onChangeEnd: (v) => adjustDevice(
              context,
              ref,
              deviceId: device.id,
              update: (d) => (d as LightDevice).copyWith(brightness: v),
              describe: (d) => '${d.name}: kecerahan ${(d as LightDevice).brightness}%',
            ),
          ),
          const SizedBox(height: 8),
          const Text('Warna', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in LightColor.values)
                _ColorSwatch(
                  color: color,
                  selected: device.color == color,
                  onTap: () {
                    if (device.color == color) return;
                    sendDeviceCommand(
                      context,
                      ref,
                      deviceId: device.id,
                      update: (d) => (d as LightDevice).copyWith(color: color),
                      message: '${device.name}: warna ${color.label}',
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color, required this.selected, required this.onTap});

  final LightColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: color.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color(color.argb),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x0F000000), width: 2),
            boxShadow: selected
                ? const [
                    BoxShadow(color: Colors.white, spreadRadius: 3),
                    BoxShadow(color: AppColors.red600, spreadRadius: 5),
                  ]
                : const [],
          ),
          child: selected ? const Icon(Icons.check_rounded, size: 18, color: AppColors.textPrimary) : null,
        ),
      ),
    );
  }
}
