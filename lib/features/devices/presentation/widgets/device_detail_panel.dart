import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../domain/entities/device.dart';
import '../device_commands.dart';
import '../device_icons.dart';
import '../providers/room_devices_controller.dart';
import 'common/panel_controls.dart';
import 'setup/ac_setup_panel.dart';
import 'setup/audio_setup_panel.dart';
import 'setup/camera_setup_panel.dart';
import 'setup/door_setup_panel.dart';
import 'setup/ifp_setup_panel.dart';
import 'setup/light_setup_panel.dart';

/// Header + type-specific setup panel for the selected unit.
class DeviceDetailPanel extends ConsumerStatefulWidget {
  const DeviceDetailPanel({super.key, required this.device, required this.status});

  final Device device;
  final DeviceLinkStatus status;

  @override
  ConsumerState<DeviceDetailPanel> createState() => _DeviceDetailPanelState();
}

class _DeviceDetailPanelState extends ConsumerState<DeviceDetailPanel> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    final result = await ref.read(roomDevicesProvider.notifier).refreshStatus(widget.device.id);
    if (!mounted) return;
    setState(() => _refreshing = false);
    showCommandResult(context, result);
  }

  Widget _setupPanel(Device device) => switch (device) {
        IfpDevice d => IfpSetupPanel(device: d),
        AcDevice d => AcSetupPanel(device: d),
        LightDevice d => LightSetupPanel(device: d),
        AudioDevice d => AudioSetupPanel(device: d),
        CameraDevice d => CameraSetupPanel(device: d),
        DoorDevice d => DoorSetupPanel(device: d),
      };

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final status = widget.status;
    final unreachable = status == DeviceLinkStatus.offline;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(12)),
                child: status == DeviceLinkStatus.pending
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Icon(device.type.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(device.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                        const SizedBox(width: 10),
                        UnitStatusBadge(status: status, poweredOn: device.isOn),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${device.type.title} · ${device.location}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _refreshing ? null : _refresh,
                icon: _refreshing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Segarkan status'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!device.online)
            _OfflineAlert(name: device.name, lastSeen: device.lastSeen)
          else if (unreachable)
            const _OfflineAlert(name: 'Server', lastSeen: null),
          IgnorePointer(
            ignoring: unreachable,
            child: Opacity(opacity: unreachable ? 0.45 : 1, child: _setupPanel(device)),
          ),
        ],
      ),
    );
  }
}

class _OfflineAlert extends StatelessWidget {
  const _OfflineAlert({required this.name, required this.lastSeen});

  final String name;
  final String? lastSeen;

  @override
  Widget build(BuildContext context) {
    final detail = lastSeen != null
        ? 'Terakhir terlihat pukul $lastSeen. Periksa daya dan kabel jaringan perangkat.'
        : 'Pengaturan tidak dapat dikirim sampai koneksi pulih.';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.red100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 20, color: AppColors.red700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name tidak terhubung',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.red700),
                ),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(fontSize: 13.5, color: AppColors.red700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
