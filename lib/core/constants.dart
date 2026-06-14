/// Centralized game-wide constants.
class GameConstants {
  /// The size of the Sudoku board (9x9 grid).
  static const int boardSize = 9;

  /// The maximum size of the undo history stack to prevent memory issues.
  static const int maxUndoHistory = 20;

  /// The maximum number of mistakes allowed in classic mode before Game Over.
  static const int maxMistakes = 3;

  /// The maximum retry attempts allowed when generating a unique puzzle.
  static const int maxGenerationRetries = 5;

  /// Number of cells to remove for easy difficulty.
  static const int easyCellsToRemove = 49;

  /// Number of cells to remove for medium difficulty.
  static const int mediumCellsToRemove = 54;

  /// Number of cells to remove for hard difficulty.
  static const int hardCellsToRemove = 59;

  /// Number of particles used in the winning confetti overlay.
  static const int confettiParticleCount = 80;
}
