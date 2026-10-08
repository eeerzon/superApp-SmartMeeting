import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/realtime/connection_status.dart';
import '../../../core/session/meeting_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/utils/time_format.dart';
import '../../../features/auth/presentation/providers/auth_controller.dart';
import '../../../features/settings/presentation/providers/settings_controller.dart';

/// Logo, bound room, meeting status, connection, clock, avatar.
class TopBar extends ConsumerWidget {
  const TopBar({super.key, required this.onAvatarTap});

  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = roomById(ref.watch(settingsControllerProvider).roomId);
    final meeting = ref.watch(currentMeetingProvider);
    final online = ref.watch(serverConnectionProvider);
    final initials = ref.watch(authControllerProvider).user?.initials ?? '';

    return Container(
      height: AppLayout.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.pagePadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const _Wordmark(),
          const SizedBox(width: 12),
          _Pill(
            icon: Icons.place_outlined,
            label: room.name,
            background: AppColors.red50,
            foreground: AppColors.red700,
          ),
          const Spacer(),
          if (meeting.isLive) ...[
            const _LivePill(),
            const SizedBox(width: 12),
          ],
          _Pill(
            icon: Icons.schedule_rounded,
            label: meeting.timeRange,
            background: AppColors.background,
            foreground: AppColors.textSecondary,
            bordered: true,
          ),
          const SizedBox(width: 16),
          _ConnectionIndicator(online: online),
          const SizedBox(width: 16),
          const _Clock(),
          const SizedBox(width: 12),
          _Avatar(initials: initials, onTap: onAvatarTap),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => AppGradients.brand.createShader(bounds),
      child: const Text(
        'onesia',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: -1,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.bordered = false,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: bordered ? Border.all(color: AppColors.border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: foreground)),
        ],
      ),
    );
  }
}

/// "Meeting Aktif" pill with a pulsing dot.
class _LivePill extends StatefulWidget {
  const _LivePill();

  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: AppColors.redShadow, blurRadius: 16, spreadRadius: -6, offset: Offset(0, 6))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withAlpha(((1 - _pulse.value) * 180).round()),
                    spreadRadius: _pulse.value * 6,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Meeting Aktif',
            style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? AppColors.online : AppColors.red700;
    return Tooltip(
      message: online ? 'Terhubung ke server' : 'Koneksi terputus',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(online ? Icons.wifi_rounded : Icons.wifi_off_rounded, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            online ? 'Terhubung' : 'Terputus',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _Clock extends StatefulWidget {
  const _Clock();

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  late final Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatHm(_now),
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.onTap});

  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Profil pengguna',
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(12)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
