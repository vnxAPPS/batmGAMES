import 'package:flutter/material.dart';

import '../l10n.dart';
import '../progress_scope.dart';
import '../puzzles/levels.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'levels_screen.dart';
import 'puzzle_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _play(BuildContext context) {
    final progress = ProgressScope.of(context);
    if (progress.allSolved) {
      showDialog<void>(context: context, builder: (_) => const AllDoneDialog());
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PuzzleScreen(level: progress.firstUnsolved),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final progress = ProgressScope.of(context);
    final solved = progress.solvedCount;
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: LayoutBuilder(builder: (context, c) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: RoundIconButton(
                          icon: Icons.info_outline_rounded,
                          tooltip: l.about,
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => const _AboutDialog(),
                          ),
                        ),
                      ),
                      SizedBox(height: c.maxHeight * 0.06),
                      const LogoMark(size: 96),
                      const SizedBox(height: 28),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: 'vnx',
                              style: font(46, 500, color: Palette.textDim)),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: ShaderMask(
                              shaderCallback: (r) =>
                                  Palette.mintGradient.createShader(r),
                              child: Text('MIND',
                                  style: font(46, 800, color: Colors.white)),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 6),
                      Text(l.tagline, style: font(20, 700)),
                      const SizedBox(height: 10),
                      Text(
                        l.subtitle,
                        textAlign: TextAlign.center,
                        style: font(15, 500, color: Palette.textDim),
                      ),
                      SizedBox(height: c.maxHeight * 0.06),
                      Glass(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.solvedOf(solved, levels.length),
                                style: font(16, 700)),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(end: solved / levels.length),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                builder: (context, v, _) => Stack(
                                  children: [
                                    Container(height: 10, color: Palette.surface),
                                    FractionallySizedBox(
                                      widthFactor: v,
                                      child: Container(
                                        height: 10,
                                        decoration: const BoxDecoration(
                                            gradient: Palette.mintGradient),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      MintButton(
                        key: const Key('play'),
                        label: solved == 0 ? l.play : l.continueGame,
                        icon: Icons.play_arrow_rounded,
                        onPressed: () => _play(context),
                      ),
                      const SizedBox(height: 12),
                      GhostButton(
                        key: const Key('levels'),
                        label: l.levels,
                        icon: Icons.grid_view_rounded,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const LevelsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Glass(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.about, style: font(22, 800)),
            const SizedBox(height: 10),
            Text(l.aboutText, style: font(15, 500, color: Palette.textDim)),
            const SizedBox(height: 20),
            GhostButton(
              label: l.resetProgress,
              icon: Icons.restart_alt_rounded,
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Palette.bgTop,
                    title: Text(l.resetProgress, style: font(20, 800)),
                    content: Text(l.resetConfirm,
                        style: font(15, 500, color: Palette.textDim)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(l.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(l.reset,
                            style: const TextStyle(color: Palette.error)),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await ProgressScope.of(context).reset();
                }
              },
            ),
            const SizedBox(height: 10),
            MintButton(
              label: l.close,
              height: 54,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
