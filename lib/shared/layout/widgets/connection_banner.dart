import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/realtime/connection_status.dart';
import '../../../core/theme/app_colors.dart';

/// Shown under the top bar while the server is unreachable.
class ConnectionBanner extends ConsumerStatefulWidget {
  const ConnectionBanner({super.key});

  @override
  ConsumerState<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends ConsumerState<ConnectionBanner> {
  bool _reconnecting = false;

  Future<void> _reconnect() async {
    setState(() => _reconnecting = true);
    await ref.read(serverConnectionProvider.notifier).reconnect();
    if (!mounted) return;
    setState(() => _reconnecting = false);
    showAppToast(context, 'Terhubung kembali ke server');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.pagePadding, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.red50,
        border: Border(bottom: BorderSide(color: AppColors.red100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 20, color: AppColors.red700),
          const SizedBox(width: 12),
          const Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Koneksi ke server terputus. ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: 'Perintah tidak dapat dikirim, status perangkat mungkin tidak terbaru.'),
                ],
              ),
              style: TextStyle(color: AppColors.red700, fontSize: 13.5),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(backgroundColor: AppColors.surface, minimumSize: const Size(0, 44)),
            onPressed: _reconnecting ? null : _reconnect,
            icon: _reconnecting
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded, size: 18),
            label: Text(_reconnecting ? 'Menghubungkan…' : 'Coba lagi'),
          ),
        ],
      ),
    );
  }
}
