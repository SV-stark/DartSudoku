import 'dart:convert';

/// Analyzes board configurations to provide educational explanations for cell values.
class SudokuAnalyzer {
  /// Analyzes the selected empty cell (row, col) on [currentBoard] and returns
  /// a logical explanation of why [correctVal] is the correct number.
  static String analyzeCell(
    List<List<int>> currentBoard,
    int row,
    int col,
    int correctVal,
  ) {
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

    // Precalculate all candidates for empty cells
    final candidates = List.generate(9, (r) {
      return List.generate(9, (c) {
        if (currentBoard[r][c] != 0) return <int>{};
        final set = <int>{};
        for (int v = 1; v <= 9; v++) {
          if (isValidForAnalysis(currentBoard, r, c, v)) set.add(v);
        }
        return set;
      });
    });

    // Check for Locked Candidates (Pointing/Claiming), Naked Pairs, Hidden Pairs, X-Wings
    String? hint = _checkLockedCandidates(currentBoard, candidates, row, col) ??
        _checkNakedPairs(currentBoard, candidates, row, col) ??
        _checkHiddenPairs(currentBoard, candidates, row, col) ??
        _checkXWings(currentBoard, candidates, row, col);

    if (hint != null) {
      return hint;
    }

    // 5. Fallback for Advanced Heuristics
    return "Advanced Elimination\n\nThrough advanced logical exclusion of other combinations, placing $correctVal in this cell is the only placement that keeps the overall Sudoku board solvable.";
  }

