import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../devices/domain/entities/device.dart';
import '../../../../devices/domain/entities/device_options.dart';
import '../../../../devices/domain/entities/device_type.dart';
import '../../../../devices/presentation/device_commands.dart';
import '../../../../devices/presentation/device_icons.dart';
import '../../../../devices/presentation/providers/room_devices_controller.dart';
import 'tile_controls.dart';
import 'tile_frame.dart';

class IfpTile extends ConsumerWidget {
  const IfpTile({super.key, required this.device, required this.linkStatus});

  final IfpDevice device;
  final DeviceLinkStatus linkStatus;

  String get _status => switch (device.power) {
        IfpPower.on => 'Aktif · ${device.input.label}',
        IfpPower.hibernate => 'Hibernasi',
        IfpPower.off => 'Mati',
      };

  Widget _inputButton(BuildContext context, WidgetRef ref, InputSource input) {
    return Expanded(
      child: TileChoiceButton(
        horizontal: true,
        icon: input.icon,
        label: input.label,
        selected: device.input == input,
        onTap: () {
          if (device.input == input) return;
          sendDeviceCommand(
            context,
            ref,
            deviceId: device.id,
            update: (d) => (d as IfpDevice).copyWith(input: input),
            message: '${device.name}: input ${input.label}',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardTileFrame(
      title: DeviceType.ifp.title,
      icon: DeviceType.ifp.icon,
      linkStatus: linkStatus,
      active: device.isOn,
      statusText: _status,
      powerValue: device.isOn,
      onPowerChanged: (on) => sendDeviceCommand(
        context,
        ref,
        deviceId: device.id,
        update: (d) => (d as IfpDevice).copyWith(power: on ? IfpPower.on : IfpPower.off),
        message: '${device.name} ${on ? 'dinyalakan' : 'dimatikan'}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Sumber input', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(children: [
            _inputButton(context, ref, InputSource.hdmi1),
            const SizedBox(width: 8),
            _inputButton(context, ref, InputSource.hdmi2),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _inputButton(context, ref, InputSource.vga),
            const SizedBox(width: 8),
            _inputButton(context, ref, InputSource.wireless),
          ]),
        ],
      ),
    );
  }
}
