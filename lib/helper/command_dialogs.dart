import 'package:flutter/material.dart';

/// Dialog konfirmasi sebelum kirim perintah (`perintah[].konfirmasi: true`)
/// atau aksi penting lain (mis. keluar dari ruangan).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD6322C),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Dialog isian untuk perintah ber-parameter, mis. `volume_set` → `{value: 30}`.
/// Nilai awal dari status perangkat (`parameter.<nama>.state`, mis. "volume"),
/// kalau tidak ada pakai `min`. Saat ini hanya tipe `integer` (slider min..max).
/// Return null kalau dibatalkan atau tipe isian belum didukung.
Future<Map<String, dynamic>?> showParameterDialog(
  BuildContext context,
  String title,
  Map<String, dynamic> spec, {
  Map<String, dynamic>? state,
}) async {
  final values = <String, double>{};
  for (final entry in spec.entries) {
    final p = entry.value as Map<String, dynamic>;
    if (p['tipe'] != 'integer') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jenis isian "${p['tipe']}" belum didukung aplikasi.'),
          backgroundColor: const Color(0xFFD6322C),
          behavior: SnackBarBehavior.floating,
          width: 420,
        ),
      );
      return null;
    }
    final min = (p['min'] as num? ?? 0).toDouble();
    final max = (p['max'] as num? ?? 100).toDouble();
    final current = state?[p['state']];
    values[entry.key] =
        current is num ? current.toDouble().clamp(min, max) : min;
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in spec.entries)
              Builder(
                builder: (context) {
                  final p = entry.value as Map<String, dynamic>;
                  final min = (p['min'] as num? ?? 0).toDouble();
                  final max = (p['max'] as num? ?? 100).toDouble();
                  final value = values[entry.key]!;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Text(p['label']?.toString() ?? entry.key),
                          const Spacer(),
                          Text(
                            '${value.round()}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Slider(
                        value: value,
                        min: min,
                        max: max,
                        divisions: (max - min).round(),
                        activeColor: const Color(0xFFD6322C),
                        onChanged: (v) =>
                            setDialogState(() => values[entry.key] = v),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD6322C),
            ),
            child: const Text('Kirim'),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return null;
  return values.map((key, v) => MapEntry(key, v.round()));
}
