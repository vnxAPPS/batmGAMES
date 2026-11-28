import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'l10n.dart';
import 'theme.dart';
import 'torch.dart';
import 'widgets/beam.dart';
import 'widgets/controls.dart';

/// Единственный экран: луч над кромкой лампы, полоска яркости и кнопка.
class LightScreen extends StatefulWidget {
  const LightScreen({super.key, required this.torch});

  final TorchController torch;

  @override
  State<LightScreen> createState() => _LightScreenState();
}

class _LightScreenState extends State<LightScreen>
    with TickerProviderStateMixin {
  /// Показываемая яркость: догоняет настоящую плавно, поэтому свет
  /// разгорается и гаснет, а не щёлкает.
  late final AnimationController _shown = AnimationController(vsync: this);

  /// Время для плывущих символов в луче.
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _shown.value = widget.torch.value;
    widget.torch.addListener(_onTorch);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    widget.torch.removeListener(_onTorch);
    _shown.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _onTorch() {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final target = widget.torch.value;
    if (still) {
      _shown.value = target;
    } else {
      _shown.animateTo(
        target,
        duration: Duration(milliseconds: _dragging ? 90 : 560),
        curve: Curves.easeOutCubic,
      );
    }
    setState(() {});
  }

  bool _toldNoFlash = false;

  /// Без вспышки один раз объясняем, почему светит только экран: постоянная
  /// подпись мешала бы смотреть на свет (и попала бы в скриншоты).
  void _toggle(L10n l) {
    widget.torch.toggle();
    if (!widget.torch.available && widget.torch.on && !_toldNoFlash) {
      _toldNoFlash = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('no-flash'),
          content: Text(l.noFlash),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final torch = widget.torch;
    return Scaffold(
      body: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final edgeY = h * 0.5;
        final lampW = math.min(w * 0.5, 340.0);
        final sliderTop = edgeY + h * 0.075;
        final sliderH = h * 0.17;
        const buttonSize = 84.0;
        return Stack(
          children: [
            Positioned.fill(child: _Backdrop(shown: _shown)),
            // Корпус лампы под кромкой.
            Positioned(
              left: (w - lampW) / 2,
              top: edgeY,
              width: lampW,
              height: h * 0.36,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xE0070C18), Color(0x00070C18)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_shown, _clock]),
                  builder: (context, _) => CustomPaint(
                    painter: BeamPainter(
                      intensity: _shown.value,
                      time: _clock.value,
                      edgeY: edgeY,
                      lampWidth: lampW,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: w / 2 - 28,
              top: sliderTop,
              width: 56,
              height: sliderH,
              child: BrightnessSlider(
                value: torch.value,
                label: l.brightness,
                onDragging: (d) => _dragging = d,
                onChanged: torch.setValue,
              ),
            ),
            Positioned(
              left: (w - buttonSize) / 2,
              top: h * 0.82,
              child: PowerButton(
                key: const Key('power'),
                on: torch.on,
                label: torch.on ? l.turnOff : l.turnOn,
                size: buttonSize,
                onTap: () => _toggle(l),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Фон: тёмно-синий градиент и размытые цветные пятна. Со светом фон чуть
/// светлеет — как стена, на которую падает луч.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.shown});

  final Animation<double> shown;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Palette.bgTop, Palette.bgBottom],
            ),
          ),
        ),
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: const CustomPaint(painter: _BlobsPainter()),
        ),
        AnimatedBuilder(
          animation: shown,
          builder: (context, _) => ColoredBox(
            color: Colors.white.withValues(alpha: 0.035 * shown.value),
          ),
        ),
      ],
    );
  }
}

class _BlobsPainter extends CustomPainter {
  const _BlobsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    void blob(double x, double y, double r, Color c) => canvas.drawCircle(
      Offset(size.width * x, size.height * y),
      size.width * r,
      Paint()..color = c,
    );
    blob(0.22, 0.18, 0.30, Palette.blue.withValues(alpha: 0.22));
    blob(0.85, 0.30, 0.26, Palette.teal.withValues(alpha: 0.16));
    blob(0.15, 0.62, 0.24, Palette.mint.withValues(alpha: 0.10));
    blob(0.80, 0.70, 0.22, Palette.blue.withValues(alpha: 0.14));
    blob(0.50, 0.92, 0.30, Palette.teal.withValues(alpha: 0.10));
  }

  @override
  bool shouldRepaint(_BlobsPainter old) => false;
}
