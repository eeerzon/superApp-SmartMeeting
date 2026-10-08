import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/device.dart';
import '../../../domain/entities/device_options.dart';
import '../../device_commands.dart';
import '../../device_icons.dart';
import '../common/option_pills.dart';
import '../common/panel_controls.dart';
import '../common/setting_row.dart';

class AcSetupPanel extends ConsumerWidget {
  const AcSetupPanel({super.key, required this.device});

  final AcDevice device;

  void _send(BuildContext context, WidgetRef ref, AcDevice Function(AcDevice d) update, String message) {
    sendDeviceCommand(context, ref, deviceId: device.id, update: (d) => update(d as AcDevice), message: message);
  }

  void _stepTemperature(BuildContext context, WidgetRef ref, int delta) {
    adjustDevice(
      context,
      ref,
      deviceId: device.id,
      update: (d) {
        final ac = d as AcDevice;
        return ac.copyWith(
          temperature: (ac.temperature + delta).clamp(AcDevice.minTemperature, AcDevice.maxTemperature),
        );
      },
      describe: (d) => '${d.name}: suhu ${(d as AcDevice).temperature}°C',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingRow(
          title: 'Status AC',
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
              title: 'Suhu',
              subtitle: 'Rentang ${AcDevice.minTemperature}–${AcDevice.maxTemperature}°C',
              trailing: PanelStepper(
                value: '${device.temperature}°',
                label: 'suhu',
                onDecrement: () => _stepTemperature(context, ref, -1),
                onIncrement: () => _stepTemperature(context, ref, 1),
              ),
            ),
            SettingRow(
              title: 'Mode',
              subtitle: device.mode.label,
              trailing: OptionPills<AcMode>(
                options: AcMode.values,
                isSelected: (m) => m == device.mode,
                labelOf: (m) => m.label,
                iconOf: (m) => m.icon,
                onTap: (m) {
                  if (m == device.mode) return;
                  _send(context, ref, (d) => d.copyWith(mode: m), '${device.name}: mode ${m.label}');
                },
              ),
            ),
            SettingRow(
              title: 'Kecepatan Kipas',
              subtitle: device.fanSpeed.label,
              trailing: OptionPills<FanSpeed>(
                options: FanSpeed.values,
                isSelected: (f) => f == device.fanSpeed,
                labelOf: (f) => f.label,
                onTap: (f) {
                  if (f == device.fanSpeed) return;
                  _send(context, ref, (d) => d.copyWith(fanSpeed: f), '${device.name}: kipas ${f.label}');
                },
              ),
            ),
            SettingRow(
              title: 'Swing',
              subtitle: 'Arah angin bergerak otomatis',
              trailing: Switch(
                value: device.swing,
                onChanged: (v) =>
                    _send(context, ref, (d) => d.copyWith(swing: v), '${device.name}: swing ${v ? 'aktif' : 'nonaktif'}'),
              ),
            ),
            SettingRow(
              title: 'Matikan Otomatis',
              subtitle: 'Hemat energi setelah meeting selesai',
              trailing: OptionPills<AutoOffTimer>(
                options: AutoOffTimer.values,
                isSelected: (t) => t == device.autoOff,
                labelOf: (t) => t.label,
                onTap: (t) {
                  if (t == device.autoOff) return;
                  _send(context, ref, (d) => d.copyWith(autoOff: t), '${device.name}: matikan otomatis ${t.label}');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
