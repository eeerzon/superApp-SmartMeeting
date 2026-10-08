import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';

class SceneButton extends StatelessWidget {
  const SceneButton({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.active,
    required this.running,
    required this.onTap,
    this.neutralIcon = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;

  /// Last applied scene: gradient background.
  final bool active;

  /// Currently being applied: spinner instead of icon.
  final bool running;

  /// Null disables the button (another scene is running).
  final VoidCallback? onTap;

  /// Gray icon box instead of red (used for "Selesai").
  final bool neutralIcon;

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : AppColors.textPrimary;
    final iconBg = active
        ? Colors.white.withAlpha(46)
        : neutralIcon
            ? AppColors.background
            : AppColors.red50;
    final iconFg = active ? Colors.white : (neutralIcon ? AppColors.textPrimary : AppColors.red600);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: active ? null : AppColors.surface,
        gradient: active ? AppGradients.brand : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? Colors.transparent : AppColors.border),
        boxShadow: active
            ? const [BoxShadow(color: AppColors.redShadow, blurRadius: 20, spreadRadius: -8, offset: Offset(0, 8))]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: running
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: iconFg),
                          )
                        : Icon(icon, size: 22, color: iconFg),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: active ? Colors.white.withAlpha(217) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
