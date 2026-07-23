import 'dart:math';
import 'difficulty.dart';
import 'constants.dart';

/// Supported game variants
enum SudokuVariant {
  standard,
  diagonalX,
  killer,
}

/// Representation of a cage in Killer Sudoku.
class KillerCage {
  final int id;
  final List<Point<int>> cells;
  final int targetSum;

  const KillerCage({
    required this.id,
    required this.cells,
    required this.targetSum,
  });

  bool containsCell(int row, int col) {
    return cells.any((p) => p.x == row && p.y == col);
  }
}

/// Representation and core logic for Sudoku operations.
class SudokuLogic {
  /// Check if placing [val] at board[[row]][[col]] is valid according to Sudoku rules and [variant].
  static bool isValid(
    List<List<int>> board,
    int row,
    int col,
    int val, {
    SudokuVariant variant = SudokuVariant.standard,
    List<KillerCage>? cages,
  }) {
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

    // Diagonal X validation
    if (variant == SudokuVariant.diagonalX) {
      if (row == col) {
        for (int i = 0; i < 9; i++) {
          if (i != row && board[i][i] == val) return false;
        }
      }
      if (row + col == 8) {
        for (int i = 0; i < 9; i++) {
          if (i != row && board[i][8 - i] == val) return false;
        }
      }
    }

    // Killer Sudoku cage validation
    if (variant == SudokuVariant.killer && cages != null) {
      final cage = cages.firstWhere(
        (c) => c.containsCell(row, col),
        orElse: () => const KillerCage(id: -1, cells: [], targetSum: 0),
      );
      if (cage.id != -1) {
        int currentSum = val;
        int emptyCount = 0;
        for (var p in cage.cells) {
          if (p.x == row && p.y == col) continue;
          int cellVal = board[p.x][p.y];
          if (cellVal != 0) {
            if (cellVal == val) return false; // Duplicate in cage
            currentSum += cellVal;
          } else {
            emptyCount++;
          }
        }
        if (currentSum > cage.targetSum) return false;
        if (emptyCount == 0 && currentSum != cage.targetSum) return false;
      }
    }

    return true;
  }

