import 'package:flutter_test/flutter_test.dart';
import 'package:dart_sudoku/core/sudoku_logic.dart';
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
      final puzzle = SudokuLogic.generatePuzzle('easy');
      expect(puzzle.difficulty, 'easy');
      
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
    });
  });
}
