import 'package:flutter/material.dart';
import '../../core/services/audio_service.dart';
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
  final int candidateFilter;

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
    this.candidateFilter = -1,
  });

  @override
  Widget build(BuildContext context) {
    final gridTheme = _GridTheme(context);

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
                      child: RepaintBoundary(
                        child: _buildCell(context, r, c, gridTheme),
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

  Widget _buildCell(BuildContext context, int r, int c, _GridTheme gridTheme) {
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
      isRelated = sameRow || sameCol || sameBox;
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

    // Colors mapping from M3 Theme
    Color cellBg = Colors.transparent;
    final bool isFlash = r == flashRow && c == flashCol;
    if (candidateFilter != -1 && value == candidateFilter) {
      cellBg = gridTheme.colorScheme.primaryContainer.withValues(alpha: 0.65);
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

    // Build accessibility semantics label
    final List<String> semanticsParts = [
      'Row ${r + 1} Column ${c + 1}',
      value != 0 ? 'Value $value' : 'Empty',
      isStartingClue ? 'clue' : 'input',
    ];
    if (isSelected) {
      semanticsParts.add('selected');
    } else if (isRelated) {
      semanticsParts.add('related');
    }
    if (value == 0 && notes != null && notes![r][c].isNotEmpty) {
      semanticsParts.add('notes ${notes![r][c].join(', ')}');
    }
    final semanticsLabel = semanticsParts.join(', ');

    return Semantics(
      label: semanticsLabel,
      button: true,
      selected: isSelected,
      child: GestureDetector(
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
          child: Container(
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

                if (candidateFilter != -1) {
                  if (noteNum == candidateFilter) {
                    noteColor = Colors.orange.shade800;
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
