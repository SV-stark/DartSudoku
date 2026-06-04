import 'package:flutter/material.dart';
import '../../core/stats_manager.dart';
import '../../ui/theme.dart';

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
    if (totalSeconds <= 0 || totalSeconds.isNaN || totalSeconds.isInfinite) return '--:--';
    int secs = totalSeconds.round();
    int minutes = secs ~/ 60;
    int seconds = secs % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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

  Future<void> _confirmReset() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.neonRed, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: AppTheme.neonRed),
              SizedBox(width: 10),
              Text(
                'Reset Analytics',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to permanently clear all Sudoku statistics, records, and win streaks? This action cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonRed),
              child: const Text('RESET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            backgroundColor: AppTheme.neonRed.withOpacity(0.9),
            content: const Text(
              'Statistics cleared successfully.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              Expanded(
                child: FutureBuilder<GameStats>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == snapshot.connectionState && !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading analytics data.',
                          style: AppTheme.subtitleStyle,
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
                          style: AppTheme.titleStyle.copyWith(fontSize: 20, shadows: []),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
          Text(
            'NEURAL ANALYTICS',
            style: AppTheme.titleStyle.copyWith(
              fontSize: 20,
              shadows: [
                const Shadow(color: AppTheme.neonCyan, blurRadius: 8),
              ],
            ),
          ),
          GestureDetector(
            onTap: _confirmReset,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceGlassColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.neonRed.withOpacity(0.2)),
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: AppTheme.neonRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection(GameStats stats) {
    return AppTheme.glassEffect(
      borderColor: AppTheme.neonCyan.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: AppTheme.neonAmber, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    '${stats.currentStreak}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CURRENT STREAK',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 70,
              color: Colors.white.withOpacity(0.1),
            ),
            Expanded(
              child: Column(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: AppTheme.neonGreen, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    '${stats.maxStreak}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MAX WIN STREAK',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5)),
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
    final Color diffColor = _getDifficultyColor(difficulty);
    final double winRate = stats.gamesPlayed > 0 ? (stats.gamesWon / stats.gamesPlayed) * 100 : 0.0;

    return AppTheme.glassEffect(
      borderColor: diffColor.withOpacity(0.3),
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
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: diffColor.withOpacity(0.5), blurRadius: 8),
                    ],
                  ),
                ),
                Text(
                  'Win Rate: ${winRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
                _buildStatLabel('Best Time', _formatTime(stats.bestTime.toDouble())),
                _buildStatLabel('Avg Time', _formatTime(stats.averageTime)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatLabel(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
        ),
      ],
    );
  }
}