  /// Check if the entire board layout is valid, ensuring no rule violations.
  /// This is used to validate custom boards before solving.
  static bool isBoardValid(
    List<List<int>> board, {
    SudokuVariant variant = SudokuVariant.standard,
    List<KillerCage>? cages,
  }) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        int val = board[r][c];
        if (val != 0) {
          if (!isValid(board, r, c, val, variant: variant, cages: cages)) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// Solves the Sudoku board in-place.
  /// Returns true if a solution is found, false if unsolvable.
  static bool solve(
    List<List<int>> board, {
    SudokuVariant variant = SudokuVariant.standard,
    List<KillerCage>? cages,
  }) {
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
            if (isValid(board, r, c, val, variant: variant, cages: cages)) {
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
      if (isValid(board, row, col, val, variant: variant, cages: cages)) {
        board[row][col] = val;
        if (solve(board, variant: variant, cages: cages)) return true;
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
  static int _countSolutions(
    List<List<int>> board,
    int limit, {
    int count = 0,
    SudokuVariant variant = SudokuVariant.standard,
    List<KillerCage>? cages,
  }) {
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
            if (isValid(board, r, c, val, variant: variant, cages: cages)) {
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
      return count + 1; // Solution found
    }

    for (int val = 1; val <= 9; val++) {
      if (isValid(board, row, col, val, variant: variant, cages: cages)) {
        board[row][col] = val;
        count = _countSolutions(
          board,
          limit,
          count: count,
          variant: variant,
          cages: cages,
        );
        board[row][col] = 0; // Backtrack
        if (count >= limit) break;
      }
    }

    return count;
  }

  /// Checks if a board has exactly one unique solution.
  static bool hasUniqueSolution(
    List<List<int>> board, {
    SudokuVariant variant = SudokuVariant.standard,
    List<KillerCage>? cages,
  }) {
    var temp = copyBoard(board);
    return _countSolutions(temp, 2, variant: variant, cages: cages) == 1;
  }

  /// Generates default sample Killer cages for a solved board.
  static List<KillerCage> generateDefaultCages(List<List<int>> solvedBoard) {
    List<KillerCage> cages = [];
    int cageId = 1;
    Set<String> visited = {};

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (visited.contains('$r,$c')) continue;
        List<Point<int>> cells = [Point(r, c)];
        visited.add('$r,$c');

        // Form 2-cell or 3-cell cages
        if (c < 8 && !visited.contains('$r,${c + 1}')) {
          cells.add(Point(r, c + 1));
          visited.add('$r,${c + 1}');
        } else if (r < 8 && !visited.contains('${r + 1},$c')) {
          cells.add(Point(r + 1, c));
          visited.add('${r + 1},$c');
        }

        int targetSum = cells.fold(0, (sum, p) => sum + solvedBoard[p.x][p.y]);
        cages.add(KillerCage(id: cageId++, cells: cells, targetSum: targetSum));
      }
    }
    return cages;
  }

  /// Generates a fully solved Sudoku board.
  static List<List<int>> generateSolvedBoard({
    Random? random,
    SudokuVariant variant = SudokuVariant.standard,
  }) {
    List<List<int>> board = List.generate(9, (_) => List.filled(9, 0));
    _fillBoardRandomly(board, random: random, variant: variant);
    return board;
  }

  static bool _fillBoardRandomly(
    List<List<int>> board, {
    Random? random,
    SudokuVariant variant = SudokuVariant.standard,
  }) {
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
            if (isValid(board, r, c, val, variant: variant)) options++;
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

    List<int> numbers = List.generate(9, (i) => i + 1)..shuffle(random);
    for (int val in numbers) {
      if (isValid(board, row, col, val, variant: variant)) {
        board[row][col] = val;
        if (_fillBoardRandomly(board, random: random, variant: variant)) {
          return true;
        }
        board[row][col] = 0;
      }
    }

    return false;
  }

  /// Generates a Sudoku game with a unique solution according to [difficulty] and [variant].
  static SudokuPuzzle generatePuzzle(
    Difficulty difficulty, {
    int? seed,
    SudokuVariant variant = SudokuVariant.standard,
  }) {
    final random = seed != null ? Random(seed) : Random();
    int cellsToRemove;
    switch (difficulty) {
      case Difficulty.easy:
        cellsToRemove = GameConstants.easyCellsToRemove;
        break;
      case Difficulty.medium:
        cellsToRemove = GameConstants.mediumCellsToRemove;
        break;
      case Difficulty.hard:
        cellsToRemove = GameConstants.hardCellsToRemove;
        break;
    }

    List<List<int>> solved = [];
    List<List<int>> puzzle = [];
    List<KillerCage>? cages;

    // Retry generation if a random removal sequence gets stuck before reaching target
    for (
      int attempt = 0;
      attempt < GameConstants.maxGenerationRetries;
      attempt++
    ) {
      solved = generateSolvedBoard(random: random, variant: variant);
      puzzle = copyBoard(solved);
      if (variant == SudokuVariant.killer) {
        cages = generateDefaultCages(solved);
      }

      // List of coordinates to try removing
      List<Point<int>> coordinates = [];
      for (int r = 0; r < GameConstants.boardSize; r++) {
        for (int c = 0; c < GameConstants.boardSize; c++) {
          coordinates.add(Point(r, c));
        }
      }
      coordinates.shuffle(random);

      int removed = 0;
      for (var point in coordinates) {
        if (removed >= cellsToRemove) break;

        int r = point.x;
        int c = point.y;
        int backup = puzzle[r][c];

        puzzle[r][c] = 0;

        // Verify that the puzzle still has a unique solution
        if (hasUniqueSolution(puzzle, variant: variant, cages: cages)) {
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
      variant: variant,
      cages: cages,
    );
  }
}

/// Helper model containing the solved grid, puzzle grid, difficulty level, and variant info.
class SudokuPuzzle {
  final List<List<int>> solvedBoard;
  final List<List<int>> puzzleBoard;
  final Difficulty difficulty;
  final SudokuVariant variant;
  final List<KillerCage>? cages;

  SudokuPuzzle({
    required this.solvedBoard,
    required this.puzzleBoard,
    required this.difficulty,
    this.variant = SudokuVariant.standard,
    this.cages,
  });
}

