import 'package:flutter/material.dart';
import '../../core/services/audio_service.dart';
import '../../core/sudoku_logic.dart';
import '../theme.dart';


/// An interactive, beautifully rendered 9x9 Sudoku grid built with Material 3 styling.
class SudokuGrid extends StatelessWidget {
  final List<List<int>> board;
  final int selectedRow;
  final int selectedCol;
  final List<List<bool>>? isClue;
  final List<List<Set<int>>>? notes;
  final List<List<int>>? solvedBoard;
  final Function(int row, int col) onCellTap;
  final bool highlightConflicts;
  final bool highlightIdentical;
  final bool showMistakes;
  final int flashRow;
  final int flashCol;
  final Map<String, Color>? customCellBgs;
  final Map<String, int>? cellColors;
  final Map<String, int>? candidateColors;
  final int candidateFilter;
  final SudokuVariant variant;
  final List<KillerCage>? killerCages;
  final Map<String, double>? hesitationHeatmap;

  const SudokuGrid({
    super.key,
    required this.board,
    required this.selectedRow,
    required this.selectedCol,
    required this.onCellTap,
    this.isClue,
    this.notes,
    this.solvedBoard,
    this.highlightConflicts = true,
    this.highlightIdentical = true,
    this.showMistakes = true,
    this.flashRow = -1,
    this.flashCol = -1,
    this.customCellBgs,
    this.cellColors,
    this.candidateColors,
    this.candidateFilter = -1,
    this.variant = SudokuVariant.standard,
    this.killerCages,
    this.hesitationHeatmap,
  });

