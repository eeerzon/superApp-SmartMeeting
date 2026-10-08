import 'package:flutter/material.dart';

import '../../../../core/feedback/app_feedback.dart';
import 'settings_card.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      icon: Icons.info_outline_rounded,
      title: 'Tentang',
      subtitle: 'Smart Meeting Controller',
      children: [
        SettingsTile(
          title: 'Versi aplikasi',
          subtitle: '0.1.0 (build 1)',
          trailing: OutlinedButton.icon(
            // TODO: check the update channel.
            onPressed: () => showAppToast(context, 'Aplikasi sudah versi terbaru', kind: ToastKind.info),
            icon: const Icon(Icons.system_update_alt_rounded, size: 18),
            label: const Text('Periksa pembaruan'),
          ),
        ),
      ],
    );
  }
}
