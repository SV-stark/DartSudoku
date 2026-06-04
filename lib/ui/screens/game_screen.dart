import 'package:flutter/material.dart';
import '../../providers/sudoku_provider.dart';
import '../../core/sudoku_analyzer.dart';
import '../components/numpad.dart';
import '../components/sudoku_grid.dart';

/// The game screen where players solve generated boards.
class GameScreen extends StatefulWidget {
  final String difficulty;

  const GameScreen({super.key, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late SudokuGameProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = SudokuGameProvider();
    _provider.addListener(_onStateChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.newGame(widget.difficulty);
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
    super.dispose();
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _showHintExplanationDialog() {
    final int r = _provider.selectedRow;
    final int c = _provider.selectedCol;
    final theme = Theme.of(context);

    if (r == -1 || c == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: const Text(
            'Select an empty cell to receive a hint explanation!',
          ),
        ),
      );
      return;
    }

    if (_provider.isOriginalClue[r][c]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: const Text('Starting clues cannot have hints.'),
        ),
      );
      return;
    }

    final int correctVal = _provider.solvedBoard[r][c];
    if (_provider.currentBoard[r][c] == correctVal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: const Text('This cell is already correctly solved!'),
        ),
      );
      return;
    }

    final String explanation = SudokuAnalyzer.analyzeCell(
      _provider.currentBoard,
      r,
      c,
      correctVal,
    );

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
                Icons.psychology_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                'Strategy Explainer',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                explanation,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'KEEP THINKING',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _provider.revealHint();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text(
                'REVEAL VALUE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameColor = _getDifficultyColor(_provider.difficulty);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

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
                child: _provider.status == GameStatus.loading
                    ? _buildLoadingState()
                    : SudokuGrid(
                        board: _provider.currentBoard,
                        selectedRow: _provider.selectedRow,
                        selectedCol: _provider.selectedCol,
                        isClue: _provider.isOriginalClue,
                        notes: _provider.notes,
                        solvedBoard: _provider.solvedBoard,
                        onCellTap: (r, c) {
                          _provider.selectCell(r, c);
                        },
                      ),
              ),
            ),
          ),
          // Right side: Controls & Stats
          Expanded(
            flex: 5,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(gameColor),
                    const SizedBox(height: 12),
                    _buildStatsRow(gameColor),
                    const SizedBox(height: 16),
                    if (_provider.status != GameStatus.loading)
                      SudokuNumpad(
                        onNumberTap: _provider.enterNumber,
                        onEraseTap: _provider.eraseCell,
                        onUndoTap: _provider.undo,
                        onNotesTap: _provider.toggleNotesMode,
                        onHintTap: _showHintExplanationDialog,
                        notesModeActive: _provider.notesMode,
                        canUndo: _provider.canUndo,
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
              _buildHeader(gameColor),
              const SizedBox(height: 16),
              // Stats Row
              _buildStatsRow(gameColor),
              const SizedBox(height: 16),
              // Sudoku Board
              Expanded(
                child: Center(
                  child: _provider.status == GameStatus.loading
                      ? _buildLoadingState()
                      : SudokuGrid(
                          board: _provider.currentBoard,
                          selectedRow: _provider.selectedRow,
                          selectedCol: _provider.selectedCol,
                          isClue: _provider.isOriginalClue,
                          notes: _provider.notes,
                          solvedBoard: _provider.solvedBoard,
                          onCellTap: (r, c) {
                            _provider.selectCell(r, c);
                          },
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Controls (Numpad + Tool Buttons)
              if (_provider.status != GameStatus.loading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: SudokuNumpad(
                    onNumberTap: _provider.enterNumber,
                    onEraseTap: _provider.eraseCell,
                    onUndoTap: _provider.undo,
                    onNotesTap: _provider.toggleNotesMode,
                    onHintTap: _showHintExplanationDialog,
                    notesModeActive: _provider.notesMode,
                    canUndo: _provider.canUndo,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Core Layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: content,
            ),

            // Game Pause Overlay
            if (_provider.status == GameStatus.paused) _buildPausedOverlay(),

            // Game Over Overlay
            if (_provider.status == GameStatus.gameOver)
              _buildGameOverOverlay(),

            // Win Overlay
            if (_provider.status == GameStatus.won) _buildWinOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color difficultyColor) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        IconButton.filledTonal(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),

        // Difficulty Badge (FilterChip-like styling)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: difficultyColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: difficultyColor.withOpacity(0.5),
              width: 1.0,
            ),
          ),
          child: Text(
            _provider.difficulty.toUpperCase(),
            style: TextStyle(
              color: difficultyColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),

        // Timer Panel (Material 3 Chip look)
        ActionChip(
          avatar: Icon(
            _provider.status == GameStatus.paused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            color: theme.colorScheme.primary,
            size: 18,
          ),
          label: Text(
            _provider.formattedTime,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            if (_provider.status == GameStatus.playing) {
              _provider.pauseGame();
            } else if (_provider.status == GameStatus.paused) {
              _provider.resumeGame();
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatsRow(Color difficultyColor) {
    final theme = Theme.of(context);
    if (_provider.status == GameStatus.loading)
      return const SizedBox(height: 20);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Mistakes Counter
        Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.error,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'Mistakes: ',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            ...List.generate(_provider.maxMistakes, (index) {
              final bool isMistake = index < _provider.mistakes;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: isMistake
                      ? theme.colorScheme.error.withOpacity(0.15)
                      : theme.colorScheme.error,
                ),
              );
            }),
          ],
        ),

        // Progress or clues count
        Text(
          'Total Clues: ${widget.difficulty.toLowerCase() == 'easy'
              ? '32'
              : widget.difficulty.toLowerCase() == 'medium'
              ? '27'
              : '22'}',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 24),
            Text(
              'Generating Solvable Grid...',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Aligning numeric pathways',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPausedOverlay() {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: Center(
          child: Card(
            elevation: 8,
            color: theme.colorScheme.surface,
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 40.0,
                horizontal: 24.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pause_circle_outline_rounded,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Game Paused',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _provider.resumeGame,
                      child: const Text(
                        'RESUME PLAY',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Card(
              elevation: 8,
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40.0,
                  horizontal: 24.0,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.gpp_bad_rounded,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'GAME OVER',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You committed 3 mistakes and terminated the board.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('EXIT MENU'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () =>
                                  _provider.newGame(widget.difficulty),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                                foregroundColor: theme.colorScheme.onError,
                              ),
                              child: const Text('TRY AGAIN'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWinOverlay() {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Card(
              elevation: 8,
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40.0,
                  horizontal: 24.0,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'VICTORY',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You successfully solved the matrix in ${_provider.formattedTime}!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('EXIT'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () =>
                                  _provider.newGame(widget.difficulty),
                              child: const Text('PLAY AGAIN'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
