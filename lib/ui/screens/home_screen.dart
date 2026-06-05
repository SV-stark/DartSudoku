import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/sudoku_provider.dart';
import '../theme.dart';
import 'game_screen.dart';
import 'solver_screen.dart';
import 'stats_screen.dart';
import 'daily_challenge_screen.dart';
import 'tutorial_screen.dart';
import 'settings_sheet.dart';

/// The entry screen of the application offering play options and the solver utility.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late SudokuGameProvider _settingsProvider;
  bool _isTodayCompleted = false;

  @override
  void initState() {
    super.initState();
    _settingsProvider = SudokuGameProvider();
    _checkTodayCompletion();
  }

  Future<void> _checkTodayCompletion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('completed_daily_challenges') ?? [];
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      setState(() {
        _isTodayCompleted = list.contains(todayStr);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Logo Area
                  _buildLogo(context),
                  const SizedBox(height: 32),

                  // Daily Challenge Card
                  _buildDailyChallengeCard(context),
                  const SizedBox(height: 16),

                  // Play Mode Card
                  _buildPlayCard(context),
                  const SizedBox(height: 16),

                  // Solver Mode Card
                  _buildSolverCard(context),
                  const SizedBox(height: 16),

                  // Tutorial Card
                  _buildTutorialCard(context),
                ],
              ),
            ),
          ),

          // Floating action buttons in Material 3 style
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: AppTheme.themeModeNotifier,
                  builder: (context, themeMode, _) {
                    return FloatingActionButton.small(
                      heroTag: 'theme_toggle',
                      onPressed: AppTheme.toggleTheme,
                      tooltip: 'Toggle Theme',
                      child: Icon(
                        themeMode == ThemeMode.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'settings_btn',
                  onPressed: () =>
                      SettingsSheet.show(context, _settingsProvider),
                  tooltip: 'Settings',
                  child: const Icon(Icons.tune_rounded),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'stats_btn',
                  onPressed: _openStats,
                  tooltip: 'Analytics',
                  child: const Icon(Icons.insights_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'DartSudoku',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: theme.colorScheme.onBackground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'ELEGANT & INTELLIGENT',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 3.0,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlayCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle_outline_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Select Game Level',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Challenge yourself with standard game boards featuring unique, solvable solutions.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _buildDifficultyButton(
              context,
              label: 'EASY',
              color: Colors.green,
              onTap: () => _startGame('easy'),
            ),
            const SizedBox(height: 12),
            _buildDifficultyButton(
              context,
              label: 'MEDIUM',
              color: Colors.orange,
              onTap: () => _startGame('medium'),
            ),
            const SizedBox(height: 12),
            _buildDifficultyButton(
              context,
              label: 'HARD',
              color: Colors.red,
              onTap: () => _startGame('hard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolverCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: InkWell(
        onTap: _openSolver,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calculate_rounded,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sudoku Solver',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Input your custom grids and let the solver resolve the board completely, or query answers for selected squares only.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.brightness == Brightness.dark
              ? color.withOpacity(0.9)
              : color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  void _startGame(String difficulty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(difficulty: difficulty),
      ),
    );
  }

  void _openSolver() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SolverScreen()),
    );
  }

  void _openStats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatsScreen()),
    );
  }

  Widget _buildDailyChallengeCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _openDailyChallenge,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Daily Challenge',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isTodayCompleted) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isTodayCompleted
                          ? "Congratulations! You completed today's seeded daily Sudoku challenge."
                          : "Play today's seeded daily Sudoku and build your monthly completion streak.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _openTutorial,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.school_rounded,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sudoku School',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Learn scanning, pointing pairs, naked pairs, and advanced strategies with interactive visual guides.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDailyChallenge() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DailyChallengeScreen()),
    ).then((_) => _checkTodayCompletion());
  }

  void _openTutorial() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TutorialScreen()),
    );
  }
}
