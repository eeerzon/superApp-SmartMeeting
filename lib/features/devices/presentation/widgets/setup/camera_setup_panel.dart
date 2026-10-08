import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/feedback/app_feedback.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/device.dart';
import '../../../domain/entities/device_options.dart';
import '../../device_commands.dart';
import '../../device_icons.dart';
import '../common/option_pills.dart';
import '../common/panel_controls.dart';
import '../common/setting_row.dart';

class CameraSetupPanel extends ConsumerWidget {
  const CameraSetupPanel({super.key, required this.device});

  final CameraDevice device;

  void _send(BuildContext context, WidgetRef ref, CameraDevice Function(CameraDevice d) update, String message) {
    sendDeviceCommand(context, ref, deviceId: device.id, update: (d) => update(d as CameraDevice), message: message);
  }

  /// Moving the camera switches it to manual mode.
  void _move(BuildContext context, WidgetRef ref, String direction, {bool home = false}) {
    if (device.mode != CameraMode.manual) {
      showAppToast(context, 'Mode kamera beralih ke Manual', kind: ToastKind.info);
    }
    // TODO: send the actual pan/tilt command to the camera service.
    adjustDevice(
      context,
      ref,
      deviceId: device.id,
      update: (d) => (d as CameraDevice).copyWith(
        mode: CameraMode.manual,
        preset: home ? CameraPreset.room : null,
      ),
      describe: (d) => '${d.name}: kamera digerakkan ke $direction',
    );
  }

  void _zoom(BuildContext context, WidgetRef ref, int delta) {
    adjustDevice(
      context,
      ref,
      deviceId: device.id,
      update: (d) {
        final cam = d as CameraDevice;
        return cam.copyWith(zoom: (cam.zoom + delta).clamp(CameraDevice.minZoom, CameraDevice.maxZoom));
      },
      describe: (d) => '${d.name}: zoom ${(d as CameraDevice).zoom}x',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingRow(
          title: 'Status Kamera',
          subtitle: device.isOn ? 'Menyala' : 'Standby',
          trailing: Switch(
            value: device.power,
            onChanged: (on) =>
                _send(context, ref, (d) => d.copyWith(power: on), '${device.name} ${on ? 'dinyalakan' : 'dimatikan'}'),
          ),
        ),
        PoweredSection(
          enabled: device.isOn,
          children: [
            SettingRow(title: 'Pratinjau', body: _LargePreview(device: device)),
            SettingRow(
              title: 'Mode Kamera',
              subtitle: device.mode == CameraMode.manual
                  ? 'Atur posisi dengan kontrol PTZ'
                  : 'Kamera mengikuti peserta secara otomatis',
              trailing: OptionPills<CameraMode>(
                options: CameraMode.values,
                isSelected: (m) => m == device.mode,
                labelOf: (m) => m.label,
                iconOf: (m) => m.icon,
                onTap: (m) {
                  if (m == device.mode) return;
                  _send(context, ref, (d) => d.copyWith(mode: m), '${device.name}: mode ${m.label}');
                },
              ),
            ),
            SettingRow(
              title: 'Kontrol PTZ',
              subtitle: 'Menggerakkan kamera akan beralih ke mode Manual',
              body: Wrap(
                spacing: 32,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _PtzPad(
                    onMove: (dir) => _move(context, ref, dir),
                    onHome: () => _move(context, ref, 'posisi awal', home: true),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Zoom', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      PanelStepper(
                        value: '${device.zoom}x',
                        label: 'zoom',
                        onDecrement: () => _zoom(context, ref, -1),
                        onIncrement: () => _zoom(context, ref, 1),
                      ),
                      const SizedBox(height: 16),
                      const Text('Preset posisi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      OptionPills<CameraPreset>(
                        options: CameraPreset.values,
                        isSelected: (p) => p == device.preset,
                        labelOf: (p) => p.label,
                        onTap: (p) {
                          if (p == device.preset) return;
                          _send(context, ref, (d) => d.copyWith(preset: p), '${device.name}: preset ${p.label}');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PtzPad extends StatelessWidget {
  const _PtzPad({required this.onMove, required this.onHome});

  final ValueChanged<String> onMove;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: 6, height: 6);
    const empty = SizedBox(width: 48, height: 48);
    Widget btn(IconData icon, String dir) =>
        PanelRoundButton(square: true, icon: icon, tooltip: dir, onTap: () => onMove(dir));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [empty, gap, btn(Icons.keyboard_arrow_up_rounded, 'atas'), gap, empty]),
        gap,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            btn(Icons.keyboard_arrow_left_rounded, 'kiri'),
            gap,
            PanelRoundButton(square: true, filled: true, icon: Icons.home_outlined, tooltip: 'Posisi awal', onTap: onHome),
            gap,
            btn(Icons.keyboard_arrow_right_rounded, 'kanan'),
          ],
        ),
        gap,
        Row(mainAxisSize: MainAxisSize.min, children: [empty, gap, btn(Icons.keyboard_arrow_down_rounded, 'bawah'), gap, empty]),
      ],
    );
  }
}

class _LargePreview extends StatelessWidget {
  const _LargePreview({required this.device});

  final CameraDevice device;

  @override
  Widget build(BuildContext context) {
    const height = 220.0;
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
            Icon(Icons.videocam_off_outlined, color: AppColors.textMuted, size: 28),
            SizedBox(height: 6),
            Text('Kamera mati', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500)),
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
                children: List.generate(4, (_) => const Padding(padding: EdgeInsets.symmetric(horizontal: 9), child: _Person())),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.red600, borderRadius: BorderRadius.circular(6)),
                child: const Text('● LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0x66000000), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  '${device.mode.label} · ${device.zoom}x · ${device.preset.label}',
                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
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
        Container(width: 30, height: 30, decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle)),
        const SizedBox(height: 6),
        Container(
          width: 52,
          height: 46,
          decoration: const BoxDecoration(
            color: Color(0x29FFFFFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26), bottom: Radius.circular(6)),
          ),
        ),
      ],
    );
  }
}
