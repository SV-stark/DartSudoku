import 'package:flutter/material.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    final outlineColor = Theme.of(context).colorScheme.outline;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: outlineColor, width: 2.0),
          color: Theme.of(context).colorScheme.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: List.generate(9, (r) {
            return Expanded(
              child: Row(
                children: List.generate(9, (c) {
                  return Expanded(child: _buildCell(context, r, c));
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, int r, int c) {
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
    if (customCellBgs != null && customCellBgs!.containsKey('$r,$c')) {
      cellBg = customCellBgs!['$r,$c']!;
    } else if (isFlash) {
      cellBg = Theme.of(context).colorScheme.tertiaryContainer;
    } else if (isSelected) {
      cellBg = AppTheme.selectedCellBg(context);
    } else if (isSameNumber) {
      cellBg = AppTheme.sameNumberBg(context);
    } else if (isRelated) {
      cellBg = AppTheme.relatedCellBg(context);
    }

    // Material 3 Borders
    final outlineColor = Theme.of(context).colorScheme.outline;
    final outlineVariantColor = Theme.of(context).colorScheme.outlineVariant;

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
          color: AppTheme.clueText(context),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        );
      } else {
        final bool isCorrect =
            solvedBoard == null || solvedBoard![r][c] == value;
        textStyle = TextStyle(
          color: (isCorrect || !showMistakes)
              ? AppTheme.userText(context)
              : AppTheme.errorText(context),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        );
      }
    } else {
      textStyle = const TextStyle(color: Colors.transparent);
    }

    return GestureDetector(
      onTap: () => onCellTap(r, c),
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
                    color: Theme.of(context).colorScheme.primary,
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
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Text(
                      '$value',
                      key: ValueKey<int>(value),
                      style: textStyle,
                    ),
                  ),
                )
              : _buildNotes(context, r, c),
        ),
      ),
    );
  }

  Widget _buildNotes(BuildContext context, int r, int c) {
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
                return Expanded(
                  child: Center(
                    child: Text(
                      hasNote ? '$noteNum' : '',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.noteText(context),
                        fontWeight: FontWeight.bold,
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
