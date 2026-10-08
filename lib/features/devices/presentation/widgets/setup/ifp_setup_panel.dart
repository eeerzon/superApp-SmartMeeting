import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/device.dart';
import '../../../domain/entities/device_options.dart';
import '../../device_commands.dart';
import '../../device_icons.dart';
import '../common/option_pills.dart';
import '../common/panel_controls.dart';
import '../common/setting_row.dart';

class IfpSetupPanel extends ConsumerWidget {
  const IfpSetupPanel({super.key, required this.device});

  final IfpDevice device;

  static const _volumeStep = 2;

  void _send(BuildContext context, WidgetRef ref, IfpDevice Function(IfpDevice d) update, String message) {
    sendDeviceCommand(context, ref, deviceId: device.id, update: (d) => update(d as IfpDevice), message: message);
  }

  void _adjust(BuildContext context, WidgetRef ref, IfpDevice Function(IfpDevice d) update, String Function(IfpDevice d) describe) {
    adjustDevice(
      context,
      ref,
      deviceId: device.id,
      update: (d) => update(d as IfpDevice),
      describe: (d) => describe(d as IfpDevice),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusText = switch (device.power) {
      IfpPower.on => 'Menyala',
      IfpPower.hibernate => 'Hibernasi, layar mati dan bangun cepat',
      IfpPower.off => 'Mati',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingRow(
          title: 'Status IFP',
          subtitle: statusText,
          trailing: OptionPills<IfpPower>(
            options: IfpPower.values,
            isSelected: (p) => p == device.power,
            labelOf: (p) => p.label,
            iconOf: (p) => p.icon,
            onTap: (p) {
              if (p == device.power) return;
              _send(context, ref, (d) => d.copyWith(power: p), '${device.name}: status ${p.label}');
            },
          ),
        ),
        PoweredSection(
          enabled: device.isOn,
          children: [
            SettingRow(
              title: 'Volume IFP',
              subtitle: '${device.volume} / 100',
              trailing: PanelStepper(
                value: '${device.volume}',
                label: 'volume',
                onDecrement: () => _adjust(
                  context,
                  ref,
                  (d) => d.copyWith(volume: (d.volume - _volumeStep).clamp(0, 100)),
                  (d) => '${d.name}: volume ${d.volume}',
                ),
                onIncrement: () => _adjust(
                  context,
                  ref,
                  (d) => d.copyWith(volume: (d.volume + _volumeStep).clamp(0, 100)),
                  (d) => '${d.name}: volume ${d.volume}',
                ),
              ),
            ),
            SettingRow(
              title: 'Mode Tampilan',
              subtitle: '${device.displayMode.label} · kecerahan ${device.brightness}%',
              trailing: OptionPills<DisplayMode>(
                options: DisplayMode.values,
                isSelected: (m) => m == device.displayMode,
                labelOf: (m) => m.label,
                iconOf: (m) => m.icon,
                onTap: (m) {
                  if (m == device.displayMode) return;
                  _send(context, ref, (d) => d.copyWith(displayMode: m), '${device.name}: mode tampilan ${m.label}');
                },
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PanelSlider(
                    label: 'Tingkat kecerahan',
                    icon: Icons.wb_sunny_outlined,
                    value: device.brightness,
                    onChangeEnd: (v) => _adjust(
                      context,
                      ref,
                      (d) => d.copyWith(brightness: v),
                      (d) => '${d.name}: kecerahan ${d.brightness}%',
                    ),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () => _send(
                      context,
                      ref,
                      (d) => d.copyWith(displayMode: DisplayMode.standard, brightness: 70),
                      '${device.name}: tampilan direset ke default',
                    ),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Reset ke default'),
                  ),
                ],
              ),
            ),
            SettingRow(
              title: 'Sumber Input',
              subtitle: 'Input aktif saat ini',
              trailing: OptionPills<InputSource>(
                options: InputSource.values,
                isSelected: (i) => i == device.input,
                labelOf: (i) => i.label,
                iconOf: (i) => i.icon,
                onTap: (i) {
                  if (i == device.input) return;
                  _send(context, ref, (d) => d.copyWith(input: i), '${device.name}: input ${i.label}');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
