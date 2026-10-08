import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/device.dart';
import '../device_icons.dart';
import '../providers/room_devices_controller.dart';
import 'common/panel_controls.dart';

/// Units of the selected type (IFP 001, IFP 002, ...).
class DeviceUnitList extends StatelessWidget {
  const DeviceUnitList({
    super.key,
    required this.units,
    required this.selectedId,
    required this.statusOf,
    required this.onSelected,
  });

  final List<Device> units;
  final String selectedId;
  final DeviceLinkStatus Function(String id) statusOf;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final unit in units) ...[
          _UnitCard(
            unit: unit,
            selected: unit.id == selectedId,
            status: statusOf(unit.id),
            onTap: () => onSelected(unit.id),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({required this.unit, required this.selected, required this.status, required this.onTap});

  final Device unit;
  final bool selected;
  final DeviceLinkStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.red50 : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppColors.red600 : AppColors.border, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? AppColors.surface : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(unit.type.icon, size: 20, color: selected ? AppColors.red600 : AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(unit.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(
                      unit.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              UnitStatusBadge(status: status, poweredOn: unit.isOn),
            ],
          ),
        ),
      ),
    );
  }
}
