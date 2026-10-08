import 'package:flutter/material.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../devices/domain/entities/device.dart';
import '../../../devices/presentation/providers/room_devices_controller.dart';
import 'tiles/ac_tile.dart';
import 'tiles/audio_tile.dart';
import 'tiles/camera_tile.dart';
import 'tiles/door_tile.dart';
import 'tiles/ifp_tile.dart';
import 'tiles/lighting_tile.dart';

/// Fixed 3-column landscape grid; tiles in a row share the same height.
class DeviceGrid extends StatelessWidget {
  const DeviceGrid({super.key, required this.state});

  final RoomDevicesState state;

  @override
  Widget build(BuildContext context) {
    final ac = state.primary<AcDevice>();
    final light = state.primary<LightDevice>();
    final audio = state.primary<AudioDevice>();
    final ifp = state.primary<IfpDevice>();
    final door = state.primary<DoorDevice>();
    final camera = state.primary<CameraDevice>();

    final tiles = <Widget>[
      AcTile(device: ac, linkStatus: state.statusOf(ac.id)),
      LightingTile(device: light, linkStatus: state.statusOf(light.id)),
      AudioTile(device: audio, linkStatus: state.statusOf(audio.id)),
      IfpTile(device: ifp, linkStatus: state.statusOf(ifp.id)),
      DoorTile(device: door, linkStatus: state.statusOf(door.id)),
      CameraTile(device: camera, linkStatus: state.statusOf(camera.id)),
    ];

    const columns = AppLayout.gridColumns;
    final rows = <Widget>[];
    for (var start = 0; start < tiles.length; start += columns) {
      final rowTiles = tiles.sublist(start, (start + columns).clamp(0, tiles.length));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < columns; i++) ...[
                if (i > 0) const SizedBox(width: AppLayout.gap),
                Expanded(child: i < rowTiles.length ? rowTiles[i] : const SizedBox.shrink()),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppLayout.gap),
          rows[i],
        ],
      ],
    );
  }
}
