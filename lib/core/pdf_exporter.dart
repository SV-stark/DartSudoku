/// Formatted printable worksheet generator for Sudoku puzzles.
class PdfExporter {
  /// Generates a styled HTML/SVG printable document containing the 9x9 grid, title, and answer key.
  static String generatePrintableHtml({
    required List<List<int>> board,
    required List<List<int>> solvedBoard,
    required String title,
    required String difficulty,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="utf-8">');
    buffer.writeln('<title>$title - DartSudoku Printable Worksheet</title>');
    buffer.writeln('<style>');
    buffer.writeln('body { font-family: "Segoe UI", Roboto, Helvetica, Arial, sans-serif; text-align: center; color: #1a1a1a; padding: 20px; }');
    buffer.writeln('h1 { margin-bottom: 4px; font-size: 28px; }');
    buffer.writeln('.subtitle { font-size: 14px; color: #555; margin-bottom: 24px; letter-spacing: 2px; text-transform: uppercase; }');
    buffer.writeln('.grid-container { display: inline-block; border: 3px solid #111; border-radius: 8px; overflow: hidden; background: #fff; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }');
    buffer.writeln('table { border-collapse: collapse; }');
    buffer.writeln('td { width: 48px; height: 48px; text-align: center; vertical-align: middle; font-size: 22px; font-weight: bold; border: 1px solid #ccc; }');
    buffer.writeln('.thick-bottom { border-bottom: 3px solid #111 !important; }');
    buffer.writeln('.thick-right { border-right: 3px solid #111 !important; }');
    buffer.writeln('.clue { color: #111; }');
    buffer.writeln('.empty { color: transparent; }');
    buffer.writeln('.solution-section { margin-top: 40px; page-break-before: always; }');
    buffer.writeln('@media print { button { display: none; } }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('<button onclick="window.print()" style="padding:10px 24px; font-size:16px; font-weight:bold; background:#4f46e5; color:#fff; border:none; border-radius:8px; cursor:pointer; margin-bottom:20px;">PRINT WORKSHEET</button>');
    buffer.writeln('<h1>🌌 DartSudoku</h1>');
    buffer.writeln('<div class="subtitle">$title • $difficulty</div>');

    // Puzzle Grid
    buffer.writeln('<div class="grid-container">');
    buffer.writeln('<table>');
    for (int r = 0; r < 9; r++) {
      buffer.writeln('<tr>');
      for (int c = 0; c < 9; c++) {
        final val = board[r][c];
        final classes = <String>[];
        if (r % 3 == 2 && r != 8) classes.add('thick-bottom');
        if (c % 3 == 2 && c != 8) classes.add('thick-right');
        final classAttr = classes.isNotEmpty ? ' class="${classes.join(' ')}"' : '';

        buffer.write('<td$classAttr>');
        if (val != 0) {
          buffer.write('<span class="clue">$val</span>');
        } else {
          buffer.write('&nbsp;');
        }
        buffer.writeln('</td>');
      }
      buffer.writeln('</tr>');
    }
    buffer.writeln('</table>');
    buffer.writeln('</div>');

    // Folded Answer Key
    buffer.writeln('<div class="solution-section">');
    buffer.writeln('<h2>Solution Key</h2>');
    buffer.writeln('<div class="grid-container" style="transform: scale(0.85);">');
    buffer.writeln('<table>');
    for (int r = 0; r < 9; r++) {
      buffer.writeln('<tr>');
      for (int c = 0; c < 9; c++) {
        final val = solvedBoard[r][c];
        final isOriginal = board[r][c] != 0;
        final classes = <String>[];
        if (r % 3 == 2 && r != 8) classes.add('thick-bottom');
        if (c % 3 == 2 && c != 8) classes.add('thick-right');
        final classAttr = classes.isNotEmpty ? ' class="${classes.join(' ')}"' : '';

        buffer.write('<td$classAttr style="${isOriginal ? 'background:#f3f4f6;' : 'color:#4f46e5;'}">');
        buffer.write('$val');
        buffer.writeln('</td>');
      }
      buffer.writeln('</tr>');
    }
    buffer.writeln('</table>');
    buffer.writeln('</div>');
    buffer.writeln('</div>');

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }
}