  static String? _checkLockedCandidates(
    List<List<int>> board,
    List<List<Set<int>>> candidates,
    int targetRow,
    int targetCol,
  ) {
    // Pointing: check each box
    for (int b = 0; b < 9; b++) {
      final boxRowStart = (b ~/ 3) * 3;
      final boxColStart = (b % 3) * 3;

      for (int d = 1; d <= 9; d++) {
        final boxCells = <(int, int)>[];
        for (int r = boxRowStart; r < boxRowStart + 3; r++) {
          for (int c = boxColStart; c < boxColStart + 3; c++) {
            if (board[r][c] == 0 && candidates[r][c].contains(d)) {
              boxCells.add((r, c));
            }
          }
        }

        if (boxCells.length >= 2 && boxCells.length <= 3) {
          // Check if they share a row
          final sharedRow = boxCells.first.$1;
          bool allInRow = boxCells.every((cell) => cell.$1 == sharedRow);
          if (allInRow) {
            // Check if there are other cells in that row outside this box with candidate d
            bool hasExternalCandidates = false;
            for (int c = 0; c < 9; c++) {
              if ((c < boxColStart || c >= boxColStart + 3) &&
                  board[sharedRow][c] == 0 &&
                  candidates[sharedRow][c].contains(d)) {
                hasExternalCandidates = true;
                break;
              }
            }
            if (hasExternalCandidates) {
              final isTargetAffected = targetRow == sharedRow &&
                  (targetCol < boxColStart || targetCol >= boxColStart + 3) &&
                  candidates[targetRow][targetCol].contains(d);
              if (isTargetAffected) {
                return "Locked Candidate (Pointing Row)\n\nIn Box ${b + 1}, the number $d can only fit in Row ${sharedRow + 1}. Therefore, $d can be eliminated from all other cells in Row ${sharedRow + 1} outside this box.\n\nThis pointing pair/triple eliminates candidate $d from your selected cell!";
              }
            }
          }

          // Check if they share a column
          final sharedCol = boxCells.first.$2;
          bool allInCol = boxCells.every((cell) => cell.$2 == sharedCol);
          if (allInCol) {
            // Check if there are other cells in that column outside this box with candidate d
            bool hasExternalCandidates = false;
            for (int r = 0; r < 9; r++) {
              if ((r < boxRowStart || r >= boxRowStart + 3) &&
                  board[r][sharedCol] == 0 &&
                  candidates[r][sharedCol].contains(d)) {
                hasExternalCandidates = true;
                break;
              }
            }
            if (hasExternalCandidates) {
              final isTargetAffected = targetCol == sharedCol &&
                  (targetRow < boxRowStart || targetRow >= boxRowStart + 3) &&
                  candidates[targetRow][targetCol].contains(d);
              if (isTargetAffected) {
                return "Locked Candidate (Pointing Column)\n\nIn Box ${b + 1}, the number $d can only fit in Column ${sharedCol + 1}. Therefore, $d can be eliminated from all other cells in Column ${sharedCol + 1} outside this box.\n\nThis pointing pair/triple eliminates candidate $d from your selected cell!";
              }
            }
          }
        }
      }
    }

    // Claiming: check each row and column
    for (int r = 0; r < 9; r++) {
      for (int d = 1; d <= 9; d++) {
        final rowCells = <(int, int)>[];
        for (int c = 0; c < 9; c++) {
          if (board[r][c] == 0 && candidates[r][c].contains(d)) {
            rowCells.add((r, c));
          }
        }

        if (rowCells.length >= 2 && rowCells.length <= 3) {
          final firstBox = (rowCells.first.$1 ~/ 3) * 3 + (rowCells.first.$2 ~/ 3);
          bool allInBox = rowCells.every((cell) =>
              (cell.$1 ~/ 3) * 3 + (cell.$2 ~/ 3) == firstBox);

          if (allInBox) {
            // Check if there are other cells in this box outside this row with candidate d
            bool hasExternalCandidates = false;
            final boxRowStart = (firstBox ~/ 3) * 3;
            final boxColStart = (firstBox % 3) * 3;
            for (int br = boxRowStart; br < boxRowStart + 3; br++) {
              for (int bc = boxColStart; bc < boxColStart + 3; bc++) {
                if (br != r &&
                    board[br][bc] == 0 &&
                    candidates[br][bc].contains(d)) {
                  hasExternalCandidates = true;
                  break;
                }
              }
            }
            if (hasExternalCandidates) {
              final isTargetAffected =
                  (targetRow ~/ 3) * 3 + (targetCol ~/ 3) == firstBox &&
                      targetRow != r &&
                      candidates[targetRow][targetCol].contains(d);
              if (isTargetAffected) {
                return "Locked Candidate (Claiming Row)\n\nIn Row ${r + 1}, the number $d can only fit within Box ${firstBox + 1}. Therefore, $d can be eliminated from all other cells in Box ${firstBox + 1} outside this row.\n\nThis claiming constraint eliminates candidate $d from your selected cell!";
              }
            }
          }
        }
      }
    }

    for (int c = 0; c < 9; c++) {
      for (int d = 1; d <= 9; d++) {
        final colCells = <(int, int)>[];
        for (int r = 0; r < 9; r++) {
          if (board[r][c] == 0 && candidates[r][c].contains(d)) {
            colCells.add((r, c));
          }
        }

        if (colCells.length >= 2 && colCells.length <= 3) {
          final firstBox = (colCells.first.$1 ~/ 3) * 3 + (colCells.first.$2 ~/ 3);
          bool allInBox = colCells.every((cell) =>
              (cell.$1 ~/ 3) * 3 + (cell.$2 ~/ 3) == firstBox);

          if (allInBox) {
            // Check if there are other cells in this box outside this column with candidate d
            bool hasExternalCandidates = false;
            final boxRowStart = (firstBox ~/ 3) * 3;
            final boxColStart = (firstBox % 3) * 3;
            for (int br = boxRowStart; br < boxRowStart + 3; br++) {
              for (int bc = boxColStart; bc < boxColStart + 3; bc++) {
                if (bc != c &&
                    board[br][bc] == 0 &&
                    candidates[br][bc].contains(d)) {
                  hasExternalCandidates = true;
                  break;
                }
              }
            }
            if (hasExternalCandidates) {
              final isTargetAffected =
                  (targetRow ~/ 3) * 3 + (targetCol ~/ 3) == firstBox &&
                      targetCol != c &&
                      candidates[targetRow][targetCol].contains(d);
              if (isTargetAffected) {
                return "Locked Candidate (Claiming Column)\n\nIn Column ${c + 1}, the number $d can only fit within Box ${firstBox + 1}. Therefore, $d can be eliminated from all other cells in Box ${firstBox + 1} outside this column.\n\nThis claiming constraint eliminates candidate $d from your selected cell!";
              }
            }
          }
        }
      }
    }

    return null;
  }

