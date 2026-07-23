import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/sudoku_logic.dart';
import '../../providers/sudoku_provider.dart';
import 'sudoku_grid.dart';

/// Interactive modal sheet allowing users to replay their Sudoku solve session step-by-step.
class ReplayDialog extends StatefulWidget {
  final List<MoveRecord> moveHistory;
  final List<List<int>> initialBoard;
  final List<List<bool>> isClue;

  const ReplayDialog({
    super.key,
    required this.moveHistory,
    required this.initialBoard,
    required this.isClue,
  });

  static void show(
    BuildContext context, {
    required List<MoveRecord> moveHistory,
    required List<List<int>> initialBoard,
    required List<List<bool>> isClue,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReplayDialog(
        moveHistory: moveHistory,
        initialBoard: initialBoard,
        isClue: isClue,
      ),
    );
  }

  @override
  State<ReplayDialog> createState() => _ReplayDialogState();
}

class _ReplayDialogState extends State<ReplayDialog> {
  int _currentStep = 0;
  bool _isPlaying = false;
  int _speedMultiplier = 1;
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.moveHistory.length; // Start at full solve state
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        if (_currentStep >= widget.moveHistory.length) {
          _currentStep = 0;
        }
        _startPlayback();
      } else {
        _playbackTimer?.cancel();
      }
    });
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    final intervalMs = (600 / _speedMultiplier).round();
    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_currentStep < widget.moveHistory.length) {
        setState(() {
          _currentStep++;
        });
      } else {
        setState(() {
          _isPlaying = false;
        });
        _playbackTimer?.cancel();
      }
    });
  }

  void _changeSpeed(int speed) {
    setState(() {
      _speedMultiplier = speed;
      if (_isPlaying) {
        _startPlayback();
      }
    });
  }

  List<List<int>> _computeBoardAtStep(int step) {
    final board = SudokuLogic.copyBoard(widget.initialBoard);
    for (int i = 0; i < step && i < widget.moveHistory.length; i++) {
      final move = widget.moveHistory[i];
      if (!move.isNote) {
        board[move.row][move.col] = move.value;
      }
    }
    return board;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boardAtStep = _computeBoardAtStep(_currentStep);
    final totalSteps = widget.moveHistory.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.replay_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Solve Replay',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: SudokuGrid(
                  board: boardAtStep,
                  selectedRow: -1,
                  selectedCol: -1,
                  isClue: widget.isClue,
                  onCellTap: (r, c) {},
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  totalSteps > 0
                      ? 'Step $_currentStep of $totalSteps'
                      : 'No moves recorded',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _currentStep.toDouble(),
                  min: 0,
                  max: totalSteps > 0 ? totalSteps.toDouble() : 1.0,
                  divisions: totalSteps > 0 ? totalSteps : 1,
                  onChanged: (val) {
                    setState(() {
                      _currentStep = val.toInt();
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [1, 2, 4].map((s) {
                        final isSel = _speedMultiplier == s;
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ChoiceChip(
                            label: Text('${s}x'),
                            selected: isSel,
                            onSelected: (_) => _changeSpeed(s),
                          ),
                        );
                      }).toList(),
                    ),
                    IconButton.filled(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: totalSteps > 0 ? _togglePlayPause : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
