import 'package:flutter/foundation.dart';

/// Sudoku string & grid importer utility for custom grids.
class SudokuOCRScanner {
  /// Parses an 81-character SDK string (or formatted line with dots/zeros for blank cells).
  /// Example: "530070000600195000098000060800060003400803001700020006060000280000419005000080079"
  static List<List<int>>? parseSDKString(String input) {
    // Sanitize string (remove spaces, newlines, pipes)
    final clean = input.replaceAll(RegExp(r'[\s|+-]'), '');

    if (clean.length != 81) {
      return null;
    }

    final grid = List.generate(9, (_) => List.generate(9, (_) => 0));

    for (int i = 0; i < 81; i++) {
      final char = clean[i];
      final r = i ~/ 9;
      final c = i % 9;

      if (char == '.' || char == '0' || char == '*') {
        grid[r][c] = 0;
      } else {
        final val = int.tryParse(char);
        if (val != null && val >= 1 && val <= 9) {
          grid[r][c] = val;
        } else {
          return null; // Invalid character
        }
      }
    }

    return grid;
  }

  /// Exports a 9x9 grid to a standard 81-character SDK string.
  static String exportSDKString(List<List<int>> board) {
    final buffer = StringBuffer();
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final val = board[r][c];
        buffer.write(val == 0 ? '.' : val.toString());
      }
    }
    return buffer.toString();
  }
}
