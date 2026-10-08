import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../devices/domain/entities/device.dart';
import '../../../../devices/domain/entities/device_type.dart';
import '../../../../devices/presentation/device_commands.dart';
import '../../../../devices/presentation/device_icons.dart';
import '../../../../devices/presentation/providers/room_devices_controller.dart';
import 'tile_controls.dart';
import 'tile_frame.dart';

class AudioTile extends ConsumerWidget {
  const AudioTile({super.key, required this.device, required this.linkStatus});

  final AudioDevice device;
  final DeviceLinkStatus linkStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardTileFrame(
      title: DeviceType.audio.title,
      icon: DeviceType.audio.icon,
      linkStatus: linkStatus,
      active: device.isOn,
      statusText: device.isOn ? 'Aktif · Vol ${device.volume}%${device.micMuted ? ' · Mic mute' : ''}' : 'Mati',
      powerValue: device.power,
      onPowerChanged: (on) => sendDeviceCommand(
        context,
        ref,
        deviceId: device.id,
        update: (d) => (d as AudioDevice).copyWith(power: on),
        message: '${device.name} ${on ? 'dinyalakan' : 'dimatikan'}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TileSlider(
            label: 'Volume',
            icon: Icons.volume_up_outlined,
            value: device.volume,
            onChangeEnd: (v) => adjustDevice(
              context,
              ref,
              deviceId: device.id,
              update: (d) => (d as AudioDevice).copyWith(volume: v),
              describe: (d) => '${d.name}: volume ${(d as AudioDevice).volume}%',
            ),
          ),
          const SizedBox(height: 4),
          TileSlider(
            label: 'Mikrofon',
            icon: Icons.mic_none_rounded,
            value: device.micLevel,
            trailing: TileRoundButton(
              size: 44,
              icon: device.micMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              tooltip: device.micMuted ? 'Aktifkan mikrofon' : 'Matikan mikrofon',
              highlighted: device.micMuted,
              onTap: () => sendDeviceCommand(
                context,
                ref,
                deviceId: device.id,
                update: (d) => (d as AudioDevice).copyWith(micMuted: !device.micMuted),
                message: '${device.name}: mikrofon ${device.micMuted ? 'aktif' : 'dimatikan'}',
              ),
            ),
            onChangeEnd: (v) => adjustDevice(
              context,
              ref,
              deviceId: device.id,
              update: (d) => (d as AudioDevice).copyWith(micLevel: v),
              describe: (d) => '${d.name}: mikrofon ${(d as AudioDevice).micLevel}%',
            ),
          ),
        ],
      ),
    );
  }
}
