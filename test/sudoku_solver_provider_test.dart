import 'package:flutter_test/flutter_test.dart';
import 'package:dart_sudoku/providers/sudoku_provider.dart';

void main() {
  group('SudokuSolverProvider Tests', () {
    test('Initial state should be correct', () {
      final provider = SudokuSolverProvider();
      expect(provider.status, SolverStatus.idle);
      expect(provider.selectedRow, -1);
      expect(provider.selectedCol, -1);
      expect(provider.errorMessage, isNull);

      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          expect(provider.solverBoard[r][c], 0);
        }
      }
    });

    test('selectCell and enterNumber / clearCell works correctly', () {
      final provider = SudokuSolverProvider();

      provider.selectCell(1, 2);
      expect(provider.selectedRow, 1);
      expect(provider.selectedCol, 2);

      provider.enterNumber(5);
      expect(provider.solverBoard[1][2], 5);
      expect(provider.errorMessage, isNull);

      provider.clearCell();
      expect(provider.solverBoard[1][2], 0);
    });

    test('clearBoard resets grid and selections', () {
      final provider = SudokuSolverProvider();
      provider.selectCell(4, 4);
      provider.enterNumber(9);

      provider.clearBoard();
      expect(provider.selectedRow, -1);
      expect(provider.selectedCol, -1);
      expect(provider.solverBoard[4][4], 0);
    });

    test('solveComplete solves a valid partially filled board', () {
      final provider = SudokuSolverProvider();
      // Setup a simple valid board structure (from a known solvable puzzle)
      // We will place a few numbers
      provider.selectCell(0, 0);
      provider.enterNumber(5);
      provider.selectCell(0, 1);
      provider.enterNumber(3);
      provider.selectCell(0, 4);
      provider.enterNumber(7);
      provider.selectCell(1, 0);
      provider.enterNumber(6);
      provider.selectCell(1, 3);
      provider.enterNumber(1);
      provider.selectCell(1, 4);
      provider.enterNumber(9);
      provider.selectCell(1, 5);
      provider.enterNumber(5);
      provider.selectCell(2, 1);
      provider.enterNumber(9);
      provider.selectCell(2, 2);
      provider.enterNumber(8);
      provider.selectCell(2, 7);
      provider.enterNumber(6);

      provider.solveComplete();
      expect(provider.status, SolverStatus.solved);
      expect(provider.errorMessage, isNull);

      // Verify all cells are filled
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          expect(provider.solverBoard[r][c], isNot(0));
        }
      }
    });

    test('solveComplete handles invalid layout duplicate rule violations', () {
      final provider = SudokuSolverProvider();
      provider.selectCell(0, 0);
      provider.enterNumber(5);
      provider.selectCell(0, 1);
      provider.enterNumber(5); // Conflict in row 0

      provider.solveComplete();
      expect(provider.status, SolverStatus.error);
      expect(provider.errorMessage, contains('violations'));
    });

    test('solveComplete handles unsolvable board configurations', () {
      final provider = SudokuSolverProvider();
      // Input a board configuration that has no duplicates, but cannot be solved
      // Row 0 has 2, 3, 4, 5, 6, 7, 8, 9 starting at col 1.
      // So (0, 0) must be 1.
      // But row 8 has 1 at col 0, meaning (8, 0) is 1. This blocks (0, 0) from being 1.
      // So cell (0, 0) has no valid candidates, making the board unsolvable.
      provider.selectCell(0, 1);
      provider.enterNumber(2);
      provider.selectCell(0, 2);
      provider.enterNumber(3);
      provider.selectCell(0, 3);
      provider.enterNumber(4);
      provider.selectCell(0, 4);
      provider.enterNumber(5);
      provider.selectCell(0, 5);
      provider.enterNumber(6);
      provider.selectCell(0, 6);
      provider.enterNumber(7);
      provider.selectCell(0, 7);
      provider.enterNumber(8);
      provider.selectCell(0, 8);
      provider.enterNumber(9);
      provider.selectCell(8, 0);
      provider.enterNumber(1);

      provider.solveComplete();
      expect(provider.status, SolverStatus.error);
      expect(provider.errorMessage, contains('unsolvable'));
    });

    test('solveSelectedCell solves only the selected coordinate', () {
      final provider = SudokuSolverProvider();
      provider.selectCell(0, 0);
      provider.enterNumber(5);
      provider.selectCell(0, 1);
      provider.enterNumber(3);
      provider.selectCell(0, 4);
      provider.enterNumber(7);

      // Select an empty cell to solve
      provider.selectCell(0, 2);
      provider.solveSelectedCell();

      expect(
        provider.status,
        SolverStatus.idle,
      ); // Returns to idle on single cell success
      expect(provider.solverBoard[0][2], isNot(0));
      // Rest of the board remains unsolved (mostly empty)
      int filledCount = 0;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (provider.solverBoard[r][c] != 0) {
            filledCount++;
          }
        }
      }
      expect(filledCount, 4); // 3 original + 1 solved cell
    });
  });
}
