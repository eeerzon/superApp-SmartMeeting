import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_controller.dart';
import 'settings_card.dart';

class DisplaySection extends ConsumerWidget {
  const DisplaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    void save(AppSettings Function(AppSettings s) change, [String message = 'Pengaturan disimpan']) {
      controller.update(change);
      showAppToast(context, message);
    }

    return SettingsCard(
      icon: Icons.tablet_android_rounded,
      title: 'Tampilan',
      subtitle: 'Perilaku layar tablet di ruang meeting',
      children: [
        SettingsTile(
          title: 'Kecerahan layar',
          below: _BrightnessSlider(
            value: settings.screenBrightness,
            onChangeEnd: (v) => controller.update((s) => s.copyWith(screenBrightness: v)),
          ),
        ),
        SettingsTile(
          title: 'Redupkan layar setelah',
          subtitle: 'Layar kembali menyala saat disentuh',
          trailing: SettingsSegmented<ScreenDimTimeout>(
            options: ScreenDimTimeout.values,
            selected: settings.screenDim,
            labelOf: (t) => t.label,
            onChanged: (t) => save((s) => s.copyWith(screenDim: t)),
          ),
        ),
        SettingsTile(
          title: 'Mode kiosk',
          subtitle: 'Kunci tablet hanya untuk aplikasi ini',
          trailing: Switch(
            value: settings.kioskMode,
            onChanged: (v) => save((s) => s.copyWith(kioskMode: v)),
          ),
        ),
        SettingsTile(
          title: 'Bahasa',
          trailing: SettingsSegmented<AppLanguage>(
            options: AppLanguage.values,
            selected: settings.language,
            labelOf: (l) => l.label,
            onChanged: (l) => save(
              (s) => s.copyWith(language: l),
              l == AppLanguage.en ? 'Bahasa diubah ke English (terjemahan belum tersedia)' : 'Bahasa diubah ke Indonesia',
            ),
          ),
        ),
      ],
    );
  }
}

class _BrightnessSlider extends StatefulWidget {
  const _BrightnessSlider({required this.value, required this.onChangeEnd});

  final int value;
  final ValueChanged<int> onChangeEnd;

  @override
  State<_BrightnessSlider> createState() => _BrightnessSliderState();
}

class _BrightnessSliderState extends State<_BrightnessSlider> {
  late double _value = widget.value.toDouble();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.brightness_low_rounded, size: 18, color: AppColors.textSecondary),
        Expanded(
          child: Slider(
            value: _value,
            max: 100,
            onChanged: (v) => setState(() => _value = v),
            onChangeEnd: (v) => widget.onChangeEnd(v.round()),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text('${_value.round()}%', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
