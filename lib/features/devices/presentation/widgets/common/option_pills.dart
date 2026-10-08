import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_gradients.dart';

/// Group of rounded option pills (single or multi select via [isSelected]).
class OptionPills<T> extends StatelessWidget {
  const OptionPills({
    super.key,
    required this.options,
    required this.isSelected,
    required this.labelOf,
    required this.onTap,
    this.iconOf,
  });

  final List<T> options;
  final bool Function(T option) isSelected;
  final String Function(T option) labelOf;
  final IconData Function(T option)? iconOf;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          _Pill(
            label: labelOf(option),
            icon: iconOf?.call(option),
            selected: isSelected(option),
            onTap: () => onTap(option),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.red700 : AppColors.textSecondary;
    return Material(
      color: selected ? AppColors.red50 : AppColors.surface,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? AppColors.red600 : AppColors.border, width: 1.5),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: EdgeInsets.only(left: icon == null ? 16 : 6, right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? null : AppColors.background,
                      gradient: selected ? AppGradients.primary : null,
                    ),
                    child: Icon(icon, size: 16, color: selected ? Colors.white : AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
