import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../domain/entities/device_type.dart';
import '../device_icons.dart';

class DeviceTypeTabs extends StatelessWidget {
  const DeviceTypeTabs({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.typesWithOfflineUnits,
  });

  final DeviceType selected;
  final ValueChanged<DeviceType> onSelected;

  /// Tabs that get a warning dot.
  final Set<DeviceType> typesWithOfflineUnits;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final type in DeviceType.values)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _Tab(
                  type: type,
                  selected: type == selected,
                  warning: typesWithOfflineUnits.contains(type),
                  onTap: () => onSelected(type),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.type, required this.selected, required this.warning, required this.onTap});

  final DeviceType type;
  final bool selected;
  final bool warning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textSecondary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        gradient: selected ? AppGradients.primary : null,
        borderRadius: BorderRadius.circular(10),
        boxShadow: selected
            ? const [BoxShadow(color: AppColors.redShadow, blurRadius: 16, spreadRadius: -8, offset: Offset(0, 6))]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(type.icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                  Text(type.shortLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
                  if (warning) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
