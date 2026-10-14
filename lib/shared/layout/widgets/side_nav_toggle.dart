import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';

/// Sidebar shown (false) or hidden to a thin strip (true).
final sideNavCollapsedProvider = StateProvider<bool>((ref) => false);

/// Floating chevron tab attached to the right edge of the sidebar.
/// Points left when the menu is open, right when it is hidden.
class SideNavToggle extends StatelessWidget {
  const SideNavToggle({super.key, required this.collapsed, required this.onTap});

  final bool collapsed;
  final VoidCallback onTap;

  static const _tabWidth = 24.0;
  static const _tabHeight = 56.0;
  static const _radius = BorderRadius.horizontal(right: Radius.circular(12));

  @override
  Widget build(BuildContext context) {
    final label = collapsed ? 'Tampilkan menu' : 'Sembunyikan menu';
    return Semantics(
      button: true,
      expanded: !collapsed,
      label: label,
      child: Tooltip(
        message: label,
        // The gesture area is wider than the visible tab (≥44 px touch target).
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: _tabHeight + 12,
            child: Align(
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  borderRadius: _radius,
                  boxShadow: [BoxShadow(color: Color(0x2E101828), blurRadius: 12, spreadRadius: -4, offset: Offset(4, 0))],
                ),
                child: Material(
                  color: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: _radius,
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: InkWell(
                    customBorder: const RoundedRectangleBorder(borderRadius: _radius),
                    hoverColor: AppColors.red50,
                    highlightColor: AppColors.red100,
                    onTap: onTap,
                    child: SizedBox(
                      width: _tabWidth,
                      height: _tabHeight,
                      child: AnimatedRotation(
                        turns: collapsed ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: const Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.red600),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
