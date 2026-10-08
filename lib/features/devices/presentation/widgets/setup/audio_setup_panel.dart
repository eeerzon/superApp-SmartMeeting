import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/device.dart';
import '../../../domain/entities/device_options.dart';
import '../../device_commands.dart';
import '../../device_icons.dart';
import '../common/option_pills.dart';
import '../common/panel_controls.dart';
import '../common/setting_row.dart';

class AudioSetupPanel extends ConsumerWidget {
  const AudioSetupPanel({super.key, required this.device});

  final AudioDevice device;

  void _send(BuildContext context, WidgetRef ref, AudioDevice Function(AudioDevice d) update, String message) {
    sendDeviceCommand(context, ref, deviceId: device.id, update: (d) => update(d as AudioDevice), message: message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingRow(
          title: 'Status Audio',
          subtitle: device.isOn ? 'Menyala' : 'Mati',
          trailing: Switch(
            value: device.power,
            onChanged: (on) =>
                _send(context, ref, (d) => d.copyWith(power: on), '${device.name} ${on ? 'dinyalakan' : 'dimatikan'}'),
          ),
        ),
        PoweredSection(
          enabled: device.isOn,
          children: [
            SettingRow(
              title: 'Level Suara',
              body: Column(
                children: [
                  PanelSlider(
                    label: 'Volume master',
                    icon: Icons.volume_up_outlined,
                    value: device.volume,
                    onChangeEnd: (v) => adjustDevice(
                      context,
                      ref,
                      deviceId: device.id,
                      update: (d) => (d as AudioDevice).copyWith(volume: v),
                      describe: (d) => '${d.name}: volume ${(d as AudioDevice).volume}%',
                    ),
                  ),
                  const SizedBox(height: 8),
                  PanelSlider(
                    label: 'Mikrofon',
                    icon: Icons.mic_none_rounded,
                    value: device.micLevel,
                    trailing: PanelRoundButton(
                      size: 44,
                      icon: device.micMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      tooltip: device.micMuted ? 'Aktifkan mikrofon' : 'Matikan mikrofon',
                      highlighted: device.micMuted,
                      onTap: () => _send(
                        context,
                        ref,
                        (d) => d.copyWith(micMuted: !d.micMuted),
                        '${device.name}: mikrofon ${device.micMuted ? 'aktif' : 'dimatikan'}',
                      ),
                    ),
                    onChangeEnd: (v) => adjustDevice(
                      context,
                      ref,
                      deviceId: device.id,
                      update: (d) => (d as AudioDevice).copyWith(micLevel: v),
                      describe: (d) => '${d.name}: mikrofon ${(d as AudioDevice).micLevel}%',
                    ),
                  ),
                ],
              ),
            ),
            SettingRow(
              title: 'Preset Suara',
              subtitle: device.preset.label,
              trailing: OptionPills<AudioPreset>(
                options: AudioPreset.values,
                isSelected: (p) => p == device.preset,
                labelOf: (p) => p.label,
                iconOf: (p) => p.icon,
                onTap: (p) {
                  if (p == device.preset) return;
                  _send(context, ref, (d) => d.copyWith(preset: p), '${device.name}: preset ${p.label}');
                },
              ),
            ),
            SettingRow(
              title: 'Tes Speaker',
              subtitle: 'Putar nada tes untuk memastikan speaker berfungsi',
              trailing: OutlinedButton.icon(
                onPressed: () => _send(context, ref, (d) => d, 'Nada tes diputar di ${device.name}'),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Putar nada tes'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
