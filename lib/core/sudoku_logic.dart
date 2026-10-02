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

/// O(1) lookup index for Killer cages.
///
/// Building this once and passing it into the solver avoids the linear
/// `cages.firstWhere(...)` scan that previously ran for *every* candidate
/// value tested during search — the single hottest path in the app.
class KillerCageIndex {
  final List<KillerCage> cages;
  final Map<int, KillerCage> _byCell;

  KillerCageIndex(List<KillerCage>? cages)
      : cages = cages ?? const <KillerCage>[],
        _byCell = <int, KillerCage>{} {
    for (final cage in this.cages) {
      for (final p in cage.cells) {
        if (p.x < 0 ||
            p.x >= GameConstants.boardSize ||
            p.y < 0 ||
            p.y >= GameConstants.boardSize) {
          continue; // Ignore out-of-bounds coordinates from corrupt saves.
        }
        // First cage wins: earlier definitions take precedence.
        _byCell.putIfAbsent(p.x * GameConstants.boardSize + p.y, () => cage);
      }
    }
  }

  bool get isEmpty => _byCell.isEmpty;

  int get cellCount => _byCell.length;

  KillerCage? cageAt(int row, int col) =>
      _byCell[row * GameConstants.boardSize + col];
}

/// Representation and core logic for Sudoku operations.
class SudokuLogic {
  /// Check if placing [val] at board[[row]][[col]] is valid according to Sudoku rules and [variant].
  ///
  /// Pass a pre-built [cageIndex] (together with, or instead of, [cages]) when
  /// validating many cells in a row to avoid rebuilding the index each call.
  static bool isValid(
    List<List<int>> board,
    int row,
    int col,
    int val, {
    SudokuVariant variant = SudokuVariant.standard,
    List<KillerCage>? cages,
    KillerCageIndex? cageIndex,
  }) {
    if (val == 0) return false;

    // Check row for duplicates
    for (int c = 0; c < GameConstants.boardSize; c++) {
      if (c != col && board[row][c] == val) return false;
    }

    // Check column for duplicates
    for (int r = 0; r < GameConstants.boardSize; r++) {
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
        for (int i = 0; i < GameConstants.boardSize; i++) {
          if (i != row && board[i][i] == val) return false;
        }
      }
      if (row + col == GameConstants.boardSize - 1) {
        for (int i = 0; i < GameConstants.boardSize; i++) {
          if (i != row && board[i][GameConstants.boardSize - 1 - i] == val) {
            return false;
          }
        }
      }
    }

    // Killer Sudoku cage validation
    if (variant == SudokuVariant.killer) {
      final KillerCage? cage;
      if (cageIndex != null) {
        cage = cageIndex.cageAt(row, col);
      } else if (cages != null && cages.isNotEmpty) {
        cage = cages.firstWhere(
          (c) => c.containsCell(row, col),
          orElse: () => _noCage,
        );
      } else {
        cage = null;
      }

      if (cage != null) {
        int currentSum = val;
        int emptyCount = 0;
        for (var p in cage.cells) {
          if (p.x == row && p.y == col) continue;
          final cellVal = board[p.x][p.y];
          if (cellVal != 0) {
            if (cellVal == val) return false; // Duplicate digit inside cage.
            currentSum += cellVal;
          } else {
            emptyCount++;
          }
        }
        // A cage can never hold the same digit twice, so each remaining empty
        // cell contributes between 1 and 9.
        if (currentSum > cage.targetSum) return false;
        if (currentSum + emptyCount * GameConstants.boardSize <
            cage.targetSum) {
          return false;
        }
        if (emptyCount == 0 && currentSum != cage.targetSum) return false;
      }
    }