  /// Resolves one of the four palette slots (1-4) to a colour.
  ///
  /// The hues are fixed so a green mark means the same thing to the player
  /// across boards, but the *rendering* is derived from the active theme: in
  /// dark mode the candidate glyphs used the light-mode `shade700` tones,
  /// which sat at very low contrast on the dark cell background. Candidates
  /// now use `ColorScheme.onSurface` at full strength with the hue layered in
  /// as a 3-way blend, which stays legible in either theme.
  static Color _getPaletteColor(
    int index,
    BuildContext context, {
    bool isCandidate = false,
  }) {
    final hue = switch (index) {
      1 => Colors.blue,
      2 => Colors.green,
      3 => Colors.orange,
      4 => Colors.purple,
      _ => Colors.transparent,
    };
    if (hue == Colors.transparent) return Colors.transparent;

    if (isCandidate) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final base = Theme.of(context).colorScheme.onSurface;
      // Dark themes need a lighter mix to clear the dark cell background.
      final blend = isDark ? 0.72 : 0.85;
      return Color.lerp(base, hue, blend)!;
    }
    return hue.withValues(alpha: 0.35);
  }

  @override
  Widget build(BuildContext context) {
    final gridTheme = _GridTheme(context);

    // Pre-index killer cages once per build to avoid 81x firstWhere & reduce scans
    final Map<int, KillerCage> cageMap = {};
    final Map<int, int> cageSumMap = {};
    if (variant == SudokuVariant.killer && killerCages != null) {
      for (final cage in killerCages!) {
        if (cage.cells.isEmpty) continue;
        final firstCell = cage.cells.reduce(
          (a, b) => (a.x < b.x || (a.x == b.x && a.y < b.y)) ? a : b,
        );
        cageSumMap[firstCell.x * 9 + firstCell.y] = cage.targetSum;
        for (final cell in cage.cells) {
          cageMap[cell.x * 9 + cell.y] = cage;
        }
      }
    }

    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gridTheme.outline, width: 2.0),
            color: gridTheme.colorScheme.surface,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(9, (r) {
              return Expanded(
                child: Row(
                  children: List.generate(9, (c) {
                    return Expanded(
                      child: _buildCell(
                        context,
                        r,
                        c,
                        gridTheme,
                        cageMap,
                        cageSumMap,
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    int r,
    int c,
    _GridTheme gridTheme,
    Map<int, KillerCage> cageMap,
    Map<int, int> cageSumMap,
  ) {
    final int value = board[r][c];
    final bool isSelected = r == selectedRow && c == selectedCol;

    // Check relationship with selected cell
    bool isRelated = false;
    if (highlightConflicts &&
        selectedRow != -1 &&
        selectedCol != -1 &&
        !isSelected) {
      bool sameRow = r == selectedRow;
      bool sameCol = c == selectedCol;
      bool sameBox =
          (r ~/ 3 == selectedRow ~/ 3) && (c ~/ 3 == selectedCol ~/ 3);
      bool sameDiagonal = false;
      if (variant == SudokuVariant.diagonalX) {
        bool mainDiag = (selectedRow == selectedCol) && (r == c);
        bool antiDiag = (selectedRow + selectedCol == 8) && (r + c == 8);
        sameDiagonal = mainDiag || antiDiag;
      }
      isRelated = sameRow || sameCol || sameBox || sameDiagonal;
    }

    // Check matching digit
    bool isSameNumber = false;
    if (highlightIdentical &&
        selectedRow != -1 &&
        selectedCol != -1 &&
        !isSelected &&
        value != 0) {
      int selectedValue = board[selectedRow][selectedCol];
      isSameNumber = value == selectedValue;
    }

    // Color palette or Heatmap computation
    Color cellBg = Colors.transparent;
    final bool isFlash = r == flashRow && c == flashCol;
    final cellColorIdx = cellColors != null ? cellColors!['$r,$c'] : null;

    if (hesitationHeatmap != null && hesitationHeatmap!.containsKey('$r,$c')) {
      double score = hesitationHeatmap!['$r,$c']!;
      cellBg = Color.lerp(
        Colors.green.withValues(alpha: 0.35),
        Colors.red.withValues(alpha: 0.65),
        score,
      )!;
    } else if (candidateFilter != -1 && value == candidateFilter) {
      cellBg = gridTheme.colorScheme.primaryContainer.withValues(alpha: 0.65);
    } else if (cellColorIdx != null && cellColorIdx != 0) {
      cellBg = _getPaletteColor(cellColorIdx, context);
    } else if (customCellBgs != null && customCellBgs!.containsKey('$r,$c')) {
      cellBg = customCellBgs!['$r,$c']!;
    } else if (isFlash) {
      cellBg = gridTheme.colorScheme.tertiaryContainer;
    } else if (isSelected) {
      cellBg = gridTheme.selectedCellBg;
    } else if (isSameNumber) {
      cellBg = gridTheme.sameNumberBg;
    } else if (isRelated) {
      cellBg = gridTheme.relatedCellBg;
    } else if (variant == SudokuVariant.diagonalX && (r == c || r + c == 8)) {
      cellBg = gridTheme.colorScheme.secondaryContainer.withValues(
        alpha: 0.18,
      );
    }

    // Killer Cage lookup
    int? cageSumLabel;
    if (variant == SudokuVariant.killer) {
      cageSumLabel = cageSumMap[r * 9 + c];
    }

    // Material 3 Borders
    final outlineColor = gridTheme.outline;
    final outlineVariantColor = gridTheme.outlineVariant;

    // Bottom and Right border drawing
    BorderSide bottomBorder = r == 8
        ? BorderSide.none
        : BorderSide(
            color: (r % 3 == 2) ? outlineColor : outlineVariantColor,
            width: (r % 3 == 2) ? 2.0 : 0.6,
          );
    BorderSide rightBorder = c == 8
        ? BorderSide.none
        : BorderSide(
            color: (c % 3 == 2) ? outlineColor : outlineVariantColor,
            width: (c % 3 == 2) ? 2.0 : 0.6,
          );

    // Number typography
    TextStyle textStyle;
    final bool isStartingClue = isClue != null && isClue![r][c];

    if (value != 0) {
      if (isStartingClue) {
        textStyle = TextStyle(
          color: gridTheme.clueText,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        );
      } else {
        final bool isCorrect =
            solvedBoard == null || solvedBoard![r][c] == value;
        textStyle = TextStyle(
          color: (isCorrect || !showMistakes)
              ? gridTheme.userText
              : gridTheme.errorText,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        );
      }

      if (candidateFilter != -1 && value != candidateFilter) {
        textStyle = textStyle.copyWith(
          color: textStyle.color?.withValues(alpha: 0.15),
        );
      }
    } else {
      textStyle = const TextStyle(color: Colors.transparent);
    }

    return GestureDetector(
      key: Key('cell_${r}_$c'),
      onTap: () {
        AudioService.playCellSelect();
        onCellTap(r, c);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cellBg,
          border: Border(bottom: bottomBorder, right: rightBorder),
        ),
        child: Stack(
          children: [
            if (cageSumLabel != null)
              Positioned(
                top: 2,
                left: 3,
                child: Text(
                  '$cageSumLabel',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: gridTheme.colorScheme.primary,
                  ),
                ),
              ),
            Container(
              alignment: Alignment.center,
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(
                        color: gridTheme.colorScheme.primary,
                        width: 2.0,
                      ),
                    )
                  : null,
              child: value != 0
                  ? Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          '$value',
                          key: ValueKey<int>(value),
                          style: textStyle,
                        ),
                      ),
                    )
                  : _buildNotes(context, r, c, gridTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes(BuildContext context, int r, int c, _GridTheme gridTheme) {
    if (notes == null) return const SizedBox.shrink();
    final cellNotes = notes![r][c];
    if (cellNotes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (gridR) {
          return Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (gridC) {
                int noteNum = gridR * 3 + gridC + 1;
                bool hasNote = cellNotes.contains(noteNum);

                Color noteColor = gridTheme.noteText;
                double fontSize = 9;
                FontWeight weight = FontWeight.bold;

                final candColorIdx = candidateColors != null
                    ? candidateColors!['$r,$c,$noteNum']
                    : null;
                if (candColorIdx != null && candColorIdx != 0) {
                  noteColor = _getPaletteColor(candColorIdx, context, isCandidate: true);
                  fontSize = 10;
                  weight = FontWeight.w900;
                } else if (candidateFilter != -1) {
                  if (noteNum == candidateFilter) {
                    // Same treatment as the colour palette so the highlighted
                    // candidate keeps its contrast in dark mode.
                    noteColor = _getPaletteColor(3, context, isCandidate: true);
                    fontSize = 11;
                    weight = FontWeight.w900;
                  } else {
                    noteColor = noteColor.withValues(alpha: 0.15);
                  }
                }

                return Expanded(
                  child: Center(
                    child: Text(
                      hasNote ? '$noteNum' : '',
                      style: TextStyle(
                        fontSize: fontSize,
                        color: noteColor,
                        fontWeight: weight,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

class _GridTheme {
  final ColorScheme colorScheme;
  final Color outline;
  final Color outlineVariant;
  final Color selectedCellBg;
  final Color sameNumberBg;
  final Color relatedCellBg;
  final Color clueText;
  final Color userText;
  final Color noteText;
  final Color errorText;

  _GridTheme(BuildContext context)
    : colorScheme = Theme.of(context).colorScheme,
      outline = Theme.of(context).colorScheme.outline,
      outlineVariant = Theme.of(context).colorScheme.outlineVariant,
      selectedCellBg = AppTheme.selectedCellBg(context),
      sameNumberBg = AppTheme.sameNumberBg(context),
      relatedCellBg = AppTheme.relatedCellBg(context),
      clueText = AppTheme.clueText(context),
      userText = AppTheme.userText(context),
      noteText = AppTheme.noteText(context),
      errorText = AppTheme.errorText(context);
}

