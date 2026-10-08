import 'package:flutter/material.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../nav_destinations.dart';

class SideNav extends StatelessWidget {
  const SideNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onLogout,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppLayout.sidebarWidth,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Column(
        children: [
          for (var i = 0; i < navDestinations.length; i++) ...[
            _NavItem(
              label: navDestinations[i].label,
              icon: i == currentIndex ? navDestinations[i].selectedIcon : navDestinations[i].icon,
              selected: i == currentIndex,
              onTap: () => onSelect(i),
            ),
            const SizedBox(height: 6),
          ],
          const Spacer(),
          _NavItem(label: 'Keluar', icon: Icons.logout_rounded, selected: false, onTap: onLogout),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.red600 : AppColors.textSecondary;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: selected ? AppColors.red50 : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(icon, size: 22, color: color),
                    const SizedBox(width: 12),
                    Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (selected)
          Positioned(
            left: -14,
            top: 14,
            bottom: 14,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
              ),
            ),
          ),
      ],
    );
  }
}
