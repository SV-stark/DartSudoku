import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/sudoku_logic.dart';
import '../../core/pdf_exporter.dart';
import '../../core/services/audio_service.dart';
import '../../core/constants.dart';
import '../components/sudoku_grid.dart';
import '../components/numpad.dart';
import '../components/custom_answers_dialog.dart';

/// Screen allowing players to design custom Sudoku boards, validate uniqueness, and export printable sheets.
class DesignerScreen extends StatefulWidget {
  const DesignerScreen({super.key});

  @override
  State<DesignerScreen> createState() => _DesignerScreenState();
}


class _DesignerScreenState extends State<DesignerScreen> {
  final List<List<int>> _grid = List.generate(
    GameConstants.boardSize,
    (_) => List.filled(GameConstants.boardSize, 0),
  );
  int _selectedRow = 0;
  int _selectedCol = 0;

  bool _isValid = true;
  bool _hasUniqueSolution = false;
  bool _isChecking = false;
  String _statusMessage = 'Enter clues to test puzzle uniqueness.';

  /// Uniqueness solving is a backtracking search. On a near-empty grid it can
  /// run for seconds, so it is debounced off the keystroke and executed in a
  /// background isolate instead of blocking the UI thread on every edit.
  Timer? _validationDebounce;
  int _validationRunId = 0;

  /// Minimum clues before a Sudoku can have exactly one solution.
  static const int _minCluesForUnique = 17;

  static const Duration _debounceDelay = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _validateBoard();
  }

  @override
  void dispose() {
    _validationDebounce?.cancel();
    super.dispose();
  }

  static int _countClues(List<List<int>> board) {
    var count = 0;
    for (final row in board) {
      for (final value in row) {
        if (value != 0) count++;
      }
    }
    return count;
  }

  void _validateBoard() {
    // Invalidate any in-flight uniqueness run so a stale result can't overwrite
    // a newer one.
    _validationRunId++;

    final valid = SudokuLogic.isBoardValid(_grid);
    final clueCount = _countClues(_grid);

    _validationDebounce?.cancel();

    if (!valid) {
      setState(() {
        _isValid = false;
        _hasUniqueSolution = false;
        _isChecking = false;
        _statusMessage = 'Rule Violation: Duplicate numbers in row, col, or box.';
      });
      return;
    }

    if (clueCount < _minCluesForUnique) {
      setState(() {
        _isValid = true;
        _hasUniqueSolution = false;
        _isChecking = false;
        _statusMessage =
            'Need at least $_minCluesForUnique clues for a unique Sudoku puzzle ($clueCount entered).';
      });
      return;
    }

    setState(() {
      _isValid = true;
      _isChecking = true;
      _statusMessage = 'Checking for a unique solution...';
    });

    final runId = _validationRunId;
    final snapshot = List.generate(
      GameConstants.boardSize,
      (r) => List<int>.from(_grid[r]),
    );

    _validationDebounce = Timer(_debounceDelay, () {
      Isolate.run(() => SudokuLogic.hasUniqueSolution(snapshot)).then(
        (unique) {
          if (!mounted || runId != _validationRunId) return;
          setState(() {
            _isChecking = false;
            _hasUniqueSolution = unique;
            _statusMessage = unique
                ? 'Valid Unique Sudoku Puzzle! Guaranteed 1 solution.'
                : 'Multiple solutions possible. Add more clues to restrict solution.';
          });
        },
        onError: (Object error) {
          if (!mounted || runId != _validationRunId) return;
          debugPrint('Designer uniqueness check failed: $error');
          setState(() {
            _isChecking = false;
            _hasUniqueSolution = false;
            _statusMessage =
                'Could not verify uniqueness right now. Try again.';
          });
        },
      );
    });
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
      for (int r = 0; r < GameConstants.boardSize; r++) {
        for (int c = 0; c < GameConstants.boardSize; c++) {
          _grid[r][c] = 0;
        }
      }
    });
    _validateBoard();
  }

  Future<void> _exportPrintableSheet() async {
    if (!SudokuLogic.isBoardValid(_grid)) {
      AudioService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Cannot export: Grid contains rule violations (duplicate digits)!',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Backtracking on an ambiguous grid can take a while — keep it off the
    // UI thread.
    final solved = await Isolate.run(() {
      final working = List.generate(
        GameConstants.boardSize,
        (r) => List<int>.from(_grid[r]),
      );
      return SudokuLogic.solve(working) ? working : null;
    });

    if (!mounted) return;

    if (solved == null) {
      AudioService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Cannot export: This puzzle layout has no valid solution.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    AudioService.playVictory();

    final html = PdfExporter.generatePrintableHtml(
      board: _grid,
      solvedBoard: solved,
      title: 'Custom Designed Puzzle',
      difficulty: _hasUniqueSolution ? 'Unique Solution' : 'Custom Layout',
    );

    if (!mounted) return;

    final clipboard = ClipboardData(text: html);
    // Captured before the await so the confirmation snackbar does not reach
    // through a stale BuildContext.
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.print_rounded, color: Colors.indigo),
              SizedBox(width: 10),
              Expanded(child: Text('Printable HTML Worksheet')),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                html,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(clipboard);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Worksheet HTML copied. Paste it into any text editor and '
                      'print, or save it as .html and open it in a browser.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.copy_all_rounded, size: 18),
              label: const Text('COPY HTML'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
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
            icon: const Icon(Icons.rule_folder_rounded),
            tooltip: 'Inspect Full Answers & Breakdown',
            onPressed: () => CustomAnswersDialog.show(context, _grid),
          ),
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
                      if (_isChecking) ...[
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
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
