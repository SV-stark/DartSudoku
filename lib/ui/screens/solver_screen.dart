import 'package:flutter/material.dart';
import '../../providers/sudoku_provider.dart';
import '../theme.dart';
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.neonCyan, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.neonCyan),
              const SizedBox(width: 10),
              Text(
                'Solver Manual',
                style: AppTheme.titleStyle.copyWith(fontSize: 20, shadows: []),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpItem(
                  number: '1',
                  text: 'Select any cell on the grid and use the number keys below to fill in your Sudoku puzzle.',
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  number: '2',
                  text: 'Use the "Erase" button to clear a number from the selected cell.',
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  number: '3',
                  text: 'Choose your solving method:\n• Solve Complete: Solves all empty cells on the grid.\n• Solve Selected: Computes the solution and fills in ONLY the selected square.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'GOT IT',
                style: TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem({required String number, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: AppTheme.neonCyan,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: AppTheme.backgroundColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
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
                    
                    // Dynamic Error message block
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

              // Processing/Solving Overlay loader
              if (_provider.status == SolverStatus.solving)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: AppTheme.glassEffect(
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Solving Sudoku...',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceGlassColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),

        // Title
        Text(
          'GRID SOLVER',
          style: AppTheme.titleStyle.copyWith(
            fontSize: 20,
            color: Colors.white,
            shadows: [
              const Shadow(color: AppTheme.neonCyan, blurRadius: 8),
            ],
          ),
        ),

        // Help Button
        GestureDetector(
          onTap: _showHelpDialog,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceGlassColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.help_outline_rounded, color: AppTheme.neonCyan),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neonRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonRed.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.neonRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _provider.errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
            ),
          ),
        ],
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
              child: GestureDetector(
                onTap: _provider.status == SolverStatus.solving ? null : _provider.solveComplete,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonViolet.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'SOLVE COMPLETE',
                      style: TextStyle(
                        color: AppTheme.backgroundColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Solve Selected Cell Button
            Expanded(
              child: GestureDetector(
                onTap: _provider.status == SolverStatus.solving ? null : _provider.solveSelectedCell,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.neonCyan, width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      'SOLVE SELECTED',
                      style: TextStyle(
                        color: AppTheme.neonCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Clear Board Button
        OutlinedButton.icon(
          onPressed: _provider.status == SolverStatus.solving ? null : _provider.clearBoard,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text(
            'CLEAR GRID',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white.withOpacity(0.7),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
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
