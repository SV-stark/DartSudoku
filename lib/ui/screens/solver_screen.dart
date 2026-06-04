import 'package:flutter/material.dart';
import '../../providers/sudoku_provider.dart';
import '../../ui/theme.dart';
import '../components/numpad.dart';
import '../components/sudoku_grid.dart';

/// The screen where users can enter custom Sudoku grids to get complete or cell-level solutions.
class SolverScreen extends StatefulWidget {
  const SolverScreen({super.key});

  @override
  State<SolverScreen> createState() => _SolverScreenState();
}

class _SolverScreenState extends State<SolverScreen> {
  late SudokuSolverProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = SudokuSolverProvider();
    _provider.addListener(_onStateChange);
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
    super.dispose();
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
            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
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
                      'Choose your solving method:\n• Solve Complete: Solves all empty cells on the grid.\n• Solve Selected: Computes the solution and fills in ONLY the selected square.',
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
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Header Row
                  _buildHeader(),
                  const SizedBox(height: 16),
                  // Grid Screen
                  Expanded(
                    child: Center(
                      child: SudokuGrid(
                        board: _provider.solverBoard,
                        selectedRow: _provider.selectedRow,
                        selectedCol: _provider.selectedCol,
                        onCellTap: (r, c) {
                          _provider.selectCell(r, c);
                        },
                      ),
                    ),
                  ),

                  // Dynamic Error message block (Material 3 Card)
                  if (_provider.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildErrorDisplay(),
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

            // Processing/Solving Overlay loader (Clean Material 3 Card style)
            if (_provider.status == SolverStatus.solving)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Card(
                      elevation: 4,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 32,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 20),
                            Text(
                              'Solving Sudoku...',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        IconButton.filledTonal(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
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
        side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
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
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Solve Complete Button (Material 3 Filled Button)
            Expanded(
              child: FilledButton(
                onPressed: _provider.status == SolverStatus.solving
                    ? null
                    : _provider.solveComplete,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'SOLVE COMPLETE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Solve Selected Cell Button (Material 3 Filled Tonal Button)
            Expanded(
              child: FilledButton.tonal(
                onPressed: _provider.status == SolverStatus.solving
                    ? null
                    : _provider.solveSelectedCell,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'SOLVE SELECTED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Clear Board Button (Material 3 Outlined Button)
        OutlinedButton.icon(
          onPressed: _provider.status == SolverStatus.solving
              ? null
              : _provider.clearBoard,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text(
            'CLEAR GRID',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }
}
