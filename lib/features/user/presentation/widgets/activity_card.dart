import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../../devices/domain/entities/activity_entry.dart';
import '../../../devices/presentation/device_icons.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.entries, this.limit = 6});

  final List<ActivityEntry> entries;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final visible = entries.take(limit).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.history_rounded, size: 20, color: AppColors.red600),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aktivitas Terakhir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('Perintah yang dikirim dari tablet ini', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                    child: Icon(
                      visible[i].deviceType?.icon ?? Icons.auto_awesome_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(visible[i].message, style: const TextStyle(fontSize: 13.5)),
                        Text(visible[i].actor, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(formatHm(visible[i].time), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
