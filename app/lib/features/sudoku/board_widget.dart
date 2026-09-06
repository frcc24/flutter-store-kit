import 'package:flutter/material.dart';

import 'engine.dart';
import 'game_session.dart';

/// The 9x9 grid. Pure presentation: everything it shows comes in as
/// parameters and every tap goes out through [onTap].
class BoardWidget extends StatelessWidget {
  const BoardWidget({
    super.key,
    required this.session,
    required this.selected,
    required this.conflicts,
    required this.onTap,
  });

  final GameSession session;
  final (int, int)? selected;
  final Set<(int, int)> conflicts;
  final void Function(int row, int col) onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.onSurface, width: 2),
        ),
        child: Column(
          children: [
            for (var r = 0; r < SudokuEngine.size; r++)
              Expanded(
                child: Row(
                  children: [
                    for (var c = 0; c < SudokuEngine.size; c++)
                      Expanded(child: _cell(r, c, scheme)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(int r, int c, ColorScheme scheme) {
    final value = session.grid[r][c];
    final given = session.isGiven(r, c);
    final isSelected = selected == (r, c);
    final isConflict = conflicts.contains((r, c));
    final thin = BorderSide(color: scheme.onSurface.withValues(alpha: 0.25));
    final thick = BorderSide(color: scheme.onSurface, width: 2);
    const last = SudokuEngine.size - 1;
    const boxEdge = SudokuEngine.box - 1;
    return GestureDetector(
      key: Key('cell-$r-$c'),
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(r, c),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isConflict
              ? scheme.error.withValues(alpha: 0.35)
              : isSelected
              ? scheme.primary.withValues(alpha: 0.35)
              : null,
          border: Border(
            right: c % SudokuEngine.box == boxEdge && c != last ? thick : thin,
            bottom: r % SudokuEngine.box == boxEdge && r != last ? thick : thin,
          ),
        ),
        child: Center(
          child: Text(
            value == 0 ? '' : '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: given ? FontWeight.w700 : FontWeight.w400,
              color: given ? scheme.onSurface : scheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
