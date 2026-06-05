import 'package:flutter/material.dart';

List<List<int>> emptyBoard() => List.generate(9, (_) => List.filled(9, 0));

List<List<int>> boardWith(Map<String, int> values) {
  final b = emptyBoard();
  values.forEach((key, val) {
    final parts = key.split(',');
    b[int.parse(parts[0])][int.parse(parts[1])] = val;
  });
  return b;
}

class LessonData {
  final String title;
  final List<SlideData> slides;

  LessonData({required this.title, required this.slides});
}

class SlideData {
  final String text;
  final List<List<int>> board;
  final int highlightedRow;
  final int highlightedCol;
  final Map<String, Set<int>> notes;
  final int? expectedValue;
  final String? interactiveHelp;
  final Map<String, Color> Function(BuildContext)? customHighlights;

  SlideData({
    required this.text,
    required this.board,
    required this.highlightedRow,
    required this.highlightedCol,
    required this.notes,
    this.expectedValue,
    this.interactiveHelp,
    this.customHighlights,
  });
}

class SudokuLessonsData {
  static List<LessonData> getLessons(BuildContext context) {
    final theme = Theme.of(context);
    final boxColor = theme.colorScheme.secondaryContainer.withValues(
      alpha: 0.25,
    );
    final targetColor = theme.colorScheme.primaryContainer.withValues(
      alpha: 0.65,
    );
    final helperColor = theme.colorScheme.secondaryContainer.withValues(
      alpha: 0.35,
    );
    final alertColor = theme.colorScheme.tertiaryContainer.withValues(
      alpha: 0.35,
    );
    final finColor = theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4);

    return [
      // 1. Basics
      LessonData(
        title: 'Basics: Scanning',
        slides: [
          SlideData(
            text:
                'Sudoku is played on a 9x9 grid. Your goal is to fill the grid so that each row, column, and 3x3 box contains all digits from 1 to 9 without repetition.',
            board: boardWith({
              '0,0': 1,
              '0,1': 2,
              '0,2': 3,
              '1,0': 4,
              '1,1': 5,
              '1,2': 6,
              '2,0': 7,
              '2,1': 8,
            }),
            highlightedRow: 2,
            highlightedCol: 2,
            notes: {},
            customHighlights: (context) {
              final Map<String, Color> map = {};
              for (int r = 0; r < 3; r++) {
                for (int c = 0; c < 3; c++) {
                  map['$r,$c'] = boxColor;
                }
              }
              map['2,2'] = targetColor;
              return map;
            },
          ),
          SlideData(
            text:
                'Look at the highlighted cell (Row 3, Col 3). The top-left 3x3 box already contains the numbers 1 through 8. The only missing number to complete this box is 9! Tap the cell and input 9.',
            board: boardWith({
              '0,0': 1,
              '0,1': 2,
              '0,2': 3,
              '1,0': 4,
              '1,1': 5,
              '1,2': 6,
              '2,0': 7,
              '2,1': 8,
            }),
            highlightedRow: 2,
            highlightedCol: 2,
            notes: {},
            expectedValue: 9,
            interactiveHelp:
                'Look at the top-left 3x3 box. It already contains 1, 2, 3, 4, 5, 6, 7, and 8. The only missing digit is 9!',
            customHighlights: (context) {
              final Map<String, Color> map = {};
              for (int r = 0; r < 3; r++) {
                for (int c = 0; c < 3; c++) {
                  map['$r,$c'] = boxColor;
                }
              }
              map['2,2'] = targetColor;
              return map;
            },
          ),
        ],
      ),

      // 2. Hidden Single (Box)
      LessonData(
        title: 'Hidden Single (Box)',
        slides: [
          SlideData(
            text:
                'A Hidden Single in a box occurs when a candidate appears in only one cell inside that 3x3 box, even if other candidates can go there.',
            board: boardWith({'1,8': 5, '2,8': 5, '8,1': 5, '8,2': 5}),
            highlightedRow: 0,
            highlightedCol: 0,
            notes: {},
            customHighlights: (context) {
              final Map<String, Color> map = {};
              for (int r = 0; r < 3; r++) {
                for (int c = 0; c < 3; c++) {
                  map['$r,$c'] = boxColor;
                }
              }
              map['0,0'] = alertColor;
              return map;
            },
          ),
          SlideData(
            text:
                'The 5s in Row 2, Row 3, Col 2, and Col 3 block all cells in Box 1 except Row 1 Col 1. Therefore, Row 1 Col 1 must be 5! Input 5.',
            board: boardWith({'1,8': 5, '2,8': 5, '8,1': 5, '8,2': 5}),
            highlightedRow: 0,
            highlightedCol: 0,
            notes: {},
            expectedValue: 5,
            interactiveHelp:
                'The existing 5s cross out all other possibilities in Box 1, forcing Row 1 Col 1 to be 5.',
            customHighlights: (context) {
              final Map<String, Color> map = {};
              for (int r = 0; r < 3; r++) {
                for (int c = 0; c < 3; c++) {
                  map['$r,$c'] = boxColor;
                }
              }
              map['0,0'] = targetColor;
              return map;
            },
          ),
        ],
      ),

      // 3. Hidden Single (Line)
      LessonData(
        title: 'Hidden Single (Line)',
        slides: [
          SlideData(
            text:
                'A Hidden Single in a row/column occurs when a candidate is forced into a single cell along that line because it is blocked elsewhere.',
            board: boardWith({'2,0': 7, '5,3': 7, '5,5': 7, '8,8': 7}),
            highlightedRow: 0,
            highlightedCol: 4,
            notes: {},
            customHighlights: (context) {
              final Map<String, Color> map = {};
              for (int c = 0; c < 9; c++) {
                map['0,$c'] = helperColor;
              }
              map['0,4'] = alertColor;
              return map;
            },
          ),
          SlideData(
            text:
                'Looking at Row 1, the 7 in Box 1 blocks Cols 1-3, the 7s in Col 4 & 6 block Col 4 & 6, and the 7 in Box 3 blocks Cols 7-9. Thus, Row 1 Col 5 must be 7! Input 7.',
            board: boardWith({'2,0': 7, '5,3': 7, '5,5': 7, '8,8': 7}),
            highlightedRow: 0,
            highlightedCol: 4,
            notes: {},
            expectedValue: 7,
            interactiveHelp:
                '7 can only be placed at Col 5 in Row 1 because all other columns in Row 1 are blocked by other 7s.',
            customHighlights: (context) {
              final Map<String, Color> map = {};
              for (int c = 0; c < 9; c++) {
                map['0,$c'] = helperColor;
              }
              map['0,4'] = targetColor;
              return map;
            },
          ),
        ],
      ),

      // 4. Hidden Pair
      LessonData(
        title: 'Hidden Pair',
        slides: [
          SlideData(
            text:
                'A Hidden Pair happens when two candidates appear in exactly two cells of a house, and nowhere else. We can eliminate all other candidates from those two cells.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 8,
            notes: {
              '0,0': {3, 8},
              '0,4': {3, 8},
              '0,8': {2, 3, 8},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,4': helperColor,
              '0,8': alertColor,
            },
          ),
          SlideData(
            text:
                'Candidates 3 and 8 form a Hidden Pair in Row 1 Col 1 & 5. This locks 8 in those cells, so 8 is eliminated from Row 1 Col 9. This leaves only 2! Input 2.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 8,
            notes: {
              '0,0': {3, 8},
              '0,4': {3, 8},
            },
            expectedValue: 2,
            interactiveHelp:
                'Since 3 and 8 must be in Col 1 & 5, candidate 8 is eliminated from Col 9, leaving only 2.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,4': helperColor,
              '0,8': targetColor,
            },
          ),
        ],
      ),

