import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_gradients.dart';
import '../../../../devices/presentation/providers/room_devices_controller.dart';

/// Card shell for a dashboard device tile: icon, title, status line,
/// optional power switch, and a body that is dimmed when the device is off.
class DashboardTileFrame extends StatelessWidget {
  const DashboardTileFrame({
    super.key,
    required this.title,
    required this.icon,
    required this.statusText,
    required this.linkStatus,
    required this.active,
    required this.child,
    this.powerValue,
    this.onPowerChanged,
  });

  final String title;
  final IconData icon;
  final String statusText;
  final DeviceLinkStatus linkStatus;

  /// Powered on (doors are always active). Inactive tiles dim their body.
  final bool active;
  final Widget child;

  /// When null, no power switch is shown.
  final bool? powerValue;
  final ValueChanged<bool>? onPowerChanged;

  @override
  Widget build(BuildContext context) {
    final busy = linkStatus == DeviceLinkStatus.pending;
    final reachable = linkStatus != DeviceLinkStatus.offline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: active
            ? const [BoxShadow(color: Color(0x33E30613), blurRadius: 28, spreadRadius: -16, offset: Offset(0, 10))]
            : const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TileIcon(icon: icon, active: active, busy: busy),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                    const SizedBox(height: 3),
                    _StatusLine(text: statusText, linkStatus: linkStatus, poweredOn: active),
                  ],
                ),
              ),
              if (powerValue != null)
                Switch(
                  value: powerValue!,
                  onChanged: busy || !reachable ? null : onPowerChanged,
                ),
            ],
          ),
          const SizedBox(height: 18),
          IgnorePointer(
            ignoring: !active || busy,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: active ? 1 : 0.45,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.icon, required this.active, required this.busy});

  final IconData icon;
  final bool active;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : AppColors.textMuted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: active ? null : AppColors.background,
        gradient: active ? AppGradients.primary : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: active
            ? const [BoxShadow(color: AppColors.redShadow, blurRadius: 14, spreadRadius: -6, offset: Offset(0, 6))]
            : const [],
      ),
      child: Center(
        child: busy
            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
            : Icon(icon, size: 22, color: fg),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.text, required this.linkStatus, required this.poweredOn});

  final String text;
  final DeviceLinkStatus linkStatus;
  final bool poweredOn;

  @override
  Widget build(BuildContext context) {
    final (dot, label) = switch (linkStatus) {
      DeviceLinkStatus.offline => (AppColors.red600, 'Offline · $text'),
      DeviceLinkStatus.pending => (AppColors.warning, 'Mengirim perintah…'),
      DeviceLinkStatus.syncing => (AppColors.warning, '$text · menyimpan…'),
      DeviceLinkStatus.online => (poweredOn ? AppColors.online : AppColors.offline, text),
    };
    return Row(
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
