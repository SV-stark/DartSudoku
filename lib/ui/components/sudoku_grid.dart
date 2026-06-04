import 'package:flutter/material.dart';
import '../theme.dart';

/// An interactive, beautifully rendered 9x9 Sudoku grid.
class SudokuGrid extends StatelessWidget {
  final List<List<int>> board;
  final int selectedRow;
  final int selectedCol;
  final List<List<bool>>? isClue;
  final List<List<Set<int>>>? notes;
  final List<List<int>>? solvedBoard;
  final Function(int row, int col) onCellTap;

  const SudokuGrid({
    super.key,
    required this.board,
    required this.selectedRow,
    required this.selectedCol,
    required this.onCellTap,
    this.isClue,
    this.notes,
    this.solvedBoard,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.neonIndigo.withOpacity(0.8),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonIndigo.withOpacity(0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
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

    // Check if cell shares row, col, or 3x3 box with the selected cell
    bool isRelated = false;
    if (selectedRow != -1 && selectedCol != -1 && !isSelected) {
      bool sameRow = r == selectedRow;
      bool sameCol = c == selectedCol;
      bool sameBox =
          (r ~/ 3 == selectedRow ~/ 3) && (c ~/ 3 == selectedCol ~/ 3);
      isRelated = sameRow || sameCol || sameBox;
    }

    // Check if cell contains the same non-zero number as the selected cell
    bool isSameNumber = false;
    if (selectedRow != -1 && selectedCol != -1 && !isSelected && value != 0) {
      int selectedValue = board[selectedRow][selectedCol];
      isSameNumber = value == selectedValue;
    }

    // Determine background color
    Color cellBg = Colors.transparent;
    if (isSelected) {
      cellBg = AppTheme.selectedCellBg;
    } else if (isSameNumber) {
      cellBg = AppTheme.sameNumberBg;
    } else if (isRelated) {
      cellBg = AppTheme.relatedCellBg;
    }

    // Determine borders to avoid doubling line thickness
    BorderSide topBorder = BorderSide(
      color: (r % 3 == 0 && r != 0)
          ? AppTheme.neonIndigo
          : AppTheme.neonIndigo.withOpacity(0.2),
      width: (r % 3 == 0 && r != 0) ? 2.2 : 0.8,
    );
    BorderSide leftBorder = BorderSide(
      color: (c % 3 == 0 && c != 0)
          ? AppTheme.neonIndigo
          : AppTheme.neonIndigo.withOpacity(0.2),
      width: (c % 3 == 0 && c != 0) ? 2.2 : 0.8,
    );

    // Determine text style
    TextStyle textStyle;
    final bool isStartingClue = isClue != null && isClue![r][c];

    if (value != 0) {
      if (isStartingClue) {
        textStyle = const TextStyle(
          color: AppTheme.clueText,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        );
      } else {
        // User entered number
        final bool isCorrect =
            solvedBoard == null || solvedBoard![r][c] == value;
        textStyle = TextStyle(
          color: isCorrect ? AppTheme.userText : AppTheme.neonRed,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          shadows: !isCorrect
              ? [const Shadow(color: AppTheme.neonRed, blurRadius: 8)]
              : null,
        );
      }
    } else {
      textStyle = const TextStyle(color: Colors.transparent);
    }

    return GestureDetector(
      onTap: () => onCellTap(r, c),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: cellBg,
          border: Border(
            top: r == 0 ? BorderSide.none : topBorder,
            left: c == 0 ? BorderSide.none : leftBorder,
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: AppTheme.neonCyan, width: 2)
                : null,
          ),
          child: value != 0
              ? Center(child: Text('$value', style: textStyle))
              : _buildNotes(r, c),
        ),
      ),
    );
  }

  Widget _buildNotes(int r, int c) {
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
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.noteText,
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
