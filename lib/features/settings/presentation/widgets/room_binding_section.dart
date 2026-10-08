import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/session/meeting_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/settings_controller.dart';
import 'settings_card.dart';

class RoomBindingSection extends ConsumerWidget {
  const RoomBindingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = ref.watch(settingsControllerProvider.select((s) => s.roomId));

    return SettingsCard(
      icon: Icons.meeting_room_outlined,
      title: 'Ruangan',
      subtitle: 'Ruang meeting yang dikendalikan tablet ini',
      children: [
        SettingsTile(
          title: 'Ruang terhubung',
          subtitle: 'Perangkat di dashboard mengikuti ruangan ini',
          trailing: SizedBox(
            width: 250,
            child: DropdownButtonFormField<String>(
              value: roomId,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              // Closed state: "Ruang Inovasi · Lantai 3" on one line.
              selectedItemBuilder: (context) => [
                for (final room in kMeetingRooms)
                  Text.rich(
                    TextSpan(
                      text: room.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      children: [
                        TextSpan(
                          text: ' · ${room.floor}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
              // Menu: name with floor underneath, check on the selected room.
              items: [
                for (final room in kMeetingRooms)
                  DropdownMenuItem(
                    value: room.id,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: room.id == roomId ? AppColors.red700 : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                room.floor,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (room.id == roomId) const Icon(Icons.check_rounded, size: 18, color: AppColors.red600),
                      ],
                    ),
                  ),
              ],
              onChanged: (id) {
                if (id == null || id == roomId) return;
                ref.read(settingsControllerProvider.notifier).update((s) => s.copyWith(roomId: id));
                // TODO: reload devices for the new room.
                showAppToast(context, 'Tablet sekarang mengendalikan ${roomById(id).name}');
              },
            ),
          ),
        ),
        SettingsTile(
          title: 'ID tablet',
          subtitle: 'Dipakai untuk registrasi di server',
          trailing: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tablet_android_rounded, size: 15, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Text(kTabletId, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
