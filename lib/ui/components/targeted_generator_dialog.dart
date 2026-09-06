import 'dart:isolate';
import 'package:flutter/material.dart';
import '../../core/difficulty.dart';
import '../../core/sudoku_analyzer.dart';
import '../screens/game_screen.dart';

/// Modal dialog allowing users to pick a specific solving strategy and difficulty
/// to generate a targeted training puzzle.
class TargetedGeneratorDialog extends StatefulWidget {
  const TargetedGeneratorDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TargetedGeneratorDialog(),
    );
  }

  @override
  State<TargetedGeneratorDialog> createState() => _TargetedGeneratorDialogState();
}

class _TargetedGeneratorDialogState extends State<TargetedGeneratorDialog> {
  int _selectedTier = 1;
  String _selectedStrategy = 'Naked Single';
  Difficulty _selectedDifficulty = Difficulty.medium;
  bool _isGenerating = false;

  static const Map<int, String> _tierNames = {
    1: 'Tier 1: Basics & Scanning',
    2: 'Tier 2: Advanced Fish',
    3: 'Tier 3: Wing Strategies',
    4: 'Tier 4: Chaining & Uniqueness',
  };

  static const Map<int, List<String>> _tierStrategies = {
    1: [
      'Naked Single',
      'Hidden Single',
      'Naked Pair',
      'Hidden Pair',
      'Naked Triple',
      'Hidden Triple',
      'Locked Candidates',
    ],
    2: [
      'X-Wing',
      'Swordfish',
      'Jellyfish',
      'Finned X-Wing',
      'Sashimi X-Wing',
    ],
    3: [
      'Skyscraper',
      'Two-String-Kite',
      'Empty Rectangle',
      'Y-Wing',
      'XYZ-Wing',
      'W-Wing',
    ],
    4: [
      'Simple Coloring',
      'X-Chain',
      'XY-Chain',
      'Alternating Inference Chain',
      'Unique Rectangles',
    ],
  };

  void _onTierChanged(int tier) {
    setState(() {
      _selectedTier = tier;
      _selectedStrategy = _tierStrategies[tier]!.first;
    });
  }

  Future<void> _generateAndPlay() async {
    setState(() {
      _isGenerating = true;
    });

    final strategy = _selectedStrategy;
    final diff = _selectedDifficulty;

    try {
      final puzzle = await Isolate.run(
        () => SudokuAnalyzer.generateTargetedPuzzle(strategy, diff),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen.fromPuzzle(
            puzzle: puzzle,
            difficulty: diff,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate targeted puzzle: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeStrategies = _tierStrategies[_selectedTier]!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                    Icon(
                      Icons.psychology_alt_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Targeted Strategy Generator',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Select Difficulty Level',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: Difficulty.values.map((d) {
                      final isSelected = _selectedDifficulty == d;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Center(
                              child: Text(d.name.toUpperCase()),
                            ),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedDifficulty = d;
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '2. Select Strategy Tier',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: [1, 2, 3, 4].map((tier) {
                      final isSelected = _selectedTier == tier;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          tileColor: isSelected
                              ? theme.colorScheme.primaryContainer.withValues(
                                  alpha: 0.4,
                                )
                              : null,
                          title: Text(
                            _tierNames[tier]!,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          onTap: () => _onTierChanged(tier),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '3. Select Target Technique',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: activeStrategies.map((strat) {
                      final isSelected = _selectedStrategy == strat;
                      return FilterChip(
                        label: Text(strat),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedStrategy = strat;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _isGenerating ? null : _generateAndPlay,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  _isGenerating
                      ? 'Generating Puzzle...'
                      : 'GENERATE & PLAY $_selectedStrategy',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
