import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../puzzles/model.dart';
import '../theme.dart';

/// Отрисовка задачи любого типа. [input] — то, что игрок уже набрал: оно
/// показывается на месте «?».
class PuzzleView extends StatelessWidget {
  const PuzzleView({super.key, required this.puzzle, required this.input});

  final Puzzle puzzle;
  final String input;

  @override
  Widget build(BuildContext context) {
    return switch (puzzle) {
      SequencePuzzle p => _SequenceView(p, input),
      PyramidPuzzle p => _PyramidView(p, input),
      ShapesPuzzle p => _ShapesView(p, input),
      GridPuzzle p => _GridView(p, input),
      TrianglePuzzle p => _TrianglesView(p, input),
    };
  }
}

/// Клетка с числом; [question] — клетка «?», подсвечена мятой.
class NumberCell extends StatelessWidget {
  const NumberCell({
    super.key,
    required this.text,
    this.question = false,
    this.size = 56,
    this.circle = false,
    this.dim = false,
  });

  final String text;
  final bool question;
  final double size;
  final bool circle;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final radius = circle ? size / 2 : size * 0.28;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: question
            ? LinearGradient(
                colors: [
                  Palette.mint.withValues(alpha: 0.30),
                  Palette.teal.withValues(alpha: 0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: question
            ? null
            : dim
            ? Colors.white.withValues(alpha: 0.03)
            : Palette.surfaceStrong,
        border: Border.all(
          color: question ? Palette.mint : Palette.stroke,
          width: question ? 1.8 : 1,
        ),
        boxShadow: [
          if (question)
            BoxShadow(
              color: Palette.mint.withValues(alpha: 0.35),
              blurRadius: 16,
            ),
        ],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            text,
            style: font(size * 0.42, 800,
                color: question ? Palette.mintLight : Palette.text),
          ),
        ),
      ),
    );
  }
}

String _slot(String input) => input.isEmpty ? '?' : input;

class _SequenceView extends StatelessWidget {
  const _SequenceView(this.p, this.input);

  final SequencePuzzle p;
  final String input;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final perRow = p.items.length <= 5 ? p.items.length : 4;
      final size = math.min(68.0, (c.maxWidth - (perRow - 1) * 12) / perRow);
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final x in p.items)
            NumberCell(
              text: x == null ? _slot(input) : '$x',
              question: x == null,
              size: size,
              circle: true,
            ),
        ],
      );
    });
  }
}

class _PyramidView extends StatelessWidget {
  const _PyramidView(this.p, this.input);

  final PyramidPuzzle p;
  final String input;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return LayoutBuilder(builder: (context, c) {
      const gap = 6.0;
      final size =
          math.min(64.0, (c.maxWidth - (p.height - 1) * gap) / p.height);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = p.height - 1; row >= 0; row--)
            Padding(
              padding: const EdgeInsets.only(bottom: gap),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var col = 0; col < p.height - row; col++)
                    Padding(
                      padding: EdgeInsets.only(right: col < p.height - row - 1 ? gap : 0),
                      child: _block(row, col, size),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(l.pyramidTip, style: font(13, 600, color: Palette.textDim)),
        ],
      );
    });
  }

  Widget _block(int row, int col, double size) {
    final cell = (row, col);
    if (cell == p.question) {
      return NumberCell(text: _slot(input), question: true, size: size);
    }
    if (p.visible.contains(cell)) {
      return NumberCell(text: '${p.full[row][col]}', size: size);
    }
    return NumberCell(text: '', size: size, dim: true);
  }
}

class ShapeIcon extends StatelessWidget {
  const ShapeIcon(this.shape, {super.key, this.size = 40});

  final Shape shape;
  final double size;

