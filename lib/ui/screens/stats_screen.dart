import 'package:flutter/material.dart';
import '../../core/stats_manager.dart';
import '../theme.dart';

/// Screen displaying game analytics, win ratios, streaks, and speed scores.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<GameStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _statsFuture = StatsManager.getStats();
    });
  }

  String _formatTime(double totalSeconds) {
    if (totalSeconds <= 0 || totalSeconds.isNaN || totalSeconds.isInfinite) {
      return '--:--';
    }
    int secs = totalSeconds.round();
    int minutes = secs ~/ 60;
    int seconds = secs % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmReset() async {
    final theme = Theme.of(context);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 10),
              const Text(
                'Reset Analytics',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to permanently clear all DartSudoku statistics, records, and win streaks? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'CANCEL',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text(
                'RESET',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await StatsManager.resetStats();
      _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: const Text('Statistics cleared successfully.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildHeader(),
            Expanded(
              child: FutureBuilder<GameStats>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading analytics data.',
                        style: theme.textTheme.titleMedium,
                      ),
                    );
                  }

                  final stats = snapshot.data!;
                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildStreakSection(stats),
                      const SizedBox(height: 24),
                      Text(
                        'Difficulty Breakdown',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...['easy', 'medium', 'hard'].map((difficulty) {
                        final diffStats = stats.difficultyStats[difficulty]!;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildDifficultyCard(difficulty, diffStats),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
          Text(
            'DartSudoku Analytics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton.filledTonal(
            onPressed: _confirmReset,
            icon: Icon(
              Icons.delete_sweep_rounded,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection(GameStats stats) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: theme.colorScheme.primary,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${stats.currentStreak}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CURRENT STREAK',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 70,
              color: theme.colorScheme.outlineVariant,
            ),
            Expanded(
              child: Column(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.orange,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${stats.maxStreak}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MAX WIN STREAK',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
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

  Widget _buildDifficultyCard(String difficulty, SudokuStats stats) {
    final theme = Theme.of(context);
    final Color diffColor = AppTheme.getDifficultyColor(difficulty);
    final double winRate = stats.gamesPlayed > 0
        ? (stats.gamesWon / stats.gamesPlayed) * 100
        : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  difficulty.toUpperCase(),
                  style: TextStyle(
                    color: diffColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Win Rate: ${winRate.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatLabel('Played', '${stats.gamesPlayed}'),
                _buildStatLabel('Won', '${stats.gamesWon}'),
                _buildStatLabel(
                  'Best Time',
                  _formatTime(stats.bestTime.toDouble()),
                ),
                _buildStatLabel('Avg Time', _formatTime(stats.averageTime)),
              ],
            ),
            _buildTopTimesTable(stats, diffColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTimesTable(SudokuStats stats, Color diffColor) {
    final theme = Theme.of(context);
    final topTimes = stats.topTimes;

    if (topTimes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Divider(color: theme.colorScheme.outlineVariant, height: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 18),
            const SizedBox(width: 6),
            Text(
              'Personal Bests',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: diffColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: topTimes.length,
          itemBuilder: (context, idx) {
            final record = topTimes[idx];
            final isFirst = idx == 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        alignment: Alignment.center,
                        child: Text(
                          '#${idx + 1}',
                          style: TextStyle(
                            fontWeight: isFirst
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isFirst
                                ? Colors.amber
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(record.timeInSeconds.toDouble()),
                        style: TextStyle(
                          fontWeight: isFirst
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    record.date,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatLabel(String label, String value) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
