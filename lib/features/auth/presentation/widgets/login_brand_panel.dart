import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/session/meeting_session.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/utils/time_format.dart';
import '../../../settings/presentation/providers/settings_controller.dart';

class LoginBrandPanel extends ConsumerWidget {
  const LoginBrandPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = roomById(ref.watch(settingsControllerProvider).roomId);
    final meeting = ref.watch(currentMeetingProvider);

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.brand),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          // Decorative rings
          Positioned(
            right: -220,
            top: -200,
            child: Container(
              width: 560,
              height: 560,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(46)),
              ),
            ),
          ),
          Positioned(
            left: -160,
            bottom: -160,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Colors.white.withAlpha(41), Colors.transparent]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 40, 48, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    _Wordmark(),
                    Spacer(),
                    _GlassPill(icon: Icons.tablet_android_rounded, label: kTabletId),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Smart Meeting\nController',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Text(
                    'Kendalikan AC, pencahayaan, audio, layar, kamera, dan pintu ruang meeting dalam satu sentuhan.',
                    style: TextStyle(color: Colors.white.withAlpha(224), fontSize: 16, height: 1.5),
                  ),
                ),
                const SizedBox(height: 28),
                _RoomCard(room: room, meeting: meeting),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'onesia',
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        letterSpacing: -1,
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(36),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(64)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Glass card with a live clock and the current meeting.
class _RoomCard extends StatefulWidget {
  const _RoomCard({required this.room, required this.meeting});

  final MeetingRoom room;
  final MeetingInfo meeting;

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
  late Timer _timer;
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
    final soft = Colors.white.withAlpha(217);
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(31),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(61)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatHm(_now),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(formatLongDate(_now), style: TextStyle(color: soft, fontSize: 13)),
              ],
            ),
            const SizedBox(width: 20),
            VerticalDivider(width: 1, thickness: 1, color: Colors.white.withAlpha(64)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 14, color: soft),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${widget.room.name} · ${widget.room.floor}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: soft, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.meeting.title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(widget.meeting.timeRange, style: TextStyle(color: soft, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