  static Color colorOf(Shape s) => switch (s) {
    Shape.triangle => Palette.mint,
    Shape.circle => Palette.blue,
    Shape.square => Palette.violet,
    Shape.star => Palette.amber,
  };

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _ShapePainter(shape, colorOf(shape))),
  );
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.shape, this.color);

  final Shape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final inset = r.deflate(size.width * 0.08);
    final path = Path();
    switch (shape) {
      case Shape.triangle:
        path
          ..moveTo(inset.center.dx, inset.top)
          ..lineTo(inset.right, inset.bottom)
          ..lineTo(inset.left, inset.bottom)
          ..close();
      case Shape.circle:
        path.addOval(inset);
      case Shape.square:
        path.addRRect(RRect.fromRectAndRadius(
            inset.deflate(size.width * 0.04), Radius.circular(size.width * 0.18)));
      case Shape.star:
        final c = inset.center;
        final outer = inset.width / 2, inner = outer * 0.45;
        for (var i = 0; i < 10; i++) {
          final rr = i.isEven ? outer : inner;
          final a = -math.pi / 2 + i * math.pi / 5;
          final pt = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        path.close();
    }
    canvas.drawShadow(path, color.withValues(alpha: 0.6), 4, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.35)!, color],
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.shape != shape || old.color != color;
}

class _ShapesView extends StatelessWidget {
  const _ShapesView(this.p, this.input);

  final ShapesPuzzle p;
  final String input;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final e in p.equations)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final t in e.left) ...[
                    if (t.shape != null)
                      ShapeIcon(t.shape!)
                    else if (t.number != null)
                      Text('${t.number}', style: font(30, 800))
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(t.op!,
                            style: font(28, 700, color: Palette.textDim)),
                      ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('=',
                        style: font(28, 700, color: Palette.textDim)),
                  ),
                  if (e.right != null)
                    SizedBox(
                      width: 64,
                      child: Text('${e.right}', style: font(30, 800)),
                    )
                  else
                    NumberCell(text: _slot(input), question: true, size: 54),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _GridView extends StatelessWidget {
  const _GridView(this.p, this.input);

  final GridPuzzle p;
  final String input;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = math.min(76.0, (c.maxWidth - 24) / 3);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in p.cells)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, x) in row.indexed)
                    Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
                      child: NumberCell(
                        text: x == null ? _slot(input) : '$x',
                        question: x == null,
                        size: size,
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    });
  }
}

class _TrianglesView extends StatelessWidget {
  const _TrianglesView(this.p, this.input);

  final TrianglePuzzle p;
  final String input;

  @override
  Widget build(BuildContext context) {
    // Примеры — парами в ряд, задача с «?» — отдельно под ними: три
    // треугольника в одну строку на телефоне слишком мелкие.
    return LayoutBuilder(builder: (context, c) {
      const gap = 14.0;
      final examples = [for (final t in p.tris) if (t.center != null) t];
      final open = p.tris.firstWhere((t) => t.center == null);
      final w = math.min(150.0, (c.maxWidth - gap) / 2);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < examples.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: gap),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Triangle(examples[i], w, input),
                  if (i + 1 < examples.length) ...[
                    const SizedBox(width: gap),
                    _Triangle(examples[i + 1], w, input),
                  ],
                ],
              ),
            ),
          _Triangle(open, w, input),
        ],
      );
    });
  }
}

class _Triangle extends StatelessWidget {
  const _Triangle(this.t, this.width, this.input);

  final Tri t;
  final double width;
  final String input;

  @override
  Widget build(BuildContext context) {
    final h = width * 1.05;
    final num = font(width * 0.17, 800);
    final q = t.center == null;
    return SizedBox(
      width: width,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: width * 0.2,
            bottom: width * 0.2,
            left: width * 0.1,
            right: width * 0.1,
            child: CustomPaint(painter: _TrianglePainter(highlight: q)),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Text('${t.top}', style: num),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text('${t.left}', style: num),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text('${t.right}', style: num),
          ),
          Align(
            alignment: const Alignment(0, 0.25),
            child: q
                ? NumberCell(
                    text: _slot(input), question: true, size: width * 0.34)
                : Text('${t.center}',
                    style: font(width * 0.2, 800, color: Palette.mintLight)),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter({required this.highlight});

  final bool highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Palette.mint.withValues(alpha: highlight ? 0.18 : 0.10),
            Palette.blue.withValues(alpha: 0.06),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..color = highlight
            ? Palette.mint.withValues(alpha: 0.9)
            : Palette.stroke.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.highlight != highlight;
}
