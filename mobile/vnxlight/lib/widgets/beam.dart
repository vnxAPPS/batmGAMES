import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Луч света над кромкой лампы и «матричные» символы, которые медленно
/// плывут в нём вверх.
///
/// [intensity] — показываемая яркость 0..1 (уже сглаженная анимацией),
/// [time] — 0..1 по кругу, двигает символы.
class BeamPainter extends CustomPainter {
  BeamPainter({
    required this.intensity,
    required this.time,
    required this.edgeY,
    required this.lampWidth,
  });

  final double intensity;
  final double time;
  final double edgeY;
  final double lampWidth;

  // Цифры и греческие буквы есть в любом системном шрифте: японские
  // символы «матрицы» на части телефонов рисуются пустыми квадратами.
  static const _glyphs = [
    '0', '1', '0', '1', '7', 'Z', 'Δ', 'Λ', 'Ξ', 'Σ', 'Ψ', 'λ', 'ψ', 'Ω',
    '+', '<', '>',
  ];
  static final _rng = math.Random(7);
  static final _particles = List.generate(30, (_) => _Particle.random(_rng));
  static final Map<String, TextPainter> _glyphCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final half = lampWidth / 2;
    final i = intensity.clamp(0.0, 1.0);

    if (i > 0.001) {
      _paintBeam(canvas, size, cx, half, i);
      _paintParticles(canvas, cx, half, i);
    }
    _paintEdge(canvas, cx, half, i);
  }

  /// Ширина луча на высоте y: от кромки он расходится к верху экрана.
  double _halfWidthAt(double y, double half) {
    final t = 1 - (y / edgeY).clamp(0.0, 1.0);
    return half * (1 + 0.95 * t);
  }

  void _paintBeam(Canvas canvas, Size size, double cx, double half, double i) {
    Path trapezoid(double spread, double grow) => Path()
      ..moveTo(cx - half * spread, edgeY)
      ..lineTo(cx + half * spread, edgeY)
      ..lineTo(cx + half * (spread + grow), 0)
      ..lineTo(cx - half * (spread + grow), 0)
      ..close();

    final rect = Rect.fromLTWH(0, 0, size.width, edgeY);

    // Широкое мягкое свечение.
    canvas.drawPath(
      trapezoid(1.05, 1.25),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx, edgeY),
          Offset(cx, 0),
          [
            Palette.mint.withValues(alpha: 0.38 * i),
            Palette.blue.withValues(alpha: 0.10 * i),
            Colors.transparent,
          ],
          [0, 0.55, 1],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 38),
    );

    // Основной луч.
    canvas.drawPath(
      trapezoid(1.0, 0.95),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx, edgeY),
          Offset(cx, 0),
          [
            Palette.beam.withValues(alpha: 0.92 * i),
            Palette.beam.withValues(alpha: 0.38 * i),
            Palette.beam.withValues(alpha: 0.06 * i),
            Colors.transparent,
          ],
          [0, 0.28, 0.75, 1],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Яркое ядро у самой кромки.
    final core = Rect.fromCenter(
      center: Offset(cx, edgeY - 6),
      width: lampWidth * 0.9,
      height: 70,
    );
    canvas.drawOval(
      core,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85 * i)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );

    // Лёгкая подсветка всего экрана сверху: в темноте свет «отражается».
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, edgeY * 0.35),
          size.width,
          [Colors.white.withValues(alpha: 0.07 * i), Colors.transparent],
        ),
    );
  }

  void _paintParticles(Canvas canvas, double cx, double half, double i) {
    for (final p in _particles) {
      final progress = (time * p.speed + p.phase) % 1.0;
      final y = edgeY - 8 - progress * edgeY * 0.92;
      final x = cx + p.x * _halfWidthAt(y, half) * 0.85;
      // Появляется у кромки, гаснет к верху.
      final life = math.sin(progress * math.pi);
      final alpha = (0.75 * i * life * p.brightness).clamp(0.0, 1.0);
      if (alpha < 0.02) continue;
      final glyph = _glyphs[p.glyph % _glyphs.length];
      final painter = _glyph(glyph, p.size);
      canvas.saveLayer(
        Rect.fromLTWH(x - 10, y - 10, painter.width + 20, painter.height + 20),
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
      painter.paint(canvas, Offset(x, y));
      canvas.restore();
    }
  }

  TextPainter _glyph(String char, double size) =>
      _glyphCache.putIfAbsent('$char@$size', () {
        return TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              fontSize: size,
              color: Palette.mintLight,
              fontWeight: FontWeight.w600,
              shadows: const [Shadow(color: Palette.mint, blurRadius: 6)],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
      });

  void _paintEdge(Canvas canvas, double cx, double half, double i) {
    final a = Offset(cx - half, edgeY);
    final b = Offset(cx + half, edgeY);
    if (i > 0.001) {
      canvas.drawLine(
        a,
        b,
        Paint()
          ..strokeWidth = 6
          ..color = Palette.mint.withValues(alpha: 0.55 * i)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawLine(
      a,
      b,
      Paint()
        ..strokeWidth = 1.6
        ..shader = ui.Gradient.linear(a, b, [
          Colors.white.withValues(alpha: 0.05),
          Color.lerp(Palette.textDim, Colors.white, i)!.withValues(
            alpha: 0.35 + 0.65 * i,
          ),
          Colors.white.withValues(alpha: 0.05),
        ], [0, 0.5, 1]),
    );
  }

  @override
  bool shouldRepaint(BeamPainter old) =>
      old.intensity != intensity ||
      old.time != time ||
      old.edgeY != edgeY ||
      old.lampWidth != lampWidth;
}

class _Particle {
  _Particle(this.x, this.speed, this.phase, this.size, this.glyph, this.brightness);

  factory _Particle.random(math.Random r) => _Particle(
    r.nextDouble() * 2 - 1,
    0.6 + r.nextDouble() * 1.4,
    r.nextDouble(),
    9 + r.nextDouble() * 5,
    r.nextInt(1000),
    0.5 + r.nextDouble() * 0.5,
  );

  final double x;
  final double speed;
  final double phase;
  final double size;
  final int glyph;
  final double brightness;
}
