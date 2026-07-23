import 'package:flutter/material.dart';
import '../../core/sudoku_logic.dart';
import '../../core/pdf_exporter.dart';
import '../../core/services/audio_service.dart';
import '../components/sudoku_grid.dart';
import '../components/numpad.dart';

/// Screen allowing players to design custom Sudoku boards, validate uniqueness, and export printable sheets.
class DesignerScreen extends StatefulWidget {
  const DesignerScreen({super.key});

  @override
  State<DesignerScreen> createState() => _DesignerScreenState();
}

class _DesignerScreenState extends State<DesignerScreen> {
  final List<List<int>> _grid = List.generate(9, (_) => List.filled(9, 0));
  int _selectedRow = 0;
  int _selectedCol = 0;

  bool _isValid = true;
  bool _hasUniqueSolution = false;
  String _statusMessage = 'Enter clues to test puzzle uniqueness.';

  @override
  void initState() {
    super.initState();
    _validateBoard();
  }

  void _validateBoard() {
    final valid = SudokuLogic.isBoardValid(_grid);
    if (!valid) {
      setState(() {
        _isValid = false;
        _hasUniqueSolution = false;
        _statusMessage = 'Rule Violation: Duplicate numbers in row, col, or box.';
      });
      return;
    }

    final clueCount = _grid.fold<int>(
      0,
      (sum, row) => sum + row.where((val) => val != 0).length,
    );

    if (clueCount < 17) {
      setState(() {
        _isValid = true;
        _hasUniqueSolution = false;
        _statusMessage = 'Need at least 17 clues for a unique Sudoku puzzle ($clueCount entered).';
      });
      return;
    }

    final unique = SudokuLogic.hasUniqueSolution(_grid);
    if (unique) {
      setState(() {
        _isValid = true;
        _hasUniqueSolution = true;
        _statusMessage = 'Valid Unique Sudoku Puzzle! Guaranteed 1 solution.';
      });
    } else {
      setState(() {
        _isValid = true;
        _hasUniqueSolution = false;
        _statusMessage = 'Multiple solutions possible. Add more clues to restrict solution.';
      });
    }
  }

  void _onNumberTap(int num) {
    AudioService.playNumberEnter();
    setState(() {
      _grid[_selectedRow][_selectedCol] = num;
    });
    _validateBoard();
  }

  void _onEraseTap() {
    AudioService.playCellSelect();
    setState(() {
      _grid[_selectedRow][_selectedCol] = 0;
    });
    _validateBoard();
  }

  void _clearBoard() {
    AudioService.playCellSelect();
    setState(() {
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          _grid[r][c] = 0;
        }
      }
    });
    _validateBoard();
  }

  void _exportPrintableSheet() {
    AudioService.playVictory();
    final List<List<int>> copy = List.generate(
      9,
      (r) => List<int>.from(_grid[r]),
    );
    SudokuLogic.solve(copy);

    final html = PdfExporter.generatePrintableHtml(
      board: _grid,
      solvedBoard: copy,
      title: 'Custom Designed Puzzle',
      difficulty: _hasUniqueSolution ? 'Unique Solution' : 'Custom Layout',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.print_rounded, color: Colors.indigo),
              SizedBox(width: 10),
              Text('Printable HTML Worksheet'),
            ],
          ),
          content: SingleChildScrollView(
            child: SelectableText(
              html,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Puzzle Designer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Export Printable Worksheet',
            onPressed: _exportPrintableSheet,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear Grid',
            onPressed: _clearBoard,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Uniqueness Status Card
              Card(
                elevation: 0,
                color: _hasUniqueSolution
                    ? Colors.green.withValues(alpha: 0.15)
                    : (!_isValid
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.secondaryContainer),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Icon(
                        _hasUniqueSolution
                            ? Icons.check_circle_rounded
                            : (!_isValid
                                ? Icons.warning_amber_rounded
                                : Icons.info_outline_rounded),
                        color: _hasUniqueSolution
                            ? Colors.green
                            : (!_isValid
                                ? theme.colorScheme.error
                                : theme.colorScheme.secondary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _hasUniqueSolution
                                ? Colors.green.shade800
                                : (!_isValid
                                    ? theme.colorScheme.onErrorContainer
                                    : theme.colorScheme.onSecondaryContainer),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sudoku Grid Canvas
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SudokuGrid(
                    board: _grid,
                    selectedRow: _selectedRow,
                    selectedCol: _selectedCol,
                    onCellTap: (r, c) {
                      AudioService.playCellSelect();
                      setState(() {
                        _selectedRow = r;
                        _selectedCol = c;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Controls & Numpad
              SudokuNumpad(
                onNumberTap: _onNumberTap,
                onEraseTap: _onEraseTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
