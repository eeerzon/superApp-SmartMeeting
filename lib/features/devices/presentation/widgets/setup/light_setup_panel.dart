import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/device.dart';
import '../../../domain/entities/device_options.dart';
import '../../device_commands.dart';
import '../common/option_pills.dart';
import '../common/panel_controls.dart';
import '../common/setting_row.dart';

class LightSetupPanel extends ConsumerWidget {
  const LightSetupPanel({super.key, required this.device});

  final LightDevice device;

  void _send(BuildContext context, WidgetRef ref, LightDevice Function(LightDevice d) update, String message) {
    sendDeviceCommand(context, ref, deviceId: device.id, update: (d) => update(d as LightDevice), message: message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingRow(
          title: 'Status Lampu',
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
              title: 'Kecerahan',
              body: PanelSlider(
                label: 'Tingkat kecerahan',
                icon: Icons.wb_sunny_outlined,
                value: device.brightness,
                onChangeEnd: (v) => adjustDevice(
                  context,
                  ref,
                  deviceId: device.id,
                  update: (d) => (d as LightDevice).copyWith(brightness: v),
                  describe: (d) => '${d.name}: kecerahan ${(d as LightDevice).brightness}%',
                ),
              ),
            ),
            SettingRow(
              title: 'Warna & Suhu Cahaya',
              subtitle: device.color.label,
              trailing: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final color in LightColor.values)
                    _LabeledSwatch(
                      color: color,
                      selected: device.color == color,
                      onTap: () {
                        if (device.color == color) return;
                        _send(context, ref, (d) => d.copyWith(color: color), '${device.name}: warna ${color.label}');
                      },
                    ),
                ],
              ),
            ),
            SettingRow(
              title: 'Zona',
              subtitle: 'Nyalakan per area ruangan',
              trailing: OptionPills<LightZone>(
                options: LightZone.values,
                isSelected: device.zones.contains,
                labelOf: (z) => z.label,
                onTap: (z) {
                  final on = !device.zones.contains(z);
                  _send(
                    context,
                    ref,
                    (d) => d.copyWith(zones: on ? {...d.zones, z} : ({...d.zones}..remove(z))),
                    '${device.name}: zona ${z.label.toLowerCase()} ${on ? 'dinyalakan' : 'dimatikan'}',
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Swatch with its label underneath (panel has more room than the tile).
class _LabeledSwatch extends StatelessWidget {
  const _LabeledSwatch({required this.color, required this.selected, required this.onTap});

  final LightColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(color.argb),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x0F000000), width: 2),
                boxShadow: selected
                    ? const [
                        BoxShadow(color: Colors.white, spreadRadius: 3),
                        BoxShadow(color: AppColors.red600, spreadRadius: 5),
                      ]
                    : const [],
              ),
              child: selected ? const Icon(Icons.check_rounded, size: 18, color: AppColors.textPrimary) : null,
            ),
            const SizedBox(height: 8),
            Text(
              color.label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.red700 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
