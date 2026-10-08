import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

// Controls used only inside dashboard tiles. Each takes explicit parameters
// so a tile can tune size/layout without affecting other pages.

/// Mode/input button. [horizontal] puts the icon beside the label.
class TileChoiceButton extends StatelessWidget {
  const TileChoiceButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.horizontal = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.red700 : AppColors.textSecondary;
    final children = [
      Icon(icon, size: horizontal ? 18 : 20, color: fg),
      SizedBox(width: horizontal ? 8 : 0, height: horizontal ? 0 : 4),
      Flexible(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: horizontal ? 13 : 12, fontWeight: FontWeight.w600, color: fg),
        ),
      ),
    ];
    return Material(
      color: selected ? AppColors.red50 : AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? AppColors.red600 : Colors.transparent, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: horizontal ? 48 : 56,
          child: horizontal
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: children)
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: children),
        ),
      ),
    );
  }
}

/// Circular +/- or toggle button.
class TileRoundButton extends StatelessWidget {
  const TileRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 48,
    this.highlighted = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: highlighted ? AppColors.red50 : AppColors.surface,
        shape: CircleBorder(
          side: BorderSide(color: highlighted ? AppColors.red600 : AppColors.border, width: 1.5),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: 20, color: highlighted ? AppColors.red700 : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Slider with label + value. Keeps its own value while dragging and only
/// reports the final value via [onChangeEnd].
class TileSlider extends StatefulWidget {
  const TileSlider({
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

  /// Extra control next to the value, e.g. a mute button.
  final Widget? trailing;

  @override
  State<TileSlider> createState() => _TileSliderState();
}

class _TileSliderState extends State<TileSlider> {
  late double _value = widget.value.toDouble();
  bool _dragging = false;

  @override
  void didUpdateWidget(TileSlider oldWidget) {
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
            Expanded(
              child: Text(widget.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            if (widget.trailing != null) ...[widget.trailing!, const SizedBox(width: 8)],
            SizedBox(
              width: 40,
              child: Text(
                '${_value.round()}%',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
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
