import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../providers/sudoku_provider.dart';
import '../components/numpad.dart';
import '../components/sudoku_grid.dart';
import '../theme.dart';

/// The screen where users can enter custom Sudoku grids to get complete or cell-level solutions.
class SolverScreen extends StatefulWidget {
  const SolverScreen({super.key});

  @override
  State<SolverScreen> createState() => _SolverScreenState();
}

class _SolverScreenState extends State<SolverScreen> {
  late SudokuSolverProvider _provider;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _provider = SudokuSolverProvider();
    _provider.addListener(_onStateChange);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onStateChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onStateChange);
    _provider.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    // Numbers 1-9
    int? number;
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      number = 1;
    } else if (key == LogicalKeyboardKey.digit2 ||
        key == LogicalKeyboardKey.numpad2) {
      number = 2;
    } else if (key == LogicalKeyboardKey.digit3 ||
        key == LogicalKeyboardKey.numpad3) {
      number = 3;
    } else if (key == LogicalKeyboardKey.digit4 ||
        key == LogicalKeyboardKey.numpad4) {
      number = 4;
    } else if (key == LogicalKeyboardKey.digit5 ||
        key == LogicalKeyboardKey.numpad5) {
      number = 5;
    } else if (key == LogicalKeyboardKey.digit6 ||
        key == LogicalKeyboardKey.numpad6) {
      number = 6;
    } else if (key == LogicalKeyboardKey.digit7 ||
        key == LogicalKeyboardKey.numpad7) {
      number = 7;
    } else if (key == LogicalKeyboardKey.digit8 ||
        key == LogicalKeyboardKey.numpad8) {
      number = 8;
    } else if (key == LogicalKeyboardKey.digit9 ||
        key == LogicalKeyboardKey.numpad9) {
      number = 9;
    }

    if (number != null) {
      _provider.enterNumber(number);
      return;
    }

    // Erase keys
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      _provider.clearCell();
      return;
    }

    // Arrow keys navigation
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      int r = _provider.selectedRow;
      int c = _provider.selectedCol;

      if (r == -1 || c == -1) {
        _provider.selectCell(0, 0);
      } else {
        if (key == LogicalKeyboardKey.arrowUp) {
          r = (r - 1).clamp(0, 8);
        } else if (key == LogicalKeyboardKey.arrowDown) {
          r = (r + 1).clamp(0, 8);
        } else if (key == LogicalKeyboardKey.arrowLeft) {
          c = (c - 1).clamp(0, 8);
        } else if (key == LogicalKeyboardKey.arrowRight) {
          c = (c + 1).clamp(0, 8);
        }
        _provider.selectCell(r, c);
      }
    }
  }

  void _showHelpDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Solver Manual',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpItem(
                  context,
                  number: '1',
                  text:
                      'Tap any cell on the grid and use the number keys below to fill in your Sudoku puzzle.',
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  context,
                  number: '2',
                  text:
                      'Use the "Erase" button to clear a number from the selected cell.',
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  context,
                  number: '3',
                  text:
                      'Choose your solving method:\n• Solve Complete: Solves all empty cells on the grid.\n• Solve Step: Solves one cell at a time and explains the technique used.\n• Solve Selected: Computes the solution and fills in ONLY the selected square.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'GOT IT',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(
    BuildContext context, {
    required String number,
    required String text,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    Widget content;
    if (isLandscape) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side: Sudoku Grid
          Expanded(
            flex: 6,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _provider,
                    _provider.selectionNotifier,
                  ]),
                  builder: (context, _) {
                    return SudokuGrid(
                      board: _provider.solverBoard,
                      selectedRow: _provider.selectedRow,
                      selectedCol: _provider.selectedCol,
                      flashRow: _provider.flashRow,
                      flashCol: _provider.flashCol,
                      onCellTap: (r, c) {
                        _provider.selectCell(r, c);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          // Right side: Controls
          Expanded(
            flex: 5,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    if (_provider.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _buildErrorDisplay(),
                    ],
                    if (_provider.stepExplanation != null) ...[
                      const SizedBox(height: 12),
                      _buildStepExplanationDisplay(),
                    ],
                    const SizedBox(height: 16),
                    _buildSolverActionButtons(),
                    const SizedBox(height: 16),
                    SudokuNumpad(
                      onNumberTap: _provider.enterNumber,
                      onEraseTap: _provider.clearCell,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Header Row
              _buildHeader(),
              const SizedBox(height: 16),
              // Grid Screen
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _provider,
                      _provider.selectionNotifier,
                    ]),
                    builder: (context, _) {
                      return SudokuGrid(
                        board: _provider.solverBoard,
                        selectedRow: _provider.selectedRow,
                        selectedCol: _provider.selectedCol,
                        flashRow: _provider.flashRow,
                        flashCol: _provider.flashCol,
                        onCellTap: (r, c) {
                          _provider.selectCell(r, c);
                        },
                      );
                    },
                  ),
                ),
              ),

              // Dynamic Error message block (Material 3 Card)
              if (_provider.errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorDisplay(),
              ],
              if (_provider.stepExplanation != null) ...[
                const SizedBox(height: 12),
                _buildStepExplanationDisplay(),
              ],

              const SizedBox(height: 20),
              // Solve & Clear Button controls
              _buildSolverActionButtons(),
              const SizedBox(height: 20),
              // Numeric inputs
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: SudokuNumpad(
                  onNumberTap: _provider.enterNumber,
                  onEraseTap: _provider.clearCell,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
          },
          behavior: HitTestBehavior.opaque,
          child: KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _handleKeyEvent,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: content,
                ),

                // Processing/Solving Overlay loader (Clean Material 3 Card style)
                if (_provider.status == SolverStatus.solving)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Center(
                        child: Card(
                          elevation: 4,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 32,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 20),
                                  Text(
                                    'Solving Sudoku...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button & Theme Toggle group
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: AppTheme.themeModeNotifier,
              builder: (context, themeMode, _) {
                return IconButton.filledTonal(
                  onPressed: AppTheme.toggleTheme,
                  tooltip: 'Toggle Theme',
                  icon: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                  ),
                );
              },
            ),
          ],
        ),

        // Title
        Text(
          'DartSudoku Solver',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        // Help Button
        IconButton.filledTonal(
          onPressed: _showHelpDialog,
          icon: const Icon(Icons.help_outline_rounded),
        ),
      ],
    );
  }

  Widget _buildErrorDisplay() {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.errorContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _provider.errorMessage!,
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolverActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Solve Complete Button
            Expanded(
              child: FilledButton.icon(
                onPressed: _provider.status == SolverStatus.solving
                    ? null
                    : _provider.solveComplete,
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: const Text(
                  'SOLVE COMPLETE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    fontSize: 12,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Solve Step Button
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _provider.status == SolverStatus.solving
                    ? null
                    : _provider.solveStepWise,
                icon: const Icon(Icons.skip_next_rounded, size: 18),
                label: const Text(
                  'SOLVE STEP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    fontSize: 12,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Solve Selected Button
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _provider.status == SolverStatus.solving
                    ? null
                    : _provider.solveSelectedCell,
                icon: const Icon(Icons.touch_app_rounded, size: 18),
                label: const Text(
                  'SOLVE SELECTED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    fontSize: 12,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Clear Grid Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _provider.status == SolverStatus.solving
                    ? null
                    : _provider.clearBoard,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'CLEAR GRID',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    fontSize: 12,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepExplanationDisplay() {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.secondary.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: theme.colorScheme.secondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step Solve Technique',
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _provider.stepExplanation!,
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
