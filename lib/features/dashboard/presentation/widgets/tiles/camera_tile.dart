import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/feedback/app_feedback.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../devices/domain/entities/device.dart';
import '../../../../devices/domain/entities/device_type.dart';
import '../../../../devices/presentation/device_commands.dart';
import '../../../../devices/presentation/device_icons.dart';
import '../../../../devices/presentation/providers/device_management_providers.dart';
import '../../../../devices/presentation/providers/room_devices_controller.dart';
import 'tile_controls.dart';
import 'tile_frame.dart';

class CameraTile extends ConsumerWidget {
  const CameraTile({super.key, required this.device, required this.linkStatus});

  final CameraDevice device;
  final DeviceLinkStatus linkStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardTileFrame(
      title: DeviceType.camera.title,
      icon: DeviceType.camera.icon,
      linkStatus: linkStatus,
      active: device.isOn,
      statusText: device.isOn ? 'Aktif · ${device.mode.label}' : 'Standby',
      powerValue: device.power,
      onPowerChanged: (on) => sendDeviceCommand(
        context,
        ref,
        deviceId: device.id,
        update: (d) => (d as CameraDevice).copyWith(power: on),
        message: '${device.name} ${on ? 'dinyalakan' : 'dimatikan'}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Preview(device: device),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TileChoiceButton(
                  horizontal: true,
                  icon: Icons.open_with_rounded,
                  label: 'Kontrol PTZ',
                  selected: false,
                  onTap: () {
                    ref.read(selectedDeviceTypeProvider.notifier).state = DeviceType.camera;
                    context.go(RoutePaths.devices);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TileChoiceButton(
                  horizontal: true,
                  icon: Icons.center_focus_weak_rounded,
                  label: 'Tangkap',
                  selected: false,
                  // TODO: request a snapshot from the camera service.
                  onTap: () => showAppToast(context, 'Tangkapan layar kamera disimpan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.device});

  final CameraDevice device;

  @override
  Widget build(BuildContext context) {
    const height = 128.0;
    if (!device.isOn) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_outlined, color: AppColors.textMuted),
            SizedBox(height: 6),
            Text('Kamera mati', style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }
    // TODO: replace with the RTSP/WebRTC stream.
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 1.2),
            radius: 1.3,
            colors: [Color(0xFF3A3F48), Color(0xFF1B1D22)],
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  4,
                  (_) => const Padding(padding: EdgeInsets.symmetric(horizontal: 7), child: _Person()),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.red600, borderRadius: BorderRadius.circular(6)),
                child: const Text(
                  '● LIVE',
                  style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0x66000000), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  '${device.mode.label} · ${device.zoom}x',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Person extends StatelessWidget {
  const _Person();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle)),
        const SizedBox(height: 4),
        Container(
          width: 34,
          height: 30,
          decoration: const BoxDecoration(
            color: Color(0x29FFFFFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(17), bottom: Radius.circular(4)),
          ),
        ),
      ],
    );
  }
}
