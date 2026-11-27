import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Фон: тёмно-синий градиент и медленно плывущие мятные и синие пятна.
/// Если в системе отключены анимации, пятна стоят на месте.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.bgTop, Palette.bgBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) =>
                  CustomPaint(painter: _AuroraPainter(_c.value)),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final a = t * 2 * math.pi;
    void blob(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    final w = size.width, h = size.height;
    blob(Offset(w * (0.2 + 0.08 * math.sin(a)), h * (0.15 + 0.05 * math.cos(a))),
        w * 0.75, Palette.mint.withValues(alpha: 0.16));
    blob(Offset(w * (0.9 + 0.06 * math.cos(a * 2)), h * (0.45 + 0.06 * math.sin(a))),
        w * 0.7, Palette.blue.withValues(alpha: 0.14));
    blob(Offset(w * (0.3 + 0.07 * math.cos(a)), h * (0.95 + 0.04 * math.sin(a * 2))),
        w * 0.8, Palette.teal.withValues(alpha: 0.12));
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
}

/// Стеклянная карточка: размытие под ней, полупрозрачная заливка, тонкая
/// светлая рамка.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(
              color: highlight
                  ? Palette.mint.withValues(alpha: 0.7)
                  : Palette.stroke,
              width: highlight ? 1.6 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Главная кнопка: мятный градиент, мягкое свечение.
class MintButton extends StatelessWidget {
  const MintButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 60,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: Palette.mintGradient,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: Palette.mint.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(height / 2),
            onTap: onPressed,
            child: SizedBox(
              height: height,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Palette.bgBottom, size: 24),
                      const SizedBox(width: 10),
                    ],
                    Text(label, style: font(19, 800, color: Palette.bgBottom)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Второстепенная кнопка: стеклянная, с мятной надписью.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onPressed,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Palette.stroke),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Palette.mintLight, size: 22),
                  const SizedBox(width: 10),
                ],
                Text(label, style: font(17, 700, color: Palette.mintLight)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Круглая стеклянная кнопка с иконкой.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.glow = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      type: MaterialType.transparency,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: glow ? Palette.mint.withValues(alpha: 0.18) : Palette.surface,
            border: Border.all(
              color: glow ? Palette.mint : Palette.stroke,
            ),
            boxShadow: [
              if (glow)
                BoxShadow(
                  color: Palette.mint.withValues(alpha: 0.45),
                  blurRadius: 18,
                ),
            ],
          ),
          child: Icon(icon, color: glow ? Palette.mintLight : Palette.text),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Логотип-знак: квадрат 2×2 со знаками действий.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    final tile = size * 0.44;
    Widget cell(String sign, Color color, {bool filled = false}) => Container(
      width: tile,
      height: tile,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tile * 0.32),
        color: filled ? color : color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 1.4),
      ),
      alignment: Alignment.center,
      child: Text(
        sign,
        style: font(tile * 0.62, 800,
            color: filled ? Palette.bgBottom : color),
      ),
    );
    return SizedBox(
      width: size,
      height: size,
      child: Wrap(
        spacing: size * 0.12,
        runSpacing: size * 0.12,
        children: [
          cell('+', Palette.mint, filled: true),
          cell('−', Palette.blue),
          cell('×', Palette.blue),
          cell('÷', Palette.mint),
        ],
      ),
    );
  }
}
