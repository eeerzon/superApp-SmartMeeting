import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/realtime/connection_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../devices/presentation/providers/room_devices_controller.dart';
import '../providers/settings_controller.dart';
import 'settings_card.dart';

class ConnectionSection extends ConsumerStatefulWidget {
  const ConnectionSection({super.key});

  @override
  ConsumerState<ConnectionSection> createState() => _ConnectionSectionState();
}

class _ConnectionSectionState extends ConsumerState<ConnectionSection> {
  late final TextEditingController _api;
  late final TextEditingController _mqtt;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsControllerProvider);
    _api = TextEditingController(text: settings.apiBaseUrl);
    _mqtt = TextEditingController(text: settings.mqttBrokerUrl);
  }

  @override
  void dispose() {
    _api.dispose();
    _mqtt.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(settingsControllerProvider.notifier).update(
          (s) => s.copyWith(apiBaseUrl: _api.text.trim(), mqttBrokerUrl: _mqtt.text.trim()),
        );
    showAppToast(context, 'Alamat koneksi disimpan');
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    // TODO: real health check against API + broker.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _testing = false);
    final online = ref.read(serverConnectionProvider);
    showAppToast(
      context,
      online ? 'Server & broker MQTT merespons (32 ms)' : 'Server tidak merespons. Periksa jaringan tablet.',
      kind: online ? ToastKind.success : ToastKind.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(serverConnectionProvider);
    final deviceCount = ref.watch(roomDevicesProvider.select((s) => s.devices.length));

    return SettingsCard(
      icon: Icons.dns_outlined,
      title: 'Koneksi',
      subtitle: 'Server API dan broker MQTT untuk status real-time',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: online ? AppColors.online : AppColors.red600,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(online ? 'Terhubung' : 'Terputus', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    online ? '· MQTT aktif, $deviceCount perangkat tersinkron' : '· mencoba menghubungkan ulang',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                if (online) const Text('32 ms', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Alamat server API', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(controller: _api, keyboardType: TextInputType.url, onSubmitted: (_) => _save()),
              const SizedBox(height: 14),
              const Text('Broker MQTT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(controller: _mqtt, keyboardType: TextInputType.url, onSubmitted: (_) => _save()),
              const SizedBox(height: 14),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _testing ? null : _test,
                    icon: _testing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.wifi_rounded, size: 18),
                    label: Text(_testing ? 'Menguji…' : 'Uji koneksi'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _save, child: const Text('Simpan')),
                ],
              ),
            ],
          ),
        ),
        SettingsTile(
          title: 'Simulasi koneksi terputus',
          subtitle: 'Khusus prototype, untuk melihat tampilan saat offline',
          trailing: Switch(
            value: !online,
            onChanged: (offline) {
              ref.read(serverConnectionProvider.notifier).setOnline(!offline);
              showAppToast(
                context,
                offline ? 'Simulasi: koneksi terputus' : 'Koneksi dipulihkan',
                kind: offline ? ToastKind.error : ToastKind.success,
              );
            },
          ),
        ),
      ],
    );
  }
}
