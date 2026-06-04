/// Analyzes board configurations to provide educational explanations for cell values.
class SudokuAnalyzer {
  /// Analyzes the selected empty cell (row, col) on [currentBoard] and returns
  /// a logical explanation of why [correctVal] is the correct number.
  static String analyzeCell(List<List<int>> currentBoard, int row, int col, int correctVal) {
    // 1. Check for Sole Candidate (Naked Single)
    List<int> validCandidates = [];
    for (int val = 1; val <= 9; val++) {
      if (isValidForAnalysis(currentBoard, row, col, val)) {
        validCandidates.add(val);
      }
    }
    if (validCandidates.length == 1 && validCandidates.first == correctVal) {
      return "Sole Candidate (Naked Single)\n\nThis cell has only one possible candidate number left ($correctVal). All other numbers 1-9 are already present in its row, column, or 3x3 block.";
    }

    // 2. Check for Hidden Single in Row
    bool isUniqueInRow = true;
    for (int c = 0; c < 9; c++) {
      if (c != col && currentBoard[row][c] == 0) {
        if (isValidForAnalysis(currentBoard, row, c, correctVal)) {
          isUniqueInRow = false;
          break;
        }
      }
    }
    if (isUniqueInRow) {
      return "Hidden Single in Row\n\nIn this row, this cell is the only place where the number $correctVal can fit. All other empty cells in this row are blocked by conflicts with their respective columns or 3x3 blocks.";
    }

    // 3. Check for Hidden Single in Column
    bool isUniqueInCol = true;
    for (int r = 0; r < 9; r++) {
      if (r != row && currentBoard[r][col] == 0) {
        if (isValidForAnalysis(currentBoard, r, col, correctVal)) {
          isUniqueInCol = false;
          break;
        }
      }
    }
    if (isUniqueInCol) {
      return "Hidden Single in Column\n\nIn this column, this cell is the only place where the number $correctVal can fit. All other empty cells in this column are blocked by conflicts with their respective rows or 3x3 blocks.";
    }

    // 4. Check for Hidden Single in 3x3 Box
    bool isUniqueInBox = true;
    int boxRowStart = row - row % 3;
    int boxColStart = col - col % 3;
    for (int r = boxRowStart; r < boxRowStart + 3; r++) {
      for (int c = boxColStart; c < boxColStart + 3; c++) {
        if ((r != row || c != col) && currentBoard[r][c] == 0) {
          if (isValidForAnalysis(currentBoard, r, c, correctVal)) {
            isUniqueInBox = false;
            break;
          }
        }
      }
    }
    if (isUniqueInBox) {
      return "Hidden Single in Block\n\nIn this 3x3 block, this cell is the only place where the number $correctVal can fit. All other empty cells in this block are blocked by conflicts with their respective rows or columns.";
    }

    // 5. Fallback for Advanced Heuristics
    return "Advanced Elimination\n\nThrough advanced logical exclusion of other combinations, placing $correctVal in this cell is the only placement that keeps the overall Sudoku board solvable.";
  }

  /// Helper to check if val is valid in currentBoard at (row, col) ignoring the cell's current value
  static bool isValidForAnalysis(List<List<int>> board, int row, int col, int val) {
    // Check row
    for (int c = 0; c < 9; c++) {
      if (c != col && board[row][c] == val) return false;
    }
    // Check col
    for (int r = 0; r < 9; r++) {
      if (r != row && board[r][col] == val) return false;
    }
    // Check box
    int boxRowStart = row - row % 3;
    int boxColStart = col - col % 3;
    for (int r = boxRowStart; r < boxRowStart + 3; r++) {
      for (int c = boxColStart; c < boxColStart + 3; c++) {
        if ((r != row || c != col) && board[r][c] == val) return false;
      }
    }
    return true;
  }
}