      // 5. Hidden Triple
      LessonData(
        title: 'Hidden Triple',
        slides: [
          SlideData(
            text:
                'A Hidden Triple consists of three candidates that appear ONLY in three cells of a house. All other candidates can be deleted from those three cells.',
            board: emptyBoard(),
            highlightedRow: 1,
            highlightedCol: 8,
            notes: {
              '0,0': {1, 5},
              '0,4': {5, 9},
              '0,8': {1, 6, 9},
              '1,8': {7, 9},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,4': helperColor,
              '0,8': helperColor,
              '1,8': alertColor,
            },
          ),
          SlideData(
            text:
                'Candidates {1, 5, 9} are restricted to Col 1, 5, and 9 of Row 1 (Hidden Triple). This eliminates 9 from the rest of Col 9, leaving Row 2 Col 9 as 7! Input 7.',
            board: emptyBoard(),
            highlightedRow: 1,
            highlightedCol: 8,
            notes: {
              '0,0': {1, 5},
              '0,4': {5, 9},
              '0,8': {1, 9},
            },
            expectedValue: 7,
            interactiveHelp:
                'Since 9 is locked in Row 1 Col 9 by the hidden triple, it is eliminated from Row 2 Col 9, leaving only 7.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,4': helperColor,
              '0,8': helperColor,
              '1,8': targetColor,
            },
          ),
        ],
      ),

      // 6. Hidden Quadruple
      LessonData(
        title: 'Hidden Quadruple',
        slides: [
          SlideData(
            text:
                'A Hidden Quadruple occurs when four candidates appear in only four cells of a house. We eliminate all other candidates from those cells.',
            board: emptyBoard(),
            highlightedRow: 1,
            highlightedCol: 7,
            notes: {
              '0,0': {1, 3},
              '0,2': {3, 7},
              '0,5': {7, 8},
              '0,7': {1, 3, 5, 7, 8},
              '1,7': {5, 8},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,2': helperColor,
              '0,5': helperColor,
              '0,7': helperColor,
              '1,7': alertColor,
            },
          ),
          SlideData(
            text:
                'Candidates {1, 3, 7, 8} form a Hidden Quadruple in Row 1. This locks 8 in Row 1 Col 8, eliminating 8 from Row 2 Col 8. Thus, Row 2 Col 8 must be 5! Input 5.',
            board: emptyBoard(),
            highlightedRow: 1,
            highlightedCol: 7,
            notes: {
              '0,0': {1, 3},
              '0,2': {3, 7},
              '0,5': {7, 8},
              '0,7': {1, 3, 7, 8},
            },
            expectedValue: 5,
            interactiveHelp:
                'The hidden quadruple in Row 1 locks candidate 8 in Row 1 Col 8, leaving Row 2 Col 8 as 5.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,2': helperColor,
              '0,5': helperColor,
              '0,7': helperColor,
              '1,7': targetColor,
            },
          ),
        ],
      ),

      // 7. Naked Single
      LessonData(
        title: 'Naked Single',
        slides: [
          SlideData(
            text:
                'A Naked Single is a cell where only one candidate remains because all other numbers (1-9) are eliminated by its row, column, and box.',
            board: boardWith({
              '0,4': 1,
              '1,4': 2,
              '2,4': 3,
              '4,0': 5,
              '4,1': 6,
              '4,2': 7,
              '4,6': 8,
              '4,7': 9,
            }),
            highlightedRow: 4,
            highlightedCol: 4,
            notes: {
              '4,4': {4},
            },
            customHighlights: (context) => {'4,4': alertColor},
          ),
          SlideData(
            text:
                'Row 5 contains 5, 6, 7, 8, 9, and Col 5 contains 1, 2, 3. The only digit that can fit in Row 5 Col 5 is 4! Input 4.',
            board: boardWith({
              '0,4': 1,
              '1,4': 2,
              '2,4': 3,
              '4,0': 5,
              '4,1': 6,
              '4,2': 7,
              '4,6': 8,
              '4,7': 9,
            }),
            highlightedRow: 4,
            highlightedCol: 4,
            notes: {},
            expectedValue: 4,
            interactiveHelp:
                'Check Col 5 (1,2,3) and Row 5 (5,6,7,8,9). 4 is the only number left.',
            customHighlights: (context) => {'4,4': targetColor},
          ),
        ],
      ),

      // 8. Naked Pair
      LessonData(
        title: 'Naked Pair',
        slides: [
          SlideData(
            text:
                'A Naked Pair occurs when two cells in a row, column, or box contain exactly the same two candidates. Those digits are locked in those cells.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 8,
            notes: {
              '0,0': {3, 7},
              '0,4': {3, 7},
              '0,8': {2, 3, 7},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,4': helperColor,
              '0,8': alertColor,
            },
          ),
          SlideData(
            text:
                'In Row 1, Col 1 and Col 5 contain ONLY candidates {3, 7}. Because 3 and 7 must be in these two cells, we can safely eliminate 3 and 7 from the rest of Row 1. Thus, Col 9 must be 2! Tap and input 2.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 8,
            notes: {
              '0,0': {3, 7},
              '0,4': {3, 7},
            },
            expectedValue: 2,
            interactiveHelp:
                'The naked pair of {3, 7} in Col 1 & 5 eliminates 3 and 7 from Row 1 Col 9, leaving 2.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,4': helperColor,
              '0,8': targetColor,
            },
          ),
        ],
      ),

      // 9. Naked Triple
      LessonData(
        title: 'Naked Triple',
        slides: [
          SlideData(
            text:
                'A Naked Triple occurs when three cells in a house contain only subsets of three candidates (e.g. {1,2}, {2,3}, {1,3}). Those digits can be eliminated from other cells in that house.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 8,
            notes: {
              '0,0': {1, 2},
              '0,2': {2, 3},
              '0,4': {1, 3},
              '0,8': {3, 6},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,2': helperColor,
              '0,4': helperColor,
              '0,8': alertColor,
            },
          ),
          SlideData(
            text:
                'The cells in Col 1, 3, and 5 contain only {1, 2, 3}. This eliminates 3 from Col 9, forcing Row 1 Col 9 to be 6! Input 6.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 8,
            notes: {
              '0,0': {1, 2},
              '0,2': {2, 3},
              '0,4': {1, 3},
            },
            expectedValue: 6,
            interactiveHelp:
                'The naked triple of {1, 2, 3} locks those numbers, eliminating 3 from Col 9 and leaving 6.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,2': helperColor,
              '0,4': helperColor,
              '0,8': targetColor,
            },
          ),
        ],
      ),

      // 10. Naked Quadruple
      LessonData(
        title: 'Naked Quadruple',
        slides: [
          SlideData(
            text:
                'A Naked Quadruple consists of four cells in a house containing only subsets of four candidates. These four digits can be deleted from all other cells in that house.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 8,
            notes: {
              '0,0': {1, 2},
              '0,2': {2, 3},
              '0,4': {3, 4},
              '0,6': {1, 4},
              '0,8': {4, 8},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,2': helperColor,
              '0,4': helperColor,
              '0,6': helperColor,
              '0,8': alertColor,
            },
          ),
          SlideData(
            text:
                'Cells Col 1, 3, 5, and 7 contain only subsets of {1, 2, 3, 4}. This eliminates 4 from Row 1 Col 9, leaving only 8! Input 8.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 8,
            notes: {
              '0,0': {1, 2},
              '0,2': {2, 3},
              '0,4': {3, 4},
              '0,6': {1, 4},
            },
            expectedValue: 8,
            interactiveHelp:
                'The naked quadruple {1, 2, 3, 4} eliminates 4 from Col 9, leaving 8 as the only candidate.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,2': helperColor,
              '0,4': helperColor,
              '0,6': helperColor,
              '0,8': targetColor,
            },
          ),
        ],
      ),

      // 11. Locked Candidate (Pointing)
      LessonData(
        title: 'Locked Candidate (Pointing)',
        slides: [
          SlideData(
            text:
                'A Pointing Pair occurs when candidate values in a 3x3 box align strictly in a single row or column. This eliminates that candidate from the rest of that row/column.',
            board: emptyBoard(),
            highlightedRow: 1,
            highlightedCol: 5,
            notes: {
              '1,0': {5},
              '1,1': {5},
              '1,5': {4, 5},
            },
            customHighlights: (context) => {
              '1,0': helperColor,
              '1,1': helperColor,
              '1,5': alertColor,
            },
          ),
          SlideData(
            text:
                'In Box 1, candidate 5 only appears in Row 2. This pointing pair eliminates 5 from Row 2 Col 6, leaving only candidate 4! Input 4.',
            board: emptyBoard(),
            highlightedRow: 1,
            highlightedCol: 5,
            notes: {
              '1,0': {5},
              '1,1': {5},
            },
            expectedValue: 4,
            interactiveHelp:
                'Since 5 must be in Box 1 Row 2, it cannot be in Col 6 Row 2, leaving only 4.',
            customHighlights: (context) => {
              '1,0': helperColor,
              '1,1': helperColor,
              '1,5': targetColor,
            },
          ),
        ],
      ),

      // 12. Locked Candidate (Claiming)
      LessonData(
        title: 'Locked Candidate (Claiming)',
        slides: [
          SlideData(
            text:
                'Claiming occurs when a candidate in a row or column is locked entirely inside a single 3x3 box. This eliminates that candidate from the rest of that box.',
            board: emptyBoard(),
            highlightedRow: 1,
            highlightedCol: 0,
            notes: {
              '0,0': {9},
              '0,1': {9},
              '1,0': {9, 3},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,1': helperColor,
              '1,0': alertColor,
            },
          ),
          SlideData(
            text:
                'In Row 1, candidate 9 is restricted to Box 1. This "claims" 9 for Row 1, eliminating 9 from the rest of Box 1 (including Row 2 Col 1). Row 2 Col 1 must be 3! Input 3.',
            board: emptyBoard(),
            highlightedRow: 1,
            highlightedCol: 0,
            notes: {
              '0,0': {9},
              '0,1': {9},
            },
            expectedValue: 3,
            interactiveHelp:
                'Since 9 is claimed by Row 1 inside Box 1, it is eliminated from Row 2 Col 1, leaving 3.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,1': helperColor,
              '1,0': targetColor,
            },
          ),
        ],
      ),

      // 13. X-Wing
      LessonData(
        title: 'X-Wing',
        slides: [
          SlideData(
            text:
                'An X-Wing is formed when a candidate is restricted to exactly two cells in two parallel rows (forming a rectangle). It locks that digit in diagonally.',
            board: emptyBoard(),
            highlightedRow: 3,
            highlightedCol: 1,
            notes: {
              '1,1': {4},
              '1,6': {4},
              '5,1': {4},
              '5,6': {4},
              '3,1': {4, 9},
            },
            customHighlights: (context) => {
              '1,1': helperColor,
              '1,6': helperColor,
              '5,1': helperColor,
              '5,6': helperColor,
              '3,1': alertColor,
            },
          ),
          SlideData(
            text:
                'Rows 2 and 6 only contain candidate 4 in Cols 2 and 7. This locks the 4s in diagonally, eliminating 4 from Row 4 Col 2. Thus, Row 4 Col 2 must be 9! Input 9.',
            board: emptyBoard(),
            highlightedRow: 3,
            highlightedCol: 1,
            notes: {
              '1,1': {4},
              '1,6': {4},
              '5,1': {4},
              '5,6': {4},
            },
            expectedValue: 9,
            interactiveHelp:
                'The X-Wing pattern locks 4s into Col 2 and Col 7, eliminating 4 from Row 4 Col 2 and leaving 9.',
            customHighlights: (context) => {
              '1,1': helperColor,
              '1,6': helperColor,
              '5,1': helperColor,
              '5,6': helperColor,
              '3,1': targetColor,
            },
          ),
        ],
      ),

      // 14. Swordfish
      LessonData(
        title: 'Swordfish',
        slides: [
          SlideData(
            text:
                'A Swordfish occurs when a candidate is restricted to the same three columns in exactly three rows. It eliminates that candidate from those columns in all other rows.',
            board: emptyBoard(),
            highlightedRow: 4,
            highlightedCol: 1,
            notes: {
              '0,1': {6},
              '0,4': {6},
              '2,4': {6},
              '2,7': {6},
              '6,1': {6},
              '6,7': {6},
              '4,1': {6, 8},
            },
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,4': helperColor,
              '2,4': helperColor,
              '2,7': helperColor,
              '6,1': helperColor,
              '6,7': helperColor,
              '4,1': alertColor,
            },
          ),
          SlideData(
            text:
                'A Swordfish of 6s in Rows 1, 3, and 7 (locked in Cols 2, 5, 8) eliminates 6 from Row 5 Col 2, leaving only 8! Input 8.',
            board: emptyBoard(),
            highlightedRow: 4,
            highlightedCol: 1,
            notes: {
              '0,1': {6},
              '0,4': {6},
              '2,4': {6},
              '2,7': {6},
              '6,1': {6},
              '6,7': {6},
            },
            expectedValue: 8,
            interactiveHelp:
                'The Swordfish pattern locks all 6s in columns 2, 5, and 8, eliminating 6 from Row 5 Col 2.',
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,4': helperColor,
              '2,4': helperColor,
              '2,7': helperColor,
              '6,1': helperColor,
              '6,7': helperColor,
              '4,1': targetColor,
            },
          ),
        ],
      ),

      // 15. Jellyfish
      LessonData(
        title: 'Jellyfish',
        slides: [
          SlideData(
            text:
                'A Jellyfish occurs when a candidate is restricted to the same four columns in exactly four rows. It eliminates that candidate from those columns in all other rows.',
            board: emptyBoard(),
            highlightedRow: 8,
            highlightedCol: 1,
            notes: {
              '0,1': {1},
              '0,3': {1},
              '2,3': {1},
              '2,5': {1},
              '4,5': {1},
              '4,7': {1},
              '6,1': {1},
              '6,7': {1},
              '8,1': {1, 5},
            },
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,3': helperColor,
              '2,3': helperColor,
              '2,5': helperColor,
              '4,5': helperColor,
              '4,7': helperColor,
              '6,1': helperColor,
              '6,7': helperColor,
              '8,1': alertColor,
            },
          ),
          SlideData(
            text:
                'A Jellyfish of 1s in Rows 1, 3, 5, and 7 eliminates 1 from Row 9 Col 2. Thus, Row 9 Col 2 must be 5! Input 5.',
            board: emptyBoard(),
            highlightedRow: 8,
            highlightedCol: 1,
            notes: {
              '0,1': {1},
              '0,3': {1},
              '2,3': {1},
              '2,5': {1},
              '4,5': {1},
              '4,7': {1},
              '6,1': {1},
              '6,7': {1},
            },
            expectedValue: 5,
            interactiveHelp:
                'The Jellyfish pattern locks all 1s in columns 2, 4, 6, and 8, eliminating 1 from Row 9 Col 2.',
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,3': helperColor,
              '2,3': helperColor,
              '2,5': helperColor,
              '4,5': helperColor,
              '4,7': helperColor,
              '6,1': helperColor,
              '6,7': helperColor,
              '8,1': targetColor,
            },
          ),
        ],
      ),

      // 16. Finned/Sashimi X-Wing
      LessonData(
        title: 'Finned/Sashimi X-Wing',
        slides: [
          SlideData(
            text:
                'A Finned X-Wing has an extra candidate (a "fin") inside one of the corners\' boxes. We can eliminate candidates seen by both the fin and the X-Wing.',
            board: emptyBoard(),
            highlightedRow: 3,
            highlightedCol: 1,
            notes: {
              '0,1': {8},
              '0,6': {8},
              '4,1': {8},
              '4,6': {8},
              '4,2': {8},
              '3,1': {8, 7},
            },
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,6': helperColor,
              '4,1': helperColor,
              '4,6': helperColor,
              '4,2': finColor,
              '3,1': targetColor,
            },
          ),
          SlideData(
            text:
                'Whether the fin (Row 5 Col 3) is true or the X-Wing (Rows 1 & 5) is true, candidate 8 in Row 4 Col 2 is always eliminated. Input 7.',
            board: emptyBoard(),
            highlightedRow: 3,
            highlightedCol: 1,
            notes: {
              '0,1': {8},
              '0,6': {8},
              '4,1': {8},
              '4,6': {8},
              '4,2': {8},
            },
            expectedValue: 7,
            interactiveHelp:
                'Eliminate 8 from Row 4 Col 2 as it sees both the fin and the column 2 X-Wing line.',
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,6': helperColor,
              '4,1': helperColor,
              '4,6': helperColor,
              '4,2': finColor,
              '3,1': targetColor,
            },
          ),
        ],
      ),

      // 17. Finned/Sashimi Swordfish
      LessonData(
        title: 'Finned/Sashimi Swordfish',
        slides: [
          SlideData(
            text:
                'A Finned Swordfish is a Swordfish pattern with an extra candidate ("fin") in one of the intersection boxes.',
            board: emptyBoard(),
            highlightedRow: 7,
            highlightedCol: 1,
            notes: {
              '0,1': {3},
              '0,4': {3},
              '2,4': {3},
              '2,7': {3},
              '6,1': {3},
              '6,7': {3},
              '6,2': {3},
              '7,1': {3, 5},
            },
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,4': helperColor,
              '2,4': helperColor,
              '2,7': helperColor,
              '6,1': helperColor,
              '6,7': helperColor,
              '6,2': finColor,
              '7,1': targetColor,
            },
          ),
          SlideData(
            text:
                'The fin at Row 7 Col 3 and the Swordfish structure intersect at Row 8 Col 2, eliminating 3 and leaving only 5! Input 5.',
            board: emptyBoard(),
            highlightedRow: 7,
            highlightedCol: 1,
            notes: {
              '0,1': {3},
              '0,4': {3},
              '2,4': {3},
              '2,7': {3},
              '6,1': {3},
              '6,7': {3},
              '6,2': {3},
            },
            expectedValue: 5,
            interactiveHelp:
                'Row 8 Col 2 sees both the fin in Box 7 and Column 2 of the Swordfish, eliminating 3.',
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,4': helperColor,
              '2,4': helperColor,
              '2,7': helperColor,
              '6,1': helperColor,
              '6,7': helperColor,
              '6,2': finColor,
              '7,1': targetColor,
            },
          ),
        ],
      ),

      // 18. Finned/Sashimi Jellyfish
      LessonData(
        title: 'Finned/Sashimi Jellyfish',
        slides: [
          SlideData(
            text:
                'A Finned Jellyfish is a Jellyfish pattern (four rows, four columns) with an extra candidate fin.',
            board: emptyBoard(),
            highlightedRow: 7,
            highlightedCol: 1,
            notes: {
              '0,1': {7},
              '0,3': {7},
              '2,3': {7},
              '2,5': {7},
              '4,5': {7},
              '4,7': {7},
              '6,1': {7},
              '6,7': {7},
              '6,2': {7},
              '7,1': {7, 9},
            },
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,3': helperColor,
              '2,3': helperColor,
              '2,5': helperColor,
              '4,5': helperColor,
              '4,7': helperColor,
              '6,1': helperColor,
              '6,7': helperColor,
              '6,2': finColor,
              '7,1': targetColor,
            },
          ),
          SlideData(
            text:
                'The fin at Row 7 Col 3 eliminates 7 from Row 8 Col 2. Thus, Row 8 Col 2 must be 9! Input 9.',
            board: emptyBoard(),
            highlightedRow: 7,
            highlightedCol: 1,
            notes: {
              '0,1': {7},
              '0,3': {7},
              '2,3': {7},
              '2,5': {7},
              '4,5': {7},
              '4,7': {7},
              '6,1': {7},
              '6,7': {7},
              '6,2': {7},
            },
            expectedValue: 9,
            interactiveHelp:
                'Row 8 Col 2 sees both the fin and the Jellyfish Col 2, eliminating candidate 7.',
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,3': helperColor,
              '2,3': helperColor,
              '2,5': helperColor,
              '4,5': helperColor,
              '4,7': helperColor,
              '6,1': helperColor,
              '6,7': helperColor,
              '6,2': finColor,
              '7,1': targetColor,
            },
          ),
        ],
      ),

      // 19. Skyscraper
      LessonData(
        title: 'Skyscraper',
        slides: [
          SlideData(
            text:
                'A Skyscraper pattern forms when a candidate is restricted to two cells in two columns, aligning in one row but offset in the other. It eliminates that candidate from cells seeing both offset tops.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 1,
            notes: {
              '1,1': {9},
              '1,5': {9},
              '6,1': {9},
              '5,5': {9},
              '5,1': {9, 3},
            },
            customHighlights: (context) => {
              '1,1': helperColor,
              '1,5': helperColor,
              '6,1': helperColor,
              '5,5': helperColor,
              '5,1': alertColor,
            },
          ),
          SlideData(
            text:
                'The tops of the skyscrapers at Row 7 Col 2 and Row 6 Col 6 eliminate 9 from Row 6 Col 2 (which sees both). Therefore, Row 6 Col 2 must be 3! Input 3.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 1,
            notes: {
              '1,1': {9},
              '1,5': {9},
              '6,1': {9},
              '5,5': {9},
            },
            expectedValue: 3,
            interactiveHelp:
                'Since 9 is locked in the tops of the skyscraper columns, it is eliminated from Row 6 Col 2.',
            customHighlights: (context) => {
              '1,1': helperColor,
              '1,5': helperColor,
              '6,1': helperColor,
              '5,5': helperColor,
              '5,1': targetColor,
            },
          ),
        ],
      ),

      // 20. Two-String-Kite
      LessonData(
        title: 'Two-String-Kite',
        slides: [
          SlideData(
            text:
                'A Two-String-Kite connects a row and column containing exactly two of a candidate, which share a box. It eliminates that candidate from the intersection of their strings.',
            board: emptyBoard(),
            highlightedRow: 8,
            highlightedCol: 7,
            notes: {
              '0,1': {4},
              '0,7': {4},
              '8,1': {4},
              '8,7': {4, 2},
            },
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,7': helperColor,
              '8,1': helperColor,
              '8,7': alertColor,
            },
          ),
          SlideData(
            text:
                'The strings at Row 1 Col 8 and Row 9 Col 2 eliminate 4 from their intersection at Row 9 Col 8. Thus, Row 9 Col 8 must be 2! Input 2.',
            board: emptyBoard(),
            highlightedRow: 8,
            highlightedCol: 7,
            notes: {
              '0,1': {4},
              '0,7': {4},
              '8,1': {4},
            },
            expectedValue: 2,
            interactiveHelp:
                'Since 4 must be in either Row 1 Col 8 or Row 9 Col 2, it is eliminated from Row 9 Col 8.',
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,7': helperColor,
              '8,1': helperColor,
              '8,7': targetColor,
            },
          ),
        ],
      ),

      // 21. Crane
      LessonData(
        title: 'Crane (Turbot Fish)',
        slides: [
          SlideData(
            text:
                'A Crane is a 3-link conjugate chain of a single candidate that alternates strong and weak links. It eliminates that candidate from cells seeing both endpoints.',
            board: emptyBoard(),
            highlightedRow: 2,
            highlightedCol: 0,
            notes: {
              '0,0': {3},
              '0,5': {3},
              '7,5': {3},
              '7,0': {3},
              '2,0': {3, 5},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,5': helperColor,
              '7,5': helperColor,
              '7,0': helperColor,
              '2,0': alertColor,
            },
          ),
          SlideData(
            text:
                'The Crane chain links Row 1 Col 1 to Row 8 Col 1. Both endpoints see Row 3 Col 1, eliminating 3 and leaving only 5! Input 5.',
            board: emptyBoard(),
            highlightedRow: 2,
            highlightedCol: 0,
            notes: {
              '0,0': {3},
              '0,5': {3},
              '7,5': {3},
              '7,0': {3},
            },
            expectedValue: 5,
            interactiveHelp:
                'Since 3 must be in either Row 1 Col 1 or Row 8 Col 1, Row 3 Col 1 cannot contain 3.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,5': helperColor,
              '7,5': helperColor,
              '7,0': helperColor,
              '2,0': targetColor,
            },
          ),
        ],
      ),

      // 22. Empty Rectangle
      LessonData(
        title: 'Empty Rectangle',
        slides: [
          SlideData(
            text:
                'An Empty Rectangle uses a candidate\'s box shape to eliminate that candidate from an intersection cell aligned with a strong link.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 7,
            notes: {
              '0,0': {8},
              '0,1': {8},
              '1,0': {8},
              '5,1': {8},
              '5,7': {8},
              '0,7': {8, 1},
            },
            customHighlights: (context) => {
              '0,0': boxColor,
              '0,1': boxColor,
              '1,0': boxColor,
              '5,1': alertColor,
              '5,7': alertColor,
              '0,7': targetColor,
            },
          ),
          SlideData(
            text:
                'The strong link of 8s in Row 6 connects to Box 1, eliminating 8 from Row 1 Col 8. Thus, Row 1 Col 8 must be 1! Input 1.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 7,
            notes: {
              '0,0': {8},
              '0,1': {8},
              '1,0': {8},
              '5,1': {8},
              '5,7': {8},
            },
            expectedValue: 1,
            interactiveHelp:
                'The empty rectangle intersection in Box 1 blocks 8 from Col 8 at Row 1.',
            customHighlights: (context) => {
              '0,0': boxColor,
              '0,1': boxColor,
              '1,0': boxColor,
              '5,1': alertColor,
              '5,7': alertColor,
              '0,7': targetColor,
            },
          ),
        ],
      ),

      // 23. Y-Wing
      LessonData(
        title: 'Y-Wing',
        slides: [
          SlideData(
            text:
                'A Y-Wing uses three bi-value cells: a pivot {A,B} and two pincers {A,C} and {B,C}. This eliminates candidate C from cells seeing both pincers.',
            board: emptyBoard(),
            highlightedRow: 4,
            highlightedCol: 7,
            notes: {
              '1,1': {5, 9},
              '1,7': {2, 5},
              '4,1': {2, 9},
              '4,7': {2, 6},
            },
            customHighlights: (context) => {
              '1,1': helperColor,
              '1,7': alertColor,
              '4,1': alertColor,
              '4,7': targetColor,
            },
          ),
          SlideData(
            text:
                'Pivot {5,9} links pincers {2,5} & {2,9}. In either case, candidate 2 is eliminated from Row 5 Col 8 (which sees both pincers). Thus, Row 5 Col 8 must be 6! Input 6.',
            board: emptyBoard(),
            highlightedRow: 4,
            highlightedCol: 7,
            notes: {
              '1,1': {5, 9},
              '1,7': {2, 5},
              '4,1': {2, 9},
            },
            expectedValue: 6,
            interactiveHelp:
                'Since 2 must be in either Row 2 Col 8 or Row 5 Col 2, candidate 2 is eliminated from Row 5 Col 8.',
            customHighlights: (context) => {
              '1,1': helperColor,
              '1,7': alertColor,
              '4,1': alertColor,
              '4,7': targetColor,
            },
          ),
        ],
      ),

      // 24. XYZ-Wing
      LessonData(
        title: 'XYZ-Wing',
        slides: [
          SlideData(
            text:
                'An XYZ-Wing has a pivot with three candidates {A,B,C} and two pincers with {A,C} and {B,C}. This eliminates candidate C from cells seeing all three.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 1,
            notes: {
              '0,0': {1, 2, 3},
              '0,4': {1, 3},
              '2,0': {2, 3},
              '0,1': {3, 8},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,4': alertColor,
              '2,0': alertColor,
              '0,1': targetColor,
            },
          ),
          SlideData(
            text:
                'Pivot {1,2,3} and pincers {1,3} & {2,3} all share candidate 3. Thus, Row 1 Col 2 (seeing all three) cannot contain 3. Row 1 Col 2 must be 8! Input 8.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 1,
            notes: {
              '0,0': {1, 2, 3},
              '0,4': {1, 3},
              '2,0': {2, 3},
            },
            expectedValue: 8,
            interactiveHelp:
                'Since 3 is forced in one of these cells, candidate 3 is eliminated from Row 1 Col 2.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,4': alertColor,
              '2,0': alertColor,
              '0,1': targetColor,
            },
          ),
        ],
      ),

      // 25. WXYZ-Wing
      LessonData(
        title: 'WXYZ-Wing (4-Y-Wing)',
        slides: [
          SlideData(
            text:
                'A WXYZ-Wing is a 4-cell wing with four candidates {A,B,C,D}. It eliminates the shared candidate from cells seeing all four.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 1,
            notes: {
              '0,0': {1, 2, 3, 4},
              '0,3': {1, 4},
              '3,0': {2, 4},
              '1,1': {3, 4},
              '0,1': {4, 7},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,3': alertColor,
              '3,0': alertColor,
              '1,1': alertColor,
              '0,1': targetColor,
            },
          ),
          SlideData(
            text:
                'The common candidate 4 is eliminated from Row 1 Col 2. Therefore, Row 1 Col 2 must be 7! Input 7.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 1,
            notes: {
              '0,0': {1, 2, 3, 4},
              '0,3': {1, 4},
              '3,0': {2, 4},
              '1,1': {3, 4},
            },
            expectedValue: 7,
            interactiveHelp:
                'Candidate 4 is eliminated from Row 1 Col 2 due to the WXYZ-Wing structure.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,3': alertColor,
              '3,0': alertColor,
              '1,1': alertColor,
              '0,1': targetColor,
            },
          ),
        ],
      ),

      // 26. 5-Y-Wing
      LessonData(
        title: '5-Y-Wing',
        slides: [
          SlideData(
            text:
                'A 5-Y-Wing is a 5-cell wing with five candidates {1,2,3,4,5}. It eliminates the shared candidate 5 from cells seeing all five.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 1,
            notes: {
              '0,0': {1, 2, 3, 4, 5},
              '0,3': {1, 5},
              '3,0': {2, 5},
              '1,1': {3, 5},
              '0,8': {4, 5},
              '0,1': {5, 6},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,3': alertColor,
              '3,0': alertColor,
              '1,1': alertColor,
              '0,8': alertColor,
              '0,1': targetColor,
            },
          ),
          SlideData(
            text:
                'The common candidate 5 is eliminated from Row 1 Col 2. Thus, Row 1 Col 2 must be 6! Input 6.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 1,
            notes: {
              '0,0': {1, 2, 3, 4, 5},
              '0,3': {1, 5},
              '3,0': {2, 5},
              '1,1': {3, 5},
              '0,8': {4, 5},
            },
            expectedValue: 6,
            interactiveHelp:
                'Candidate 5 is eliminated from Row 1 Col 2 due to the 5-Y-Wing structure.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,3': alertColor,
              '3,0': alertColor,
              '1,1': alertColor,
              '0,8': alertColor,
              '0,1': targetColor,
            },
          ),
        ],
      ),

      // 27. 6-Y-Wing
      LessonData(
        title: '6-Y-Wing',
        slides: [
          SlideData(
            text:
                'A 6-Y-Wing is a 6-cell wing with six candidates. It eliminates the shared candidate 6 from cells seeing all six.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 1,
            notes: {
              '0,0': {1, 2, 3, 4, 5, 6},
              '0,3': {1, 6},
              '3,0': {2, 6},
              '1,1': {3, 6},
              '0,8': {4, 6},
              '8,0': {5, 6},
              '0,1': {6, 9},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,3': alertColor,
              '3,0': alertColor,
              '1,1': alertColor,
              '0,8': alertColor,
              '8,0': alertColor,
              '0,1': targetColor,
            },
          ),
          SlideData(
            text:
                'The common candidate 6 is eliminated from Row 1 Col 2. Thus, Row 1 Col 2 must be 9! Input 9.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 1,
            notes: {
              '0,0': {1, 2, 3, 4, 5, 6},
              '0,3': {1, 6},
              '3,0': {2, 6},
              '1,1': {3, 6},
              '0,8': {4, 6},
              '8,0': {5, 6},
            },
            expectedValue: 9,
            interactiveHelp:
                'Candidate 6 is eliminated from Row 1 Col 2 due to the 6-Y-Wing structure.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,3': alertColor,
              '3,0': alertColor,
              '1,1': alertColor,
              '0,8': alertColor,
              '8,0': alertColor,
              '0,1': targetColor,
            },
          ),
        ],
      ),

      // 28. 7-Y-Wing
      LessonData(
        title: '7-Y-Wing',
        slides: [
          SlideData(
            text:
                'A 7-Y-Wing is a 7-cell wing with seven candidates. It eliminates the shared candidate 7 from cells seeing all seven.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 1,
            notes: {
              '0,0': {1, 2, 3, 4, 5, 6, 7},
              '0,3': {1, 7},
              '3,0': {2, 7},
              '1,1': {3, 7},
              '0,8': {4, 7},
              '8,0': {5, 7},
              '2,2': {6, 7},
              '0,1': {7, 8},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,3': alertColor,
              '3,0': alertColor,
              '1,1': alertColor,
              '0,8': alertColor,
              '8,0': alertColor,
              '2,2': alertColor,
              '0,1': targetColor,
            },
          ),
          SlideData(
            text:
                'The common candidate 7 is eliminated from Row 1 Col 2. Thus, Row 1 Col 2 must be 8! Input 8.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 1,
            notes: {
              '0,0': {1, 2, 3, 4, 5, 6, 7},
              '0,3': {1, 7},
              '3,0': {2, 7},
              '1,1': {3, 7},
              '0,8': {4, 7},
              '8,0': {5, 7},
              '2,2': {6, 7},
            },
            expectedValue: 8,
            interactiveHelp:
                'Candidate 7 is eliminated from Row 1 Col 2 due to the 7-Y-Wing structure.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,3': alertColor,
              '3,0': alertColor,
              '1,1': alertColor,
              '0,8': alertColor,
              '8,0': alertColor,
              '2,2': alertColor,
              '0,1': targetColor,
            },
          ),
        ],
      ),

      // 29. 8-Y-Wing
      LessonData(
        title: '8-Y-Wing',
        slides: [
          SlideData(
            text:
                'An 8-Y-Wing is an 8-cell wing with eight candidates. It eliminates the shared candidate 8 from cells seeing all eight.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 1,
            notes: {
              '0,0': {1, 2, 3, 4, 5, 6, 7, 8},
              '0,3': {1, 8},
              '3,0': {2, 8},
              '1,1': {3, 8},
              '0,8': {4, 8},
              '8,0': {5, 8},
              '2,2': {6, 8},
              '0,5': {7, 8},
              '0,1': {8, 9},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,3': alertColor,
              '3,0': alertColor,
              '1,1': alertColor,
              '0,8': alertColor,
              '8,0': alertColor,
              '2,2': alertColor,
              '0,5': alertColor,
              '0,1': targetColor,
            },
          ),
          SlideData(
            text:
                'The common candidate 8 is eliminated from Row 1 Col 2. Thus, Row 1 Col 2 must be 9! Input 9.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 1,
            notes: {
              '0,0': {1, 2, 3, 4, 5, 6, 7, 8},
              '0,3': {1, 8},
              '3,0': {2, 8},
              '1,1': {3, 8},
              '0,8': {4, 8},
              '8,0': {5, 8},
              '2,2': {6, 8},
              '0,5': {7, 8},
            },
            expectedValue: 9,
            interactiveHelp:
                'Candidate 8 is eliminated from Row 1 Col 2 due to the 8-Y-Wing structure.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,3': alertColor,
              '3,0': alertColor,
              '1,1': alertColor,
              '0,8': alertColor,
              '8,0': alertColor,
              '2,2': alertColor,
              '0,5': alertColor,
              '0,1': targetColor,
            },
          ),
        ],
      ),

      // 30. W-Wing
      LessonData(
        title: 'W-Wing',
        slides: [
          SlideData(
            text:
                'A W-Wing connects two identical bi-value cells {A,B} via a strong link of A in another house. It eliminates B from cells seeing both bi-value endpoints.',
            board: emptyBoard(),
            highlightedRow: 1,
            highlightedCol: 4,
            notes: {
              '1,1': {2, 7},
              '1,7': {2, 7},
              '5,1': {7},
              '5,7': {7},
              '1,4': {2, 5},
            },
            customHighlights: (context) => {
              '1,1': helperColor,
              '1,7': helperColor,
              '5,1': alertColor,
              '5,7': alertColor,
              '1,4': targetColor,
            },
          ),
          SlideData(
            text:
                'The strong link of 7s in Row 6 connects the bi-value {2,7} cells. This eliminates candidate 2 from Row 2 Col 5, leaving only 5! Input 5.',
            board: emptyBoard(),
            highlightedRow: 1,
            highlightedCol: 4,
            notes: {
              '1,1': {2, 7},
              '1,7': {2, 7},
              '5,1': {7},
              '5,7': {7},
            },
            expectedValue: 5,
            interactiveHelp:
                'Since 2 must be in Row 2 Col 2 or Row 2 Col 8, Row 2 Col 5 cannot contain candidate 2.',
            customHighlights: (context) => {
              '1,1': helperColor,
              '1,7': helperColor,
              '5,1': alertColor,
              '5,7': alertColor,
              '1,4': targetColor,
            },
          ),
        ],
      ),

      // 31. Simple Coloring
      LessonData(
        title: 'Simple Coloring',
        slides: [
          SlideData(
            text:
                'Simple Coloring colors conjugate pairs of a single digit in two alternating colors. If a cell sees both colors, that candidate is eliminated from it.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 0,
            notes: {
              '0,0': {9},
              '0,5': {9},
              '5,5': {9},
              '5,1': {9},
              '5,0': {9, 3},
            },
            customHighlights: (context) => {
              '0,0': Colors.blue.withValues(alpha: 0.35),
              '0,5': Colors.green.withValues(alpha: 0.35),
              '5,5': Colors.blue.withValues(alpha: 0.35),
              '5,1': Colors.green.withValues(alpha: 0.35),
              '5,0': targetColor,
            },
          ),
          SlideData(
            text:
                'Row 6 Col 1 sees both blue (Row 1 Col 1) and green (Row 6 Col 2) cells. This eliminates candidate 9, leaving only 3! Input 3.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 0,
            notes: {
              '0,0': {9},
              '0,5': {9},
              '5,5': {9},
              '5,1': {9},
            },
            expectedValue: 3,
            interactiveHelp:
                'Since Row 6 Col 1 sees both alternating states, it cannot contain 9.',
            customHighlights: (context) => {
              '0,0': Colors.blue.withValues(alpha: 0.35),
              '0,5': Colors.green.withValues(alpha: 0.35),
              '5,5': Colors.blue.withValues(alpha: 0.35),
              '5,1': Colors.green.withValues(alpha: 0.35),
              '5,0': targetColor,
            },
          ),
        ],
      ),

      // 32. X-Chain
      LessonData(
        title: 'X-Chain',
        slides: [
          SlideData(
            text:
                'An X-Chain is a single-digit chain of alternating strong and weak links. It eliminates that candidate from cells seeing both endpoints.',
            board: emptyBoard(),
            highlightedRow: 8,
            highlightedCol: 1,
            notes: {
              '0,1': {4},
              '0,7': {4},
              '5,7': {4},
              '5,3': {4},
              '8,3': {4},
              '8,1': {4, 1},
            },
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,7': helperColor,
              '5,7': helperColor,
              '5,3': helperColor,
              '8,3': helperColor,
              '8,1': targetColor,
            },
          ),
          SlideData(
            text:
                'The X-Chain links Row 1 Col 2 to Row 9 Col 4. Row 9 Col 2 sees both endpoints, eliminating 4 and leaving 1! Input 1.',
            board: emptyBoard(),
            highlightedRow: 8,
            highlightedCol: 1,
            notes: {
              '0,1': {4},
              '0,7': {4},
              '5,7': {4},
              '5,3': {4},
              '8,3': {4},
            },
            expectedValue: 1,
            interactiveHelp:
                'Candidate 4 must be in either Row 1 Col 2 or Row 9 Col 4, so it is eliminated from Row 9 Col 2.',
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,7': helperColor,
              '5,7': helperColor,
              '5,3': helperColor,
              '8,3': helperColor,
              '8,1': targetColor,
            },
          ),
        ],
      ),

      // 33. Grouped X-Chain
      LessonData(
        title: 'Grouped X-Chain',
        slides: [
          SlideData(
            text:
                'A Grouped X-Chain is like an X-Chain, but links can consist of multiple cells in a single house (such as pointing candidate groups).',
            board: emptyBoard(),
            highlightedRow: 8,
            highlightedCol: 0,
            notes: {
              '0,0': {3},
              '0,4': {3},
              '0,5': {3},
              '1,4': {3},
              '8,4': {3},
              '8,0': {3, 7},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,4': helperColor,
              '0,5': helperColor,
              '1,4': helperColor,
              '8,4': helperColor,
              '8,0': targetColor,
            },
          ),
          SlideData(
            text:
                'The Grouped X-Chain eliminates candidate 3 from Row 9 Col 1. Therefore, Row 9 Col 1 must be 7! Input 7.',
            board: emptyBoard(),
            highlightedRow: 8,
            highlightedCol: 0,
            notes: {
              '0,0': {3},
              '0,4': {3},
              '0,5': {3},
              '1,4': {3},
              '8,4': {3},
            },
            expectedValue: 7,
            interactiveHelp:
                'Candidate 3 is eliminated from Row 9 Col 1 by the grouped X-chain.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,4': helperColor,
              '0,5': helperColor,
              '1,4': helperColor,
              '8,4': helperColor,
              '8,0': targetColor,
            },
          ),
        ],
      ),

      // 34. 3D Medusa
      LessonData(
        title: '3D Medusa',
        slides: [
          SlideData(
            text:
                '3D Medusa is a multi-digit coloring strategy. Alternating colors are assigned across different digits and cells, eliminating candidates seeing opposite colored links.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 0,
            notes: {
              '0,0': {1, 2},
              '0,5': {2, 3},
              '5,5': {3, 1},
              '5,0': {1, 4},
            },
            customHighlights: (context) => {
              '0,0': Colors.blue.withValues(alpha: 0.35),
              '0,5': Colors.green.withValues(alpha: 0.35),
              '5,5': Colors.blue.withValues(alpha: 0.35),
              '5,0': targetColor,
            },
          ),
          SlideData(
            text:
                'The 3D Medusa coloring chain eliminates candidate 1 from Row 6 Col 1. Therefore, Row 6 Col 1 must be 4! Input 4.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 0,
            notes: {
              '0,0': {1, 2},
              '0,5': {2, 3},
              '5,5': {3, 1},
            },
            expectedValue: 4,
            interactiveHelp:
                'Candidate 1 is eliminated from Row 6 Col 1 by the 3D Medusa chain.',
            customHighlights: (context) => {
              '0,0': Colors.blue.withValues(alpha: 0.35),
              '0,5': Colors.green.withValues(alpha: 0.35),
              '5,5': Colors.blue.withValues(alpha: 0.35),
              '5,0': targetColor,
            },
          ),
        ],
      ),

      // 35. XY-Chain
      LessonData(
        title: 'XY-Chain',
        slides: [
          SlideData(
            text:
                'An XY-Chain is a chain composed entirely of bi-value cells. If the start and end of the chain share a candidate, that candidate can be eliminated from cells seeing both ends.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 0,
            notes: {
              '0,0': {1, 2},
              '0,5': {2, 3},
              '5,5': {3, 4},
              '5,1': {4, 1},
              '5,0': {1, 9},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,5': helperColor,
              '5,5': helperColor,
              '5,1': helperColor,
              '5,0': targetColor,
            },
          ),
          SlideData(
            text:
                'The XY-Chain starting at Row 1 Col 1 and ending at Row 6 Col 2 forces candidate 1 into one of those cells, eliminating 1 from Row 6 Col 1. Input 9.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 0,
            notes: {
              '0,0': {1, 2},
              '0,5': {2, 3},
              '5,5': {3, 4},
              '5,1': {4, 1},
            },
            expectedValue: 9,
            interactiveHelp:
                'Eliminate 1 from Row 6 Col 1 since 1 must be in either Row 1 Col 1 or Row 6 Col 2.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,5': helperColor,
              '5,5': helperColor,
              '5,1': helperColor,
              '5,0': targetColor,
            },
          ),
        ],
      ),

      // 36. Alternating Inference Chain (AIC)
      LessonData(
        title: 'Alternating Inference Chain (AIC)',
        slides: [
          SlideData(
            text:
                'An AIC alternates strong and weak links of both cells and candidates. It establishes inference between endpoints, eliminating candidates seeing both.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 0,
            notes: {
              '0,0': {1, 2},
              '0,5': {1, 2},
              '5,5': {2, 7},
              '5,0': {2, 8},
            },
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,5': helperColor,
              '5,5': helperColor,
              '5,0': targetColor,
            },
          ),
          SlideData(
            text:
                'The AIC chain forces candidate 2 into either Row 1 Col 1 or Row 6 Col 6. This eliminates 2 from Row 6 Col 1. Input 8.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 0,
            notes: {
              '0,0': {1, 2},
              '0,5': {1, 2},
              '5,5': {2, 7},
            },
            expectedValue: 8,
            interactiveHelp:
                'AIC eliminates candidate 2 from Row 6 Col 1, leaving only 8.',
            customHighlights: (context) => {
              '0,0': helperColor,
              '0,5': helperColor,
              '5,5': helperColor,
              '5,0': targetColor,
            },
          ),
        ],
      ),

      // 37. Nishio Forcing Chain
      LessonData(
        title: 'Nishio Forcing Chain',
        slides: [
          SlideData(
            text:
                'A Nishio Forcing Chain assumes a cell is a candidate. If this assumption leads to a contradiction, that candidate is eliminated from the starting cell.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 0,
            notes: {
              '0,0': {5, 2},
              '0,5': {5},
              '5,5': {5},
              '5,1': {5},
              '0,1': {5},
            },
            customHighlights: (context) {
              final assumptionColor = Colors.orange.withValues(alpha: 0.35);
              return {
                '0,0': targetColor,
                '0,5': assumptionColor,
                '5,5': assumptionColor,
                '5,1': assumptionColor,
                '0,1': assumptionColor,
              };
            },
          ),
          SlideData(
            text:
                'Assuming Row 1 Col 1 is 5 forces a contradiction (two 5s in Box 1). Thus, Row 1 Col 1 cannot be 5, leaving only 2! Input 2.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 0,
            notes: {
              '0,5': {5},
              '5,5': {5},
              '5,1': {5},
              '0,1': {5},
            },
            expectedValue: 2,
            interactiveHelp:
                'Assuming 5 leads to a contradiction, so 5 is eliminated from Row 1 Col 1.',
            customHighlights: (context) => {'0,0': targetColor},
          ),
        ],
      ),

      // 38. Cell/Region Forcing Chain
      LessonData(
        title: 'Cell/Region Forcing Chain',
        slides: [
          SlideData(
            text:
                'Cell Forcing Chains trace the implications of every candidate in a cell. If all candidates force the same value in another cell, that value is solved.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 5,
            notes: {
              '0,0': {1, 2},
              '0,5': {1, 3},
              '5,0': {2, 4},
              '5,5': {3, 4},
            },
            customHighlights: (context) => {
              '0,0': alertColor,
              '0,5': helperColor,
              '5,0': helperColor,
              '5,5': targetColor,
            },
          ),
          SlideData(
            text:
                'Whether Row 1 Col 1 is 1 or 2, both paths force Row 6 Col 6 to be 4. Therefore, Row 6 Col 6 must be 4! Input 4.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 5,
            notes: {
              '0,0': {1, 2},
              '0,5': {1, 3},
              '5,0': {2, 4},
            },
            expectedValue: 4,
            interactiveHelp:
                'Both candidate states for Row 1 Col 1 force Row 6 Col 6 to be 4.',
            customHighlights: (context) => {
              '0,0': alertColor,
              '0,5': helperColor,
              '5,0': helperColor,
              '5,5': targetColor,
            },
          ),
        ],
      ),

      // 39. Cell/Region Forcing Net
      LessonData(
        title: 'Cell/Region Forcing Net',
        slides: [
          SlideData(
            text:
                'A Forcing Net is a network of forcing implications. Multiple branches of deduction converge to force a candidate value into a specific cell.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 5,
            notes: {
              '0,0': {1, 2, 3},
              '5,5': {9},
            },
            customHighlights: (context) => {
              '0,0': alertColor,
              '5,5': targetColor,
            },
          ),
          SlideData(
            text:
                'All three branches of implication starting from Row 1 Col 1 ({1, 2, 3}) converge to force Row 6 Col 6 to be 9! Input 9.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 5,
            notes: {
              '0,0': {1, 2, 3},
            },
            expectedValue: 9,
            interactiveHelp:
                'Every possible candidate state for Row 1 Col 1 leads directly to 9 in Row 6 Col 6.',
            customHighlights: (context) => {
              '0,0': alertColor,
              '5,5': targetColor,
            },
          ),
        ],
      ),

      // 40. Unique Rectangle Type 1
      LessonData(
        title: 'Unique Rectangle Type 1',
        slides: [
          SlideData(
            text:
                'Sudoku puzzles must have a unique solution. To prevent a non-unique deadly pattern {A,B} in four cells sharing rows/cols/boxes, the cell with an extra candidate must be that extra value.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 7,
            notes: {
              '0,1': {3, 8},
              '0,7': {3, 8},
              '5,1': {3, 8},
              '5,7': {3, 8, 5},
            },
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,7': helperColor,
              '5,1': helperColor,
              '5,7': targetColor,
            },
          ),
          SlideData(
            text:
                'If Row 6 Col 8 is 3 or 8, it creates a non-unique deadly loop. Therefore, Row 6 Col 8 must be 5! Input 5.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 7,
            notes: {
              '0,1': {3, 8},
              '0,7': {3, 8},
              '5,1': {3, 8},
            },
            expectedValue: 5,
            interactiveHelp:
                'To avoid a non-unique deadly loop of {3, 8}, Row 6 Col 8 must be the extra candidate 5.',
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,7': helperColor,
              '5,1': helperColor,
              '5,7': targetColor,
            },
          ),
        ],
      ),

      // 41. Unique Rectangle Type 2
      LessonData(
        title: 'Unique Rectangle Type 2',
        slides: [
          SlideData(
            text:
                'In Type 2, two cells contain an extra candidate C. C must be in one of those two cells, eliminating C from other cells in their shared house.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 4,
            notes: {
              '0,1': {3, 8},
              '0,7': {3, 8},
              '5,1': {3, 8, 5},
              '5,7': {3, 8, 5},
              '5,4': {5, 9},
            },
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,7': helperColor,
              '5,1': helperColor,
              '5,7': helperColor,
              '5,4': targetColor,
            },
          ),
          SlideData(
            text:
                'Candidate 5 must appear in Row 6 Col 2 or Row 6 Col 8. This eliminates 5 from Row 6 Col 5, leaving only 9! Input 9.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 4,
            notes: {
              '0,1': {3, 8},
              '0,7': {3, 8},
              '5,1': {3, 8, 5},
              '5,7': {3, 8, 5},
            },
            expectedValue: 9,
            interactiveHelp:
                'Since 5 is locked in Row 6 of the rectangle, candidate 5 is eliminated from Row 6 Col 5.',
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,7': helperColor,
              '5,1': helperColor,
              '5,7': helperColor,
              '5,4': targetColor,
            },
          ),
        ],
      ),

      // 42. Unique Rectangle Type 3
      LessonData(
        title: 'Unique Rectangle Type 3',
        slides: [
          SlideData(
            text:
                'In Type 3, two cells contain extra candidates that form a naked pair/triple with other cells in their shared house, allowing eliminations of those extra candidates.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 8,
            notes: {
              '0,1': {3, 8},
              '0,7': {3, 8},
              '5,1': {3, 8, 1, 2},
              '5,7': {3, 8, 1, 2},
              '5,4': {1, 2},
              '5,8': {1, 6},
            },
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,7': helperColor,
              '5,1': helperColor,
              '5,7': helperColor,
              '5,4': alertColor,
              '5,8': targetColor,
            },
          ),
          SlideData(
            text:
                'The extra candidates {1,2} form a Naked Pair in Row 6 with Row 6 Col 5. This eliminates 1 from Row 6 Col 9, leaving only 6! Input 6.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 8,
            notes: {
              '0,1': {3, 8},
              '0,7': {3, 8},
              '5,1': {3, 8, 1, 2},
              '5,7': {3, 8, 1, 2},
              '5,4': {1, 2},
            },
            expectedValue: 6,
            interactiveHelp:
                'The naked pair of {1, 2} in Row 6 eliminates candidate 1 from Row 6 Col 9.',
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,7': helperColor,
              '5,1': helperColor,
              '5,7': helperColor,
              '5,4': alertColor,
              '5,8': targetColor,
            },
          ),
        ],
      ),

      // 43. Unique Rectangle Type 4
      LessonData(
        title: 'Unique Rectangle Type 4',
        slides: [
          SlideData(
            text:
                'In Type 4, if one candidate is locked in the two remaining cells in a house, we eliminate the other candidate from those two cells to avoid a deadly loop.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 7,
            notes: {
              '0,1': {3, 8},
              '0,7': {3, 8},
              '5,1': {3, 8},
              '5,7': {3, 8},
            },
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,7': helperColor,
              '5,1': helperColor,
              '5,7': targetColor,
            },
          ),
          SlideData(
            text:
                'Since candidate 8 is locked in Row 6 of the rectangle, candidate 3 is eliminated from Row 6 Col 8. Row 6 Col 8 must be 8! Input 8.',
            board: emptyBoard(),
            highlightedRow: 5,
            highlightedCol: 7,
            notes: {
              '0,1': {3, 8},
              '0,7': {3, 8},
              '5,1': {3, 8},
            },
            expectedValue: 8,
            interactiveHelp:
                'Eliminating 3 from Row 6 Col 8 leaves 8 as the only possible candidate.',
            customHighlights: (context) => {
              '0,1': helperColor,
              '0,7': helperColor,
              '5,1': helperColor,
              '5,7': targetColor,
            },
          ),
        ],
      ),

      // 44. Unique Rectangle Type 5
      LessonData(
        title: 'Unique Rectangle Type 5',
        slides: [
          SlideData(
            text:
                'In Type 5, diagonally opposite cells have extra candidates. This forces the extra candidate to be true, solving the starting cell.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 1,
            notes: {
              '0,1': {3, 8, 5},
              '0,7': {3, 8},
              '5,1': {3, 8},
              '5,7': {3, 8, 5},
            },
            customHighlights: (context) => {
              '0,1': targetColor,
              '0,7': helperColor,
              '5,1': helperColor,
              '5,7': helperColor,
            },
          ),
          SlideData(
            text:
                'To avoid a deadly loop, the extra candidate 5 must be true in either Row 1 Col 2 or Row 6 Col 8. Thus, Row 1 Col 2 is 5! Input 5.',
            board: emptyBoard(),
            highlightedRow: 0,
            highlightedCol: 1,
            notes: {
              '0,7': {3, 8},
              '5,1': {3, 8},
              '5,7': {3, 8, 5},
            },
            expectedValue: 5,
            interactiveHelp:
                'To avoid the deadly pattern of {3, 8}, Row 1 Col 2 must be solved as 5.',
            customHighlights: (context) => {
              '0,1': targetColor,
              '0,7': helperColor,
              '5,1': helperColor,
              '5,7': helperColor,
            },
          ),
        ],
      ),

      // 45. BUG
      LessonData(
        title: 'BUG (Binary Universal Grave)',
        slides: [
          SlideData(
            text:
                'BUG (Binary Universal Grave) occurs when all unsolved cells have exactly two candidates except one cell which has three. The correct digit is the one appearing three times in its row/col/box.',
            board: emptyBoard(),
            highlightedRow: 4,
            highlightedCol: 4,
            notes: {
              '4,4': {1, 2, 3},
            },
            customHighlights: (context) => {'4,4': alertColor},
          ),
          SlideData(
            text:
                'The tri-value cell at Row 5 Col 5 contains {1, 2, 3}. Candidate 3 appears three times in Row 5, Col 5, and Box 5. Therefore, Row 5 Col 5 must be 3! Input 3.',
            board: emptyBoard(),
            highlightedRow: 4,
            highlightedCol: 4,
            notes: {},
            expectedValue: 3,
            interactiveHelp:
                'According to the BUG+1 rule, the candidate that appears three times in the cell\'s row, col, and box is the correct answer.',
            customHighlights: (context) => {'4,4': targetColor},
          ),
        ],
      ),
    ];
  }
}
