import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../progress_scope.dart';
import '../puzzles/levels.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/puzzle_views.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key, required this.level});

  final int level;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen>
    with TickerProviderStateMixin {
  static const _maxDigits = 4;

  String _input = '';
  int _wrong = 0;
  bool _hint = false;
  bool _answer = false;
  bool _solved = false;
  String? _message;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _shake.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _press(String key) {
    if (_solved) return;
    HapticFeedback.selectionClick();
    setState(() {
      _message = null;
      if (key == '⌫') {
        if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
      } else if (_input.length < _maxDigits) {
        _input = _input == '0' ? key : _input + key;
      }
    });
  }

  Future<void> _check() async {
    if (_input.isEmpty || _solved) return;
    final puzzle = levels[widget.level];
    final progress = ProgressScope.of(context);
    final l = L10n.of(context);
    if (int.tryParse(_input) == puzzle.answer) {
      HapticFeedback.mediumImpact();
      setState(() => _solved = true);
      _burst.forward(from: 0);
      if (_hint || _answer) await progress.markHinted(widget.level);
      await progress.markSolved(widget.level);
    } else {
      HapticFeedback.heavyImpact();
      _shake.forward(from: 0);
      setState(() {
        _wrong++;
        _input = '';
        _message = l.wrong;
      });
    }
  }

  void _next() {
    final nextLevel = widget.level + 1;
    if (nextLevel >= levels.length) {
      Navigator.of(context).pop();
      showDialog<void>(context: context, builder: (_) => const AllDoneDialog());
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, _, _) => PuzzleScreen(level: nextLevel),
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.06, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final puzzle = levels[widget.level];
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            l.level(widget.level + 1),
                            textAlign: TextAlign.center,
                            style: font(20, 800),
                          ),
                        ),
                        RoundIconButton(
                          key: const Key('hint'),
                          icon: Icons.lightbulb_outline_rounded,
                          tooltip: l.hint,
                          glow: _wrong >= 2 && !_hint,
                          onPressed: () => setState(() => _hint = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _shake,
                        builder: (context, child) {
                          final t = _shake.value;
                          final dx = math.sin(t * math.pi * 6) * 14 * (1 - t);
                          return Transform.translate(
                              offset: Offset(dx, 0), child: child);
                        },
                        child: Glass(
                          highlight: _solved,
                          padding: const EdgeInsets.all(18),
                          // Задача видна целиком: на низком экране она
                          // ужимается, а не уходит под край прокрутки.
                          child: LayoutBuilder(
                            builder: (context, c) => Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SizedBox(
                                  width: c.maxWidth,
                                  child: PuzzleView(
                                      puzzle: puzzle, input: _input),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: _hintPanel(l),
                    ),
                    SizedBox(
                      height: 30,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _message ?? '',
                            key: ValueKey(_message),
                            style: font(15, 700, color: Palette.error),
                          ),
                        ),
                      ),
                    ),
                    Keypad(onKey: _press, onCheck: _input.isEmpty ? null : _check),
                  ],
                ),
              ),
              if (_solved)
                _SuccessOverlay(
                  burst: _burst,
                  onNext: _next,
                  rule: puzzle.hint.of(l.ru),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hintPanel(L10n l) {
    if (!_hint) return const SizedBox(width: double.infinity);
    final puzzle = levels[widget.level];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Glass(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_rounded, color: Palette.amber, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                (_answer ? puzzle.solution : puzzle.hint).of(l.ru),
                style: font(15, 600),
              ),
            ),
            if (!_answer)
              TextButton(
                onPressed: () => setState(() => _answer = true),
                child: Text(l.showAnswer,
                    style: font(14, 700, color: Palette.mintLight)),
              ),
          ],
        ),
      ),
    );
  }
}

class Keypad extends StatelessWidget {
  const Keypad({super.key, required this.onKey, required this.onCheck});

  final ValueChanged<String> onKey;
  final VoidCallback? onCheck;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['⌫', '0', '✓'],
    ];
    final l = L10n.of(context);
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                for (final (i, k) in row.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: k == '✓'
                        ? Semantics(
                            button: true,
                            label: l.check,
                            child: MintButton(
                              key: const Key('check'),
                              label: '✓',
                              height: 56,
                              onPressed: onCheck,
                            ),
                          )
                        : _Key(label: k, onTap: () => onKey(k)),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: Key('key-$label'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Palette.stroke),
          ),
          alignment: Alignment.center,
          child: label == '⌫'
              ? const Icon(Icons.backspace_outlined, color: Palette.textDim)
              : Text(label, style: font(24, 700)),
        ),
      ),
    );
  }
}

class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay({
    required this.burst,
    required this.onNext,
    required this.rule,
  });

  final AnimationController burst;
  final VoidCallback onNext;

  /// Правило задачи одной строкой: после ответа видно, почему он верный.
  final String rule;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        builder: (context, v, child) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6 * v, sigmaY: 6 * v),
          child: ColoredBox(
            color: Palette.bgBottom.withValues(alpha: 0.55 * v),
            child: Opacity(opacity: v, child: child),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Glass(
              highlight: true,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: AnimatedBuilder(
                      animation: burst,
                      builder: (context, _) => CustomPaint(
                        painter: _BurstPainter(burst.value),
                        child: Center(
                          child: Transform.scale(
                            scale: Curves.elasticOut
                                .transform(burst.value.clamp(0, 1)),
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: Palette.mintGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: Palette.mint.withValues(alpha: 0.5),
                                    blurRadius: 30,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.check_rounded,
                                  size: 50, color: Palette.bgBottom),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(l.correct, style: font(30, 800)),
                  const SizedBox(height: 10),
                  Text(
                    rule,
                    key: const Key('rule'),
                    textAlign: TextAlign.center,
                    style: font(15, 600, color: Palette.textDim),
                  ),
                  const SizedBox(height: 22),
                  MintButton(
                    key: const Key('next'),
                    label: l.next,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: onNext,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0 || t == 1) return;
    final c = size.center(Offset.zero);
    final colors = [Palette.mint, Palette.blue, Palette.mintLight, Palette.amber];
    for (var i = 0; i < 18; i++) {
      final a = i * 2 * math.pi / 18;
      final d = 30 + 46 * Curves.easeOutCubic.transform(t);
      final p = c + Offset(math.cos(a) * d, math.sin(a) * d);
      canvas.drawCircle(
        p,
        4 * (1 - t) + 1,
        Paint()..color = colors[i % colors.length].withValues(alpha: 1 - t),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

class AllDoneDialog extends StatelessWidget {
  const AllDoneDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Glass(
        highlight: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, size: 56, color: Palette.amber),
            const SizedBox(height: 12),
            Text(l.allDone, style: font(24, 800), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l.allDoneText,
                style: font(15, 500, color: Palette.textDim),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            MintButton(label: l.home, onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}
