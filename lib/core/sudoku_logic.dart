import 'dart:math';

/// Representation and core logic for Sudoku operations.
class SudokuLogic {
  /// Check if placing [val] at board[[row]][[col]] is valid according to Sudoku rules.
  static bool isValid(List<List<int>> board, int row, int col, int val) {
    // Check row for duplicates
    for (int c = 0; c < 9; c++) {
      if (c != col && board[row][c] == val) return false;
    }

    // Check column for duplicates
    for (int r = 0; r < 9; r++) {
      if (r != row && board[r][col] == val) return false;
    }

    // Check 3x3 subgrid for duplicates
    int boxRowStart = row - row % 3;
    int boxColStart = col - col % 3;
    for (int r = boxRowStart; r < boxRowStart + 3; r++) {
      for (int c = boxColStart; c < boxColStart + 3; c++) {
        if ((r != row || c != col) && board[r][c] == val) return false;
      }
    }

    return true;
  }

  /// Check if the entire board layout is valid, ensuring no rule violations.
  /// This is used to validate custom boards before solving.
  static bool isBoardValid(List<List<int>> board) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        int val = board[r][c];
        if (val != 0) {
          if (!isValid(board, r, c, val)) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// Solves the Sudoku board in-place.
  /// Returns true if a solution is found, false if unsolvable.
  static bool solve(List<List<int>> board) {
    int row = -1;
    int col = -1;
    bool isEmpty = false;

    // Use Minimum Remaining Values (MRV) heuristic to choose the cell with the fewest candidates
    int minOptions = 10;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == 0) {
          int options = 0;
          for (int val = 1; val <= 9; val++) {
            if (isValid(board, r, c, val)) {
              options++;
            }
          }
          if (options < minOptions) {
            minOptions = options;
            row = r;
            col = c;
            isEmpty = true;
          }
        }
      }
    }

    if (!isEmpty) {
      return true; // No empty cells, board solved
    }

    for (int val = 1; val <= 9; val++) {
      if (isValid(board, row, col, val)) {
        board[row][col] = val;
        if (solve(board)) return true;
        board[row][col] = 0; // Backtrack
      }
    }

    return false;
  }

  /// Creates a deep copy of a 2D grid.
  static List<List<int>> copyBoard(List<List<int>> board) {
    return List.generate(9, (r) => List.from(board[r]));
  }

  /// Counts the number of solutions a Sudoku puzzle has, up to the given [limit].
  /// This is used to check if a board has a unique solution.
  static int _countSolutions(List<List<int>> board, int limit, {int count = 0}) {
    if (count >= limit) return count;

    int row = -1;
    int col = -1;
    bool isEmpty = false;

    // Find the cell with the fewest candidate values (MRV heuristic)
    int minOptions = 10;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == 0) {
          int options = 0;
          for (int val = 1; val <= 9; val++) {
            if (isValid(board, r, c, val)) options++;
          }
          if (options < minOptions) {
            minOptions = options;
            row = r;
            col = c;
            isEmpty = true;
          }
        }
      }
    }

    if (!isEmpty) {
      return count + 1; // Solution found
    }

    for (int val = 1; val <= 9; val++) {
      if (isValid(board, row, col, val)) {
        board[row][col] = val;
        count = _countSolutions(board, limit, count: count);
        board[row][col] = 0; // Backtrack
        if (count >= limit) break;
      }
    }

    return count;
  }

  /// Checks if a board has exactly one unique solution.
  static bool hasUniqueSolution(List<List<int>> board) {
    var temp = copyBoard(board);
    return _countSolutions(temp, 2) == 1;
  }

  /// Generates a fully solved Sudoku board.
  static List<List<int>> generateSolvedBoard() {
    List<List<int>> board = List.generate(9, (_) => List.filled(9, 0));
    _fillBoardRandomly(board);
    return board;
  }

  static bool _fillBoardRandomly(List<List<int>> board) {
    int row = -1;
    int col = -1;
    bool isEmpty = false;

    // Simple MRV heuristic for random generation
    int minOptions = 10;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == 0) {
          int options = 0;
          for (int val = 1; val <= 9; val++) {
            if (isValid(board, r, c, val)) options++;
          }
          if (options < minOptions) {
            minOptions = options;
            row = r;
            col = c;
            isEmpty = true;
          }
        }
      }
    }

    if (!isEmpty) {
      return true;
    }

    List<int> numbers = List.generate(9, (i) => i + 1)..shuffle();
    for (int val in numbers) {
      if (isValid(board, row, col, val)) {
        board[row][col] = val;
        if (_fillBoardRandomly(board)) return true;
        board[row][col] = 0;
      }
    }

    return false;
  }

  /// Generates a Sudoku game with a unique solution according to [difficulty].
  /// [difficulty] can be 'easy', 'medium', or 'hard'.
  static SudokuPuzzle generatePuzzle(String difficulty) {
    int cellsToRemove;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        cellsToRemove = 53; // Leaves 28 clues
        break;
      case 'medium':
        cellsToRemove = 58; // Leaves 23 clues
        break;
      case 'hard':
        cellsToRemove = 63; // Leaves 18 clues
        break;
      default:
        cellsToRemove = 53;
    }

    List<List<int>> solved = [];
    List<List<int>> puzzle = [];

    // Retry generation if a random removal sequence gets stuck before reaching target
    for (int attempt = 0; attempt < 5; attempt++) {
      solved = generateSolvedBoard();
      puzzle = copyBoard(solved);

      // List of coordinates to try removing
      List<Point<int>> coordinates = [];
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          coordinates.add(Point(r, c));
        }
      }
      coordinates.shuffle();

      int removed = 0;
      for (var point in coordinates) {
        if (removed >= cellsToRemove) break;

        int r = point.x;
        int c = point.y;
        int backup = puzzle[r][c];

        puzzle[r][c] = 0;

        // Verify that the puzzle still has a unique solution
        if (hasUniqueSolution(puzzle)) {
          removed++;
        } else {
          puzzle[r][c] = backup; // Revert if removal causes multiple solutions
        }
      }

      // If we hit the target removed count, or came within 1 cell, accept the puzzle
      if (removed >= cellsToRemove - 1) {
        break;
      }
    }

    return SudokuPuzzle(
      solvedBoard: solved,
      puzzleBoard: puzzle,
      difficulty: difficulty,
    );
  }
}

/// Helper model containing the solved grid, puzzle grid, and its difficulty level.
class SudokuPuzzle {
  final List<List<int>> solvedBoard;
  final List<List<int>> puzzleBoard;
  final String difficulty;

  SudokuPuzzle({
    required this.solvedBoard,
    required this.puzzleBoard,
    required this.difficulty,
  });
}
