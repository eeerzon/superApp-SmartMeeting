import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_gradients.dart';
import '../../providers/room_devices_controller.dart';

// Controls used only inside device setup panels.

class PanelRoundButton extends StatelessWidget {
  const PanelRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 48,
    this.highlighted = false,
    this.filled = false,
    this.square = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final bool highlighted;

  /// Red gradient background (e.g. PTZ home).
  final bool filled;

  /// Rounded square instead of circle (PTZ pad).
  final bool square;

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shape = square
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: filled ? Colors.transparent : AppColors.border, width: 1.5),
          )
        : CircleBorder(side: BorderSide(color: highlighted ? AppColors.red600 : AppColors.border, width: 1.5));

    final button = Material(
      color: filled ? Colors.transparent : (highlighted ? AppColors.red50 : AppColors.surface),
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: 20,
            color: filled ? Colors.white : (highlighted ? AppColors.red700 : AppColors.textPrimary),
          ),
        ),
      ),
    );

    return Tooltip(
      message: tooltip,
      child: filled
          ? DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(14)),
              child: button,
            )
          : button,
    );
  }
}

/// − value + stepper.
class PanelStepper extends StatelessWidget {
  const PanelStepper({
    super.key,
    required this.value,
    required this.label,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String value;

  /// Used in tooltips: "Kurangi <label>".
  final String label;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PanelRoundButton(icon: Icons.remove_rounded, tooltip: 'Kurangi $label', onTap: onDecrement),
        const SizedBox(width: 8),
        Container(
          constraints: const BoxConstraints(minWidth: 76),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        PanelRoundButton(icon: Icons.add_rounded, tooltip: 'Tambah $label', onTap: onIncrement),
      ],
    );
  }
}

/// Slider that reports only the final value.
class PanelSlider extends StatefulWidget {
  const PanelSlider({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChangeEnd,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChangeEnd;
  final Widget? trailing;

  @override
  State<PanelSlider> createState() => _PanelSliderState();
}

class _PanelSliderState extends State<PanelSlider> {
  late double _value = widget.value.toDouble();
  bool _dragging = false;

  @override
  void didUpdateWidget(PanelSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging) _value = widget.value.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(widget.icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(child: Text(widget.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            if (widget.trailing != null) ...[widget.trailing!, const SizedBox(width: 8)],
            Text(
              '${_value.round()}%',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Slider(
          value: _value,
          max: 100,
          onChangeStart: (_) => _dragging = true,
          onChanged: (v) => setState(() => _value = v),
          onChangeEnd: (v) {
            _dragging = false;
            widget.onChangeEnd(v.round());
          },
        ),
      ],
    );
  }
}

/// Online / Offline / Sinkron / Mati badge.
class UnitStatusBadge extends StatelessWidget {
  const UnitStatusBadge({super.key, required this.status, required this.poweredOn});

  final DeviceLinkStatus status;
  final bool poweredOn;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, label) = switch (status) {
      DeviceLinkStatus.offline => (AppColors.red50, AppColors.red700, Icons.wifi_off_rounded, 'Offline'),
      DeviceLinkStatus.pending || DeviceLinkStatus.syncing =>
        (AppColors.warningBg, AppColors.warningText, Icons.sync_rounded, 'Sinkron'),
      DeviceLinkStatus.online when !poweredOn =>
        (AppColors.background, AppColors.textSecondary, Icons.power_settings_new_rounded, 'Mati'),
      DeviceLinkStatus.online => (AppColors.onlineBg, AppColors.online, Icons.check_rounded, 'Online'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}