    return true;
  }

  static const KillerCage _noCage =
      KillerCage(id: -1, cells: <Point<int>>[], targetSum: 0);

  /// Check if the entire board layout is valid, ensuring no rule violations.
  /// This is used to validate custom boards before solving.
  static bool isBoardValid(
    List<List<int>> board, {
    SudokuVariant variant = SudokuVariant.standard,
    List<KillerCage>? cages,
  }) {
    if (board.length != GameConstants.boardSize) return false;
    for (final row in board) {
      if (row.length != GameConstants.boardSize) return false;
    }

    final index = KillerCageIndex(cages);
    for (int r = 0; r < GameConstants.boardSize; r++) {
      for (int c = 0; c < GameConstants.boardSize; c++) {
        int val = board[r][c];
        if (val == 0) continue;
        if (val < 1 || val > GameConstants.boardSize) return false;
        if (!isValid(board, r, c, val,
            variant: variant, cages: cages, cageIndex: index)) {
          return false;
        }
      }
    }

    // Fully filled boards must also respect Killer cage totals.
    if (variant == SudokuVariant.killer && !index.isEmpty) {
      if (!areCagesSatisfied(board, index)) return false;
    }
    return true;
  }

  /// Verifies every cage in [index] is completely filled and sums to its target.
  static bool areCagesSatisfied(List<List<int>> board, KillerCageIndex index) {
    for (final cage in index.cages) {
      int sum = 0;
      for (final p in cage.cells) {
        if (p.x < 0 ||
            p.x >= GameConstants.boardSize ||
            p.y < 0 ||
            p.y >= GameConstants.boardSize) {
          return false;
        }
        final v = board[p.x][p.y];
        if (v == 0) return false; // Not completely filled yet.
        sum += v;
      }
      if (sum != cage.targetSum) return false;
    }
    return true;
  }

  /// Picks the empty cell with the fewest legal candidates (MRV heuristic).
  ///
  /// Returns `null` when the board has no empty cells. Returns a cell whose
  /// candidate list is empty (count `0`) when the position is dead — the caller
  /// must treat that as a failure of this branch.
  static _MrvCell? _selectMrvCell(
    List<List<int>> board, {
    required SudokuVariant variant,
    List<KillerCage>? cages,
    KillerCageIndex? cageIndex,
  }) {
    int bestRow = -1;
    int bestCol = -1;
    int minOptions = GameConstants.boardSize + 1;

    for (int r = 0; r < GameConstants.boardSize; r++) {
      for (int c = 0; c < GameConstants.boardSize; c++) {
        if (board[r][c] != 0) continue;
        int options = 0;
        for (int val = 1; val <= GameConstants.boardSize; val++) {
          if (isValid(board, r, c, val,
              variant: variant, cages: cages, cageIndex: cageIndex)) {
            options++;
          }
        }
        if (options < minOptions) {
          minOptions = options;
          bestRow = r;
          bestCol = c;
          // A cell with a single candidate is optimal; stop scanning early.
          if (options <= 1) return _MrvCell(bestRow, bestCol, options);
        }
      }
    }

    if (bestRow == -1) return null;
    return _MrvCell(bestRow, bestCol, minOptions);
  }

  /// Solves the Sudoku board in-place.
  /// Returns true if a solution is found, false if unsolvable.
  static bool solve(
    List<List<int>> board, {
    SudokuVariant variant = SudokuVariant.standard,
    List<KillerCage>? cages,
  }) {
    final index = variant == SudokuVariant.killer ? KillerCageIndex(cages) : null;

    final cell = _selectMrvCell(
      board,
      variant: variant,
      cages: cages,
      cageIndex: index,
    );
    if (cell == null) return true; // No empty cells, board solved.
    if (cell.options == 0) return false; // Dead end: no legal candidate.

    for (int val = 1; val <= GameConstants.boardSize; val++) {
      if (isValid(board, cell.row, cell.col, val,
          variant: variant, cages: cages, cageIndex: index)) {
        board[cell.row][cell.col] = val;
        if (solve(board, variant: variant, cages: cages)) return true;
        board[cell.row][cell.col] = 0; // Backtrack
      }
    }

    return false;
  }

  /// Creates a deep copy of a 2D grid.
  static List<List<int>> copyBoard(List<List<int>> board) {
    return List.generate(
      board.length,
      (r) => List<int>.from(board[r]),
      growable: false,
    );
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

    final index = variant == SudokuVariant.killer ? KillerCageIndex(cages) : null;

    final cell = _selectMrvCell(
      board,
      variant: variant,
      cages: cages,
      cageIndex: index,
    );
    if (cell == null) return count + 1; // Solution found.
    if (cell.options == 0) return count; // Dead end.

    for (int val = 1; val <= GameConstants.boardSize; val++) {
      if (isValid(board, cell.row, cell.col, val,
          variant: variant, cages: cages, cageIndex: index)) {
        board[cell.row][cell.col] = val;
        count = _countSolutions(
          board,
          limit,
          count: count,
          variant: variant,
          cages: cages,
        );
        board[cell.row][cell.col] = 0; // Backtrack
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
    if (!isBoardValid(board, variant: variant, cages: cages)) return false;
    var temp = copyBoard(board);
    return _countSolutions(temp, 2, variant: variant, cages: cages) == 1;
  }

  /// Public helper: number of solutions found, stopping once [limit] is reached.
  /// Useful for diagnostics ("this puzzle has 3 solutions").
  static int countSolutions(
    List<List<int>> board, {
    int limit = 2,
    SudokuVariant variant = SudokuVariant.standard,
    List<KillerCage>? cages,
  }) {
    if (!isBoardValid(board, variant: variant, cages: cages)) return 0;
    return _countSolutions(
      copyBoard(board),
      limit,
      variant: variant,
      cages: cages,
    );
  }

  /// Generates default sample Killer cages for a solved board.
  ///
  /// The layout is deterministic: cells are consumed in row-major order into
  /// cages of 1-3 cells that never overlap. A cage is only accepted when the
  /// digits it contains are all distinct, which is what makes the cage sums a
  /// meaningful constraint rather than decoration.
  static List<KillerCage> generateDefaultCages(List<List<int>> solvedBoard) {
    List<KillerCage> cages = [];
    int cageId = 1;
    final boolSet = List.generate(
      GameConstants.boardSize,
      (_) => List.filled(GameConstants.boardSize, false),
    );

    // Preferred cage shapes, tried in order so cages get varied sizes.
    const List<int> sizes = [2, 3, 1, 2, 3, 2];

    for (int r = 0; r < GameConstants.boardSize; r++) {
      for (int c = 0; c < GameConstants.boardSize; c++) {
        if (boolSet[r][c]) continue;

        final shapeIndex = (cageId - 1) % sizes.length;
        final targetSize = sizes[shapeIndex];

        final cells = <Point<int>>[];
        final usedDigits = <int>{};

        // Horizontal neighbours first.
        for (int cc = c; cc < GameConstants.boardSize && cells.length < targetSize; cc++) {
          if (boolSet[r][cc]) break;
          final d = solvedBoard[r][cc];
          if (!usedDigits.add(d)) continue;
          cells.add(Point(r, cc));
        }

        // Then vertical neighbours of the anchor cell.
        if (cells.length < targetSize && cells.isNotEmpty) {
          final anchor = cells.first;
          for (int rr = anchor.x + 1;
              rr < GameConstants.boardSize && cells.length < targetSize;
              rr++) {
            if (boolSet[rr][anchor.y]) continue;
            final d = solvedBoard[rr][anchor.y];
            if (!usedDigits.add(d)) continue;
            cells.add(Point(rr, anchor.y));
          }
        }

        for (final p in cells) {
          boolSet[p.x][p.y] = true;
        }

        final targetSum =
            cells.fold<int>(0, (sum, p) => sum + solvedBoard[p.x][p.y]);
        cages.add(KillerCage(id: cageId++, cells: cells, targetSum: targetSum));
      }
    }
    return cages;
  }

  /// Validates that [cages] fully and correctly describes [solvedBoard]:
  /// every board cell belongs to exactly one cage and each cage's digits are
  /// distinct and sum to the declared target.
  static bool isCageConfigurationValid(
    List<KillerCage> cages,
    List<List<int>> solvedBoard,
  ) {
    final cells = GameConstants.boardSize * GameConstants.boardSize;
    final seen = List<bool>.filled(cells, false);

    for (final cage in cages) {
      if (cage.cells.isEmpty) return false;
      final digits = <int>{};
      for (final p in cage.cells) {
        if (p.x < 0 ||
            p.x >= GameConstants.boardSize ||
            p.y < 0 ||
            p.y >= GameConstants.boardSize) {
          return false;
        }
        final flat = p.x * GameConstants.boardSize + p.y;
        if (seen[flat]) return false; // Overlapping cages.
        seen[flat] = true;
        if (!digits.add(solvedBoard[p.x][p.y])) return false;
      }
      final sum = digits.fold<int>(0, (a, b) => a + b);
      if (sum != cage.targetSum) return false;
    }

    return seen.every((v) => v);
  }

  /// Generates a fully solved Sudoku board.
  static List<List<int>> generateSolvedBoard({
    Random? random,
    SudokuVariant variant = SudokuVariant.standard,
  }) {
    final size = GameConstants.boardSize;

    // Retry from scratch rather than recursing forever on an unlucky path.
    for (int attempt = 0; attempt < GameConstants.maxGenerationRetries; attempt++) {
      final candidate = List.generate(size, (_) => List.filled(size, 0));
      if (_fillBoardRandomly(candidate, random: random, variant: variant)) {
        return candidate;
      }
    }

    // Extremely unlikely fallback: seed a valid base grid and permute digits.
    return _baseSolution(random: random, variant: variant);
  }

  /// Deterministic seed grid (classic pattern) with shuffled digits, rows and
  /// columns, used only as a last-resort fallback so generation can never
  /// return an empty board.
  ///
  /// Permuting digits and re-ordering rows *within* a band / columns *within* a
  /// stack both preserve standard Sudoku validity, so any combination of those
  /// three shuffles is a legal solved grid.
  static List<List<int>> _baseSolution({
    Random? random,
    SudokuVariant variant = SudokuVariant.standard,
  }) {
    const size = 9;
    const pattern = [
      [5, 3, 4, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9],
    ];

    List<int> bandShuffle() {
      final order = List<int>.generate(size, (i) => i);
      for (int band = 0; band < size; band += 3) {
        final slice = order.sublist(band, band + 3)..shuffle(random);
        for (int i = 0; i < 3; i++) {
          order[band + i] = slice[i];
        }
      }
      return order;
    }

    final grid = List.generate(size, (_) => List.filled(size, 0));

    for (int attempt = 0; attempt < 4000; attempt++) {
      final rows = bandShuffle();
      final cols = bandShuffle();
      final digitMap = List<int>.generate(size, (i) => i + 1)..shuffle(random);

      for (int r = 0; r < size; r++) {
        for (int c = 0; c < size; c++) {
          grid[r][c] = digitMap[pattern[rows[r]][cols[c]] - 1];
        }
      }

      if (variant != SudokuVariant.diagonalX || _hasDistinctDiagonals(grid)) {
        return grid;
      }
    }

    // Identity fallback is not diagonal-safe, so keep the first attempt's grid
    // only if nothing better was found; standard variants already returned
    // above on the very first pass.
    return grid;
  }

  static bool _hasDistinctDiagonals(List<List<int>> grid) {
    const size = 9;
    final main = <int>{};
    final anti = <int>{};
    for (int i = 0; i < size; i++) {
      main.add(grid[i][i]);
      anti.add(grid[i][size - 1 - i]);
    }
    return main.length == size && anti.length == size;
  }

  static bool _fillBoardRandomly(
    List<List<int>> board, {
    Random? random,
    SudokuVariant variant = SudokuVariant.standard,
  }) {
    final size = GameConstants.boardSize;

    final cell = _selectMrvCell(board, variant: variant);
    if (cell == null) return true; // Board complete.
    if (cell.options == 0) return false; // Dead end.

    final numbers = List<int>.generate(size, (i) => i + 1)..shuffle(random);
    for (int val in numbers) {
      if (isValid(board, cell.row, cell.col, val, variant: variant)) {
        board[cell.row][cell.col] = val;
        if (_fillBoardRandomly(board, random: random, variant: variant)) {
          return true;
        }
        board[cell.row][cell.col] = 0; // Backtrack
      }
    }
    return false;
  }

  /// Number of clue cells a puzzle of [difficulty] should aim to leave.
  static int cellsToRemoveFor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return GameConstants.easyCellsToRemove;
      case Difficulty.medium:
        return GameConstants.mediumCellsToRemove;
      case Difficulty.hard:
        return GameConstants.hardCellsToRemove;
    }
  }

  /// Generates a Sudoku game with a unique solution according to [difficulty]
  /// and [variant].
  ///
  /// Each attempt carves clues out of a freshly generated solution board and
  /// only keeps a removal when the puzzle still has exactly one solution. If no
  /// attempt reaches the target removal count, the *closest* attempt is
  /// returned instead of an arbitrarily bad one.
  static SudokuPuzzle generatePuzzle(
    Difficulty difficulty, {
    int? seed,
    SudokuVariant variant = SudokuVariant.standard,
  }) {
    final random = seed != null ? Random(seed) : Random();
    final cellsToRemove = cellsToRemoveFor(difficulty);
    final size = GameConstants.boardSize;

    SudokuPuzzle? best;
    int bestRemoved = -1;

    // Every attempt must produce a usable board, otherwise there is nothing to
    // return. This guards against a pathological random stream.
    final fallbackSolved = generateSolvedBoard(random: random, variant: variant);

    for (int attempt = 0;
        attempt < GameConstants.maxGenerationRetries;
        attempt++) {
      final solved = generateSolvedBoard(random: random, variant: variant);
      final puzzle = copyBoard(solved);

      List<KillerCage>? cages;
      if (variant == SudokuVariant.killer) {
        cages = generateDefaultCages(solved);
        if (!isCageConfigurationValid(cages, solved)) {
          continue; // Generated layout is unusable; retry.
        }
      }

      // Coordinates to try removing, in random order.
      final coordinates = <Point<int>>[
        for (int r = 0; r < size; r++)
          for (int c = 0; c < size; c++) Point(r, c),
      ]..shuffle(random);

      int removed = 0;
      for (final point in coordinates) {
        if (removed >= cellsToRemove) break;

        final r = point.x;
        final c = point.y;
        final backup = puzzle[r][c];

        puzzle[r][c] = 0;

        // Keep the removal only if the puzzle still has a unique solution.
        if (hasUniqueSolution(puzzle, variant: variant, cages: cages)) {
          removed++;
        } else {
          puzzle[r][c] = backup; // Revert: removal broke uniqueness.
        }
      }

      if (removed > bestRemoved) {
        bestRemoved = removed;
        best = SudokuPuzzle(
          solvedBoard: solved,
          puzzleBoard: puzzle,
          difficulty: difficulty,
          variant: variant,
          cages: cages,
        );
      }

      // Accept this attempt if it hit (or came within one of) the target.
      if (removed >= cellsToRemove - 1) return best!;
    }

    // None of the attempts fully converged; return the best one found, or an
    // untouched solved board so callers never receive an empty puzzle.
    return best ??
        SudokuPuzzle(
          solvedBoard: fallbackSolved,
          puzzleBoard: copyBoard(fallbackSolved),
          difficulty: difficulty,
          variant: variant,
          cages: null,
        );
  }
}

/// Result of the MRV heuristic: an empty cell plus how many values fit there.
class _MrvCell {
  final int row;
  final int col;
  final int options;

  const _MrvCell(this.row, this.col, this.options);
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

