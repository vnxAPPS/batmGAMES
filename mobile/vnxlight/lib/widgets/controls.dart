import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Вертикальная полоска яркости. Палец по полоске задаёт яркость, низ —
/// выключено. Область касания шире самой полоски, чтобы попадать легко.
class BrightnessSlider extends StatefulWidget {
  const BrightnessSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onDragging,
    required this.label,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<bool> onDragging;
  final String label;

  @override
  State<BrightnessSlider> createState() => _BrightnessSliderState();
}

class _BrightnessSliderState extends State<BrightnessSlider> {
  static const _trackWidth = 12.0;
  int _bucket = -1;

  void _set(Offset local, double height) {
    final v = (1 - local.dy / height).clamp(0.0, 1.0);
    final bucket = (v * 10).floor();
    if (bucket != _bucket) {
      _bucket = bucket;
      HapticFeedback.selectionClick();
    }
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.value.clamp(0.0, 1.0);
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      return Semantics(
        key: const Key('brightness'),
        label: widget.label,
        slider: true,
        value: '${(v * 100).round()}%',
        increasedValue: '${((v + 0.1).clamp(0.0, 1.0) * 100).round()}%',
        decreasedValue: '${((v - 0.1).clamp(0.0, 1.0) * 100).round()}%',
        onIncrease: () => widget.onChanged((v + 0.1).clamp(0.0, 1.0)),
        onDecrease: () => widget.onChanged((v - 0.1).clamp(0.0, 1.0)),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _set(d.localPosition, h),
          onVerticalDragStart: (d) {
            widget.onDragging(true);
            _set(d.localPosition, h);
          },
          onVerticalDragUpdate: (d) => _set(d.localPosition, h),
          onVerticalDragEnd: (_) => widget.onDragging(false),
          onVerticalDragCancel: () => widget.onDragging(false),
          child: Center(
            child: Container(
              width: _trackWidth,
              height: h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(_trackWidth / 2),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                width: _trackWidth,
                // На самой малой яркости остаётся точка: видно, что свет есть.
                height: v <= 0 ? 0 : (_trackWidth + (h - _trackWidth) * v),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_trackWidth / 2),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Palette.mint, Colors.white],
                  ),
                  boxShadow: [
                    if (v > 0)
                      BoxShadow(
                        color: Palette.mint.withValues(alpha: 0.55),
                        blurRadius: 14,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Круглая кнопка включения: выключена — стеклянная, включена — мятная.
class PowerButton extends StatelessWidget {
  const PowerButton({
    super.key,
    required this.on,
    required this.onTap,
    required this.label,
    this.size = 84,
  });

  final bool on;
  final VoidCallback onTap;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: on,
      label: label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: on
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Palette.mintLight, Palette.mint],
                  )
                : null,
            color: on ? null : Colors.white.withValues(alpha: 0.10),
            border: Border.all(
              color: on
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.16),
            ),
            boxShadow: [
              if (on)
                BoxShadow(
                  color: Palette.mint.withValues(alpha: 0.55),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Icon(
              on ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
              key: ValueKey(on),
              size: size * 0.42,
              color: on
                  ? Palette.bgTop
                  : Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ),
      ),
    );
  }
}
