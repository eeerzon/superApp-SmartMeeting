import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/feedback/app_feedback.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_controller.dart';
import 'settings_card.dart';

class SecuritySection extends ConsumerWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    void save(AppSettings Function(AppSettings s) change) {
      ref.read(settingsControllerProvider.notifier).update(change);
      showAppToast(context, 'Pengaturan disimpan');
    }

    return SettingsCard(
      icon: Icons.shield_outlined,
      title: 'Keamanan & Feedback',
      subtitle: 'Perlindungan aksi penting',
      children: [
        SettingsTile(
          title: 'Konfirmasi aksi kritis',
          subtitle: 'Tampilkan dialog sebelum membuka pintu atau mematikan semua perangkat',
          trailing: Switch(
            value: settings.confirmCriticalActions,
            onChanged: (v) => save((s) => s.copyWith(confirmCriticalActions: v)),
          ),
        ),
        SettingsTile(
          title: 'Keluar otomatis',
          subtitle: 'Kembali ke halaman login jika tidak digunakan',
          trailing: SettingsSegmented<AutoLogout>(
            options: AutoLogout.values,
            selected: settings.autoLogout,
            labelOf: (a) => a.label,
            onChanged: (a) => save((s) => s.copyWith(autoLogout: a)),
          ),
        ),
        SettingsTile(
          title: 'Suara sentuhan',
          subtitle: 'Bunyi singkat saat perintah berhasil',
          trailing: Switch(
            value: settings.touchSound,
            onChanged: (v) => save((s) => s.copyWith(touchSound: v)),
          ),
        ),
      ],
    );
  }
}
