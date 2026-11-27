import 'package:flutter/material.dart';

import '../l10n.dart';
import '../progress_scope.dart';
import '../puzzles/levels.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'puzzle_screen.dart';

class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final progress = ProgressScope.of(context);
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(l.levels,
                          textAlign: TextAlign.center, style: font(20, 800)),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 8),
                Text(l.solvedOf(progress.solvedCount, levels.length),
                    style: font(14, 600, color: Palette.textDim)),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 76,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: levels.length,
                    itemBuilder: (context, i) => _LevelTile(index: i),
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

class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final l = L10n.of(context);
    final solved = progress.isSolved(index);
    final unlocked = progress.isUnlocked(index);
    final current = unlocked && !solved;
    final clean = solved && !progress.usedHint(index);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (!unlocked) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l.locked)));
            return;
          }
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => PuzzleScreen(level: index),
          ));
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: clean ? Palette.mintGradient : null,
            color: clean
                ? null
                : unlocked
                ? Palette.surfaceStrong
                : Colors.white.withValues(alpha: 0.03),
            border: Border.all(
              color: current || (solved && !clean)
                  ? Palette.mint
                  : Palette.stroke,
              width: current ? 1.8 : 1,
            ),
            boxShadow: [
              if (current)
                BoxShadow(
                  color: Palette.mint.withValues(alpha: 0.35),
                  blurRadius: 14,
                ),
            ],
          ),
          alignment: Alignment.center,
          child: unlocked
              ? Text(
                  '${index + 1}',
                  style: font(20, 800,
                      color: clean ? Palette.bgBottom : Palette.text),
                )
              : Icon(Icons.lock_rounded,
                  size: 20, color: Palette.textDim.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}