  static String? _checkNakedPairs(
    List<List<int>> board,
    List<List<Set<int>>> candidates,
    int targetRow,
    int targetCol,
  ) {
    // Check rows
    for (int r = 0; r < 9; r++) {
      final pairCells = <(int, int), Set<int>>{};
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == 0 && candidates[r][c].length == 2) {
          pairCells[(r, c)] = candidates[r][c];
        }
      }

      final cellsList = pairCells.keys.toList();
      for (int i = 0; i < cellsList.length; i++) {
        for (int j = i + 1; j < cellsList.length; j++) {
          final c1 = cellsList[i];
          final c2 = cellsList[j];
          final s1 = pairCells[c1]!;
          final s2 = pairCells[c2]!;

          if (s1.length == 2 && s1.difference(s2).isEmpty) {
            // Found a Naked Pair! Check if it eliminates anything in the row
            final d1 = s1.first;
            final d2 = s1.last;
            bool eliminates = false;
            for (int c = 0; c < 9; c++) {
              if (c != c1.$2 && c != c2.$2 && board[r][c] == 0) {
                if (candidates[r][c].contains(d1) || candidates[r][c].contains(d2)) {
                  eliminates = true;
                  break;
                }
              }
            }

            if (eliminates) {
              final isTargetAffected = targetRow == r &&
                  targetCol != c1.$2 &&
                  targetCol != c2.$2 &&
                  (candidates[targetRow][targetCol].contains(d1) ||
                      candidates[targetRow][targetCol].contains(d2));
              if (isTargetAffected) {
                return "Naked Pair\n\nCells at Row ${r + 1} Col ${c1.$2 + 1} and Row ${r + 1} Col ${c2.$2 + 1} contain only the candidates {$d1, $d2}. These numbers are locked in these two cells, allowing you to eliminate them from other cells in Row ${r + 1}.\n\nThis Naked Pair eliminates candidates $d1 and $d2 from your selected cell!";
              }
            }
          }
        }
      }
    }

    // Check columns
    for (int c = 0; c < 9; c++) {
      final pairCells = <(int, int), Set<int>>{};
      for (int r = 0; r < 9; r++) {
        if (board[r][c] == 0 && candidates[r][c].length == 2) {
          pairCells[(r, c)] = candidates[r][c];
        }
      }

      final cellsList = pairCells.keys.toList();
      for (int i = 0; i < cellsList.length; i++) {
        for (int j = i + 1; j < cellsList.length; j++) {
          final c1 = cellsList[i];
          final c2 = cellsList[j];
          final s1 = pairCells[c1]!;
          final s2 = pairCells[c2]!;

          if (s1.length == 2 && s1.difference(s2).isEmpty) {
            final d1 = s1.first;
            final d2 = s1.last;
            bool eliminates = false;
            for (int r = 0; r < 9; r++) {
              if (r != c1.$1 && r != c2.$1 && board[r][c] == 0) {
                if (candidates[r][c].contains(d1) || candidates[r][c].contains(d2)) {
                  eliminates = true;
                  break;
                }
              }
            }

            if (eliminates) {
              final isTargetAffected = targetCol == c &&
                  targetRow != c1.$1 &&
                  targetRow != c2.$1 &&
                  (candidates[targetRow][targetCol].contains(d1) ||
                      candidates[targetRow][targetCol].contains(d2));
              if (isTargetAffected) {
                return "Naked Pair\n\nCells at Row ${c1.$1 + 1} Col ${c + 1} and Row ${c2.$1 + 1} Col ${c + 1} contain only the candidates {$d1, $d2}. These numbers are locked in these two cells, allowing you to eliminate them from other cells in Column ${c + 1}.\n\nThis Naked Pair eliminates candidates $d1 and $d2 from your selected cell!";
              }
            }
          }
        }
      }
    }

    // Check boxes
    for (int b = 0; b < 9; b++) {
      final boxRowStart = (b ~/ 3) * 3;
      final boxColStart = (b % 3) * 3;
      final pairCells = <(int, int), Set<int>>{};

      for (int r = boxRowStart; r < boxRowStart + 3; r++) {
        for (int c = boxColStart; c < boxColStart + 3; c++) {
          if (board[r][c] == 0 && candidates[r][c].length == 2) {
            pairCells[(r, c)] = candidates[r][c];
          }
        }
      }

      final cellsList = pairCells.keys.toList();
      for (int i = 0; i < cellsList.length; i++) {
        for (int j = i + 1; j < cellsList.length; j++) {
          final c1 = cellsList[i];
          final c2 = cellsList[j];
          final s1 = pairCells[c1]!;
          final s2 = pairCells[c2]!;

          if (s1.length == 2 && s1.difference(s2).isEmpty) {
            final d1 = s1.first;
            final d2 = s1.last;
            bool eliminates = false;
            for (int r = boxRowStart; r < boxRowStart + 3; r++) {
              for (int c = boxColStart; c < boxColStart + 3; c++) {
                if ((r != c1.$1 || c != c1.$2) && (r != c2.$1 || c != c2.$2) && board[r][c] == 0) {
                  if (candidates[r][c].contains(d1) || candidates[r][c].contains(d2)) {
                    eliminates = true;
                    break;
                  }
                }
              }
            }

            if (eliminates) {
              final targetBox = (targetRow ~/ 3) * 3 + (targetCol ~/ 3);
              final isTargetAffected = targetBox == b &&
                  (targetRow != c1.$1 || targetCol != c1.$2) &&
                  (targetRow != c2.$1 || targetCol != c2.$2) &&
                  (candidates[targetRow][targetCol].contains(d1) ||
                      candidates[targetRow][targetCol].contains(d2));
              if (isTargetAffected) {
                return "Naked Pair\n\nCells at Row ${c1.$1 + 1} Col ${c1.$2 + 1} and Row ${c2.$1 + 1} Col ${c2.$2 + 1} contain only the candidates {$d1, $d2}. These numbers are locked in these two cells, allowing you to eliminate them from other cells in Box ${b + 1}.\n\nThis Naked Pair eliminates candidates $d1 and $d2 from your selected cell!";
              }
            }
          }
        }
      }
    }

    return null;
  }

  static String? _checkHiddenPairs(
    List<List<int>> board,
    List<List<Set<int>>> candidates,
    int targetRow,
    int targetCol,
  ) {
    // Check rows
    for (int r = 0; r < 9; r++) {
      for (int d1 = 1; d1 <= 9; d1++) {
        for (int d2 = d1 + 1; d2 <= 9; d2++) {
          final cellsWithD1 = <int>[];
          final cellsWithD2 = <int>[];
          for (int c = 0; c < 9; c++) {
            if (board[r][c] == 0) {
              if (candidates[r][c].contains(d1)) cellsWithD1.add(c);
              if (candidates[r][c].contains(d2)) cellsWithD2.add(c);
            }
          }

          if (cellsWithD1.length == 2 &&
              cellsWithD2.length == 2 &&
              cellsWithD1[0] == cellsWithD2[0] &&
              cellsWithD1[1] == cellsWithD2[1]) {
            final c1 = cellsWithD1[0];
            final c2 = cellsWithD1[1];
            final extraInC1 = candidates[r][c1].length > 2;
            final extraInC2 = candidates[r][c2].length > 2;

            if (extraInC1 || extraInC2) {
              final isTargetAffected = targetRow == r &&
                  (targetCol == c1 || targetCol == c2) &&
                  candidates[targetRow][targetCol].length > 2;
              if (isTargetAffected) {
                return "Hidden Pair\n\nIn Row ${r + 1}, candidates $d1 and $d2 appear in only two cells: Col ${c1 + 1} and Col ${c2 + 1}. All other candidates can be eliminated from these two cells.\n\nThis Hidden Pair eliminates other candidates from your selected cell, leaving only {$d1, $d2}!";
              }
            }
          }
        }
      }
    }

    // Check columns
    for (int c = 0; c < 9; c++) {
      for (int d1 = 1; d1 <= 9; d1++) {
        for (int d2 = d1 + 1; d2 <= 9; d2++) {
          final cellsWithD1 = <int>[];
          final cellsWithD2 = <int>[];
          for (int r = 0; r < 9; r++) {
            if (board[r][c] == 0) {
              if (candidates[r][c].contains(d1)) cellsWithD1.add(r);
              if (candidates[r][c].contains(d2)) cellsWithD2.add(r);
            }
          }

          if (cellsWithD1.length == 2 &&
              cellsWithD2.length == 2 &&
              cellsWithD1[0] == cellsWithD2[0] &&
              cellsWithD1[1] == cellsWithD2[1]) {
            final r1 = cellsWithD1[0];
            final r2 = cellsWithD1[1];
            final extraInR1 = candidates[r1][c].length > 2;
            final extraInR2 = candidates[r2][c].length > 2;

            if (extraInR1 || extraInR2) {
              final isTargetAffected = targetCol == c &&
                  (targetRow == r1 || targetRow == r2) &&
                  candidates[targetRow][targetCol].length > 2;
              if (isTargetAffected) {
                return "Hidden Pair\n\nIn Column ${c + 1}, candidates $d1 and $d2 appear in only two cells: Row ${r1 + 1} and Row ${r2 + 1}. All other candidates can be eliminated from these two cells.\n\nThis Hidden Pair eliminates other candidates from your selected cell, leaving only {$d1, $d2}!";
              }
            }
          }
        }
      }
    }

    // Check boxes
    for (int b = 0; b < 9; b++) {
      final boxRowStart = (b ~/ 3) * 3;
      final boxColStart = (b % 3) * 3;

      for (int d1 = 1; d1 <= 9; d1++) {
        for (int d2 = d1 + 1; d2 <= 9; d2++) {
          final cellsWithD1 = <(int, int)>[];
          final cellsWithD2 = <(int, int)>[];

          for (int r = boxRowStart; r < boxRowStart + 3; r++) {
            for (int c = boxColStart; c < boxColStart + 3; c++) {
              if (board[r][c] == 0) {
                if (candidates[r][c].contains(d1)) cellsWithD1.add((r, c));
                if (candidates[r][c].contains(d2)) cellsWithD2.add((r, c));
              }
            }
          }

          if (cellsWithD1.length == 2 &&
              cellsWithD2.length == 2 &&
              cellsWithD1[0] == cellsWithD2[0] &&
              cellsWithD1[1] == cellsWithD2[1]) {
            final c1 = cellsWithD1[0];
            final c2 = cellsWithD1[1];
            final extraInC1 = candidates[c1.$1][c1.$2].length > 2;
            final extraInC2 = candidates[c2.$1][c2.$2].length > 2;

            if (extraInC1 || extraInC2) {
              final isTargetAffected = ((targetRow == c1.$1 && targetCol == c1.$2) ||
                      (targetRow == c2.$1 && targetCol == c2.$2)) &&
                  candidates[targetRow][targetCol].length > 2;
              if (isTargetAffected) {
                return "Hidden Pair\n\nIn Box ${b + 1}, candidates $d1 and $d2 appear in only two cells: Row ${c1.$1 + 1} Col ${c1.$2 + 1} and Row ${c2.$1 + 1} Col ${c2.$2 + 1}. All other candidates can be eliminated from these two cells.\n\nThis Hidden Pair eliminates other candidates from your selected cell, leaving only {$d1, $d2}!";
              }
            }
          }
        }
      }
    }

    return null;
  }

  static String? _checkXWings(
    List<List<int>> board,
    List<List<Set<int>>> candidates,
    int targetRow,
    int targetCol,
  ) {
    // Row-based X-Wing
    for (int d = 1; d <= 9; d++) {
      for (int r1 = 0; r1 < 9; r1++) {
        for (int r2 = r1 + 1; r2 < 9; r2++) {
          final cols1 = <int>[];
          final cols2 = <int>[];

          for (int c = 0; c < 9; c++) {
            if (board[r1][c] == 0 && candidates[r1][c].contains(d)) cols1.add(c);
            if (board[r2][c] == 0 && candidates[r2][c].contains(d)) cols2.add(c);
          }

          if (cols1.length == 2 && cols2.length == 2 && cols1[0] == cols2[0] && cols1[1] == cols2[1]) {
            final c1 = cols1[0];
            final c2 = cols1[1];

            // Check if it eliminates d from columns c1 or c2 outside r1 and r2
            bool eliminates = false;
            for (int r = 0; r < 9; r++) {
              if (r != r1 && r != r2) {
                if ((board[r][c1] == 0 && candidates[r][c1].contains(d)) ||
                    (board[r][c2] == 0 && candidates[r][c2].contains(d))) {
                  eliminates = true;
                  break;
                }
              }
            }

            if (eliminates) {
              final isTargetAffected = (targetCol == c1 || targetCol == c2) &&
                  targetRow != r1 &&
                  targetRow != r2 &&
                  candidates[targetRow][targetCol].contains(d);
              if (isTargetAffected) {
                return "X-Wing\n\nCandidate $d is restricted to columns ${c1 + 1} and ${c2 + 1} in rows ${r1 + 1} and ${r2 + 1}. This eliminates $d from all other cells in columns ${c1 + 1} and ${c2 + 1}.\n\nThis X-Wing eliminates candidate $d from your selected cell!";
              }
            }
          }
        }
      }
    }

    // Column-based X-Wing
    for (int d = 1; d <= 9; d++) {
      for (int c1 = 0; c1 < 9; c1++) {
        for (int c2 = c1 + 1; c2 < 9; c2++) {
          final rows1 = <int>[];
          final rows2 = <int>[];

          for (int r = 0; r < 9; r++) {
            if (board[r][c1] == 0 && candidates[r][c1].contains(d)) rows1.add(r);
            if (board[r][c2] == 0 && candidates[r][c2].contains(d)) rows2.add(r);
          }

          if (rows1.length == 2 && rows2.length == 2 && rows1[0] == rows2[0] && rows1[1] == rows2[1]) {
            final r1 = rows1[0];
            final r2 = rows1[1];

            // Check if it eliminates d from rows r1 or r2 outside c1 and c2
            bool eliminates = false;
            for (int c = 0; c < 9; c++) {
              if (c != c1 && c != c2) {
                if ((board[r1][c] == 0 && candidates[r1][c].contains(d)) ||
                    (board[r2][c] == 0 && candidates[r2][c].contains(d))) {
                  eliminates = true;
                  break;
                }
              }
            }

            if (eliminates) {
              final isTargetAffected = (targetRow == r1 || targetRow == r2) &&
                  targetCol != c1 &&
                  targetCol != c2 &&
                  candidates[targetRow][targetCol].contains(d);
              if (isTargetAffected) {
                return "X-Wing\n\nCandidate $d is restricted to rows ${r1 + 1} and ${r2 + 1} in columns ${c1 + 1} and ${c2 + 1}. This eliminates $d from all other cells in rows ${r1 + 1} and ${r2 + 1}.\n\nThis X-Wing eliminates candidate $d from your selected cell!";
              }
            }
          }
        }
      }
    }

    return null;
  }

  /// Helper to check if val is valid in currentBoard at (row, col) ignoring the cell's current value
  static bool isValidForAnalysis(
    List<List<int>> board,
    int row,
    int col,
    int val,
  ) {
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
