import 'package:flutter/material.dart';
import '../../core/sudoku_logic.dart';
import '../../providers/sudoku_provider.dart';
import '../../core/sudoku_analyzer.dart';
import '../theme.dart';
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
    // Trigger game creation on next frame
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

  void _showHintExplanationDialog() {
    final int r = _provider.selectedRow;
    final int c = _provider.selectedCol;

    if (r == -1 || c == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.neonCyan.withOpacity(0.9),
          content: const Text(
            'Select an empty cell to receive a hint explanation!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    if (_provider.isOriginalClue[r][c]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.neonCyan.withOpacity(0.9),
          content: const Text(
            'Starting clues cannot have hints.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    final int correctVal = _provider.solvedBoard[r][c];
    if (_provider.currentBoard[r][c] == correctVal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.neonGreen.withOpacity(0.9),
          content: const Text(
            'This cell is already correctly solved!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
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
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.neonAmber, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.psychology_rounded, color: AppTheme.neonAmber, size: 28),
              SizedBox(width: 10),
              Text(
                'Neural Strategy Hint',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                explanation,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('KEEP THINKING', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _provider.revealHint();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonAmber),
              child: const Text(
                'REVEAL VALUE',
                style: TextStyle(color: AppTheme.backgroundColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return AppTheme.neonGreen;
      case 'medium':
        return AppTheme.neonAmber;
      case 'hard':
        return AppTheme.neonRed;
      default:
        return AppTheme.neonCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameColor = _getDifficultyColor(_provider.difficulty);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Core Layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

              // Game Pause Overlay
              if (_provider.status == GameStatus.paused) _buildPausedOverlay(),

              // Game Over Overlay
              if (_provider.status == GameStatus.gameOver) _buildGameOverOverlay(),

              // Win Overlay
              if (_provider.status == GameStatus.won) _buildWinOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color difficultyColor) {
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

        // Difficulty Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: difficultyColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: difficultyColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: difficultyColor.withOpacity(0.15),
                blurRadius: 8,
              )
            ],
          ),
          child: Text(
            _provider.difficulty.toUpperCase(),
            style: TextStyle(
              color: difficultyColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),

        // Timer Panel
        GestureDetector(
          onTap: () {
            if (_provider.status == GameStatus.playing) {
              _provider.pauseGame();
            } else if (_provider.status == GameStatus.paused) {
              _provider.resumeGame();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: AppTheme.glassBoxDecoration(
              borderRadius: 20,
              borderColor: AppTheme.neonCyan.withOpacity(0.3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _provider.status == GameStatus.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: AppTheme.neonCyan,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _provider.formattedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(Color difficultyColor) {
    if (_provider.status == GameStatus.loading) return const SizedBox(height: 20);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Mistakes Counter
        Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.neonRed, size: 18),
            const SizedBox(width: 6),
            Text(
              'Mistakes: ',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            ),
            ...List.generate(_provider.maxMistakes, (index) {
              final bool isMistake = index < _provider.mistakes;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: isMistake ? AppTheme.neonRed.withOpacity(0.15) : AppTheme.neonRed,
                ),
              );
            }),
          ],
        ),
        
        // Progress or clues count
        Text(
          'Total Clues: ${widget.difficulty.toLowerCase() == 'easy' ? '32' : widget.difficulty.toLowerCase() == 'medium' ? '27' : '22'}',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return AppTheme.glassEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonViolet),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Generating Solvable Grid...',
              style: AppTheme.subtitleStyle.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Aligning numeric pathways',
              style: AppTheme.subtitleStyle.copyWith(fontSize: 12, color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPausedOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: AppTheme.glassEffect(
          fillColor: Colors.black.withOpacity(0.4),
          borderColor: AppTheme.neonCyan.withOpacity(0.2),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.pause_circle_filled_rounded,
                  size: 80,
                  color: AppTheme.neonCyan,
                ),
                const SizedBox(height: 24),
                Text(
                  'GAME PAUSED',
                  style: AppTheme.titleStyle.copyWith(shadows: [
                    const Shadow(color: AppTheme.neonCyan, blurRadius: 15),
                  ]),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _provider.resumeGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonCyan,
                    foregroundColor: AppTheme.backgroundColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'RESUME PLAY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
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

  Widget _buildGameOverOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: AppTheme.glassEffect(
              borderColor: AppTheme.neonRed.withOpacity(0.4),
              fillColor: AppTheme.surfaceColor.withOpacity(0.8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.gpp_bad_rounded,
                      size: 80,
                      color: AppTheme.neonRed,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'GAME OVER',
                      style: AppTheme.titleStyle.copyWith(
                        color: AppTheme.neonRed,
                        shadows: [
                          const Shadow(color: AppTheme.neonRed, blurRadius: 15),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You committed 3 mistakes and terminated the neural matrix.',
                      style: AppTheme.subtitleStyle.copyWith(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withOpacity(0.2)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('EXIT MENU'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _provider.newGame(widget.difficulty),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
    );
  }

  Widget _buildWinOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: AppTheme.glassEffect(
              borderColor: AppTheme.neonGreen.withOpacity(0.4),
              fillColor: AppTheme.surfaceColor.withOpacity(0.8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 80,
                      color: AppTheme.neonGreen,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'VICTORY',
                      style: AppTheme.titleStyle.copyWith(
                        color: AppTheme.neonGreen,
                        shadows: [
                          const Shadow(color: AppTheme.neonGreen, blurRadius: 15),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You successfully solved the matrix in ${_provider.formattedTime}!',
                      style: AppTheme.subtitleStyle.copyWith(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withOpacity(0.2)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('EXIT'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _provider.newGame(widget.difficulty),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
    );
  }
}
