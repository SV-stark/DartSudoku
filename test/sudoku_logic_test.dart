import 'package:flutter_test/flutter_test.dart';
import 'package:dart_sudoku/core/sudoku_logic.dart';
import 'package:dart_sudoku/core/difficulty.dart';
import 'package:dart_sudoku/core/sudoku_analyzer.dart';

void main() {
  group('SudokuLogic Tests', () {
    test('generateSolvedBoard should return a valid complete Sudoku board', () {
      final board = SudokuLogic.generateSolvedBoard();

      // Verify board size
      expect(board.length, 9);
      for (var row in board) {
        expect(row.length, 9);
      }

      // Verify all cells are filled and valid
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          expect(board[r][c], isNot(0));
          expect(SudokuLogic.isValid(board, r, c, board[r][c]), true);
        }
      }

      expect(SudokuLogic.isBoardValid(board), true);
    });

    test('solve should solve an empty board', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      final success = SudokuLogic.solve(board);

      expect(success, true);
      expect(SudokuLogic.isBoardValid(board), true);
      for (var r in board) {
        for (var val in r) {
          expect(val, isNot(0));
        }
      }
    });

    test('isBoardValid should detect invalid boards', () {
      // Create a valid solved board and insert a conflict
      final board = SudokuLogic.generateSolvedBoard();

      expect(SudokuLogic.isBoardValid(board), true);

      // Introduce a duplicate in the first row
      final val = board[0][0];
      board[0][1] = val; // Now board[0][0] and board[0][1] are identical

      expect(SudokuLogic.isBoardValid(board), false);
    });

    test('generatePuzzle should generate puzzles with unique solutions', () {
      final puzzle = SudokuLogic.generatePuzzle(Difficulty.easy);
      expect(puzzle.difficulty, Difficulty.easy);

      // Check that the puzzle grid is valid
      expect(SudokuLogic.isBoardValid(puzzle.puzzleBoard), true);

      // Check that it has a unique solution
      expect(SudokuLogic.hasUniqueSolution(puzzle.puzzleBoard), true);

      // Verify that the solved version is indeed a solution
      final solvedPuzzleCopy = SudokuLogic.copyBoard(puzzle.puzzleBoard);
      final success = SudokuLogic.solve(solvedPuzzleCopy);
      expect(success, true);

      // Verify values match the original solved board
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          expect(solvedPuzzleCopy[r][c], puzzle.solvedBoard[r][c]);
        }
      }
    });

    group('SudokuAnalyzer Tests', () {
      test('Should identify Sole Candidate', () {
        final board = List.generate(9, (_) => List.filled(9, 0));
        for (int c = 1; c < 9; c++) {
          board[0][c] = c + 1; // 2..9
        }
        final explanation = SudokuAnalyzer.analyzeCell(board, 0, 0, 1);
        expect(explanation.contains('Sole Candidate'), true);
      });

      test('Should identify Hidden Single in Row', () {
        final board = List.generate(9, (_) => List.filled(9, 0));
        for (int c = 2; c < 9; c++) {
          board[0][c] = c + 1; // 3..9
        }
        board[1][1] = 1; // Conflict blocks '1' at board[0][1]

        final explanation = SudokuAnalyzer.analyzeCell(board, 0, 0, 1);
        expect(explanation.contains('Hidden Single in Row'), true);
      });

      test('Should identify Locked Candidate (Pointing)', () {
        final board = List.generate(9, (_) => List.filled(9, 0));
        // Fill some cells in Box 0 so 1 can only go in Row 0
        board[1][0] = 2;
        board[1][1] = 3;
        board[1][2] = 4;
        board[2][0] = 5;
        board[2][1] = 6;
        board[2][2] = 7;

        final explanation = SudokuAnalyzer.analyzeCell(board, 0, 5, 8);
        expect(explanation.contains('Locked Candidate'), true);
      });

      test('Should identify Naked Pair', () {
        final board = List.generate(9, (_) => List.filled(9, 0));
        board[0][4] = 5;
        board[0][5] = 6;
        board[0][6] = 7;
        board[0][7] = 8;
        board[0][8] = 9;

        // Block 1 and 4 from Col 0 and Col 1 using solved digits inside boxes
        board[5][0] = 1;
        board[5][1] = 4;
        board[8][1] = 1;
        board[8][0] = 4;

        // Block 3 from Col 2
        board[3][2] = 3;

        // Block 2 and 3 from Col 3
        board[3][3] = 2;
        board[4][3] = 3;

        final explanation = SudokuAnalyzer.analyzeCell(board, 0, 2, 1);
        expect(explanation.contains('Naked Pair'), true);
      });

      test('Should identify Hidden Pair', () {
        final board = List.generate(9, (_) => List.filled(9, 0));
        board[0][4] = 7;
        board[0][5] = 8;
        board[0][6] = 9;
        board[0][7] = 1;

        // Block 2 and 3 from Col 2, Col 3, Col 8
        board[3][2] = 2;
        board[4][2] = 3;
        board[3][3] = 2;
        board[4][3] = 3;
        board[3][8] = 2;
        board[4][8] = 3;

        // Block 6 from Col 0 and Col 1
        board[3][0] = 6;
        board[3][1] = 6;

        // Block 5 from Col 0
        board[4][0] = 5;

        // Block 4 from Col 1
        board[4][1] = 4;

        final explanation = SudokuAnalyzer.analyzeCell(board, 0, 0, 2);
        expect(explanation.contains('Hidden Pair'), true);
      });

      test('Should identify X-Wing', () {
        final board = List.generate(9, (_) => List.filled(9, 0));
        // Row 0 setup
        board[0][1] = 2;
        board[0][2] = 3;
        board[0][5] = 6;
        board[0][6] = 7;
        board[0][7] = 8;
        board[0][8] = 9;
        board[8][0] = 4;
        board[8][4] = 4;
        board[8][3] = 1;

        // Row 4 setup
        board[4][1] = 2;
        board[4][3] = 4;
        board[4][5] = 6;
        board[4][6] = 7;
        board[4][7] = 8;
        board[4][8] = 9;
        board[7][2] = 1;

        final explanation = SudokuAnalyzer.analyzeCell(board, 2, 0, 5);
        expect(explanation.contains('X-Wing'), true);
      });
    });
  });
}
