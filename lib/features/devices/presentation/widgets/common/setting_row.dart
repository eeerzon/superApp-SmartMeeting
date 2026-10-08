import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// One configuration row in a device panel: title/subtitle on the left,
/// [trailing] controls on the right (wraps below when too wide), and an
/// optional full-width [body] underneath.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.body,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final text = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (trailing == null)
            text
          else
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 24,
              runSpacing: 14,
              children: [text, trailing!],
            ),
          if (body != null) ...[const SizedBox(height: 14), body!],
        ],
      ),
    );
  }
}

/// Dims and disables its child while the device is powered off.
class PoweredSection extends StatelessWidget {
  const PoweredSection({super.key, required this.enabled, required this.children});

  final bool enabled;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.45,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final child in children) ...[const SizedBox(height: 12), child],
          ],
        ),
      ),
    );
  }
}
