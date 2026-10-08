import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/feedback/app_feedback.dart';
import '../../../devices/presentation/device_commands.dart';
import '../../../devices/presentation/providers/room_devices_controller.dart';
import '../../../settings/presentation/providers/settings_controller.dart';
import '../../domain/entities/scene.dart';
import '../providers/scene_providers.dart';
import 'scene_button.dart';

/// "Mulai Meeting / Presentasi / Video Call / Selesai" in one row.
class QuickSceneBar extends ConsumerWidget {
  const QuickSceneBar({super.key});

  static IconData _iconFor(String sceneId) => switch (sceneId) {
        'meeting' => Icons.play_arrow_rounded,
        'presentation' => Icons.co_present_outlined,
        'video' => Icons.videocam_outlined,
        'end' => Icons.power_settings_new_rounded,
        _ => Icons.auto_awesome_outlined,
      };

  Future<void> _run(BuildContext context, WidgetRef ref, Scene scene) async {
    if (scene.requiresConfirmation && ref.read(settingsControllerProvider).confirmCriticalActions) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Akhiri meeting?',
        message: 'Semua perangkat akan dimatikan dan pintu dikunci. '
            'Pastikan tidak ada peserta yang masih menggunakan ruangan.',
        confirmLabel: 'Matikan semua',
        icon: Icons.power_settings_new_rounded,
        destructive: true,
      );
      if (!confirmed || !context.mounted) return;
    }
    final result = await ref.read(roomDevicesProvider.notifier).applyScene(scene);
    if (context.mounted) showCommandResult(context, result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenes = ref.watch(scenesProvider);
    final activeId = ref.watch(roomDevicesProvider.select((s) => s.activeSceneId));
    final progress = ref.watch(roomDevicesProvider.select((s) => s.sceneProgress));

    return Row(
      children: [
        for (var i = 0; i < scenes.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: Builder(builder: (context) {
              final scene = scenes[i];
              final running = progress?.sceneId == scene.id;
              final active = activeId == scene.id && !running;
              return SceneButton(
                icon: _iconFor(scene.id),
                label: scene.label,
                subtitle: running
                    ? 'Menerapkan ${progress!.done}/${progress.total}…'
                    : active
                        ? 'Sedang aktif'
                        : scene.description,
                active: active,
                running: running,
                neutralIcon: scene.endsMeeting,
                onTap: progress != null ? null : () => _run(context, ref, scene),
              );
            }),
          ),
        ],
      ],
    );
  }
}
