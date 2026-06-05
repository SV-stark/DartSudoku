import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_screen.dart';

/// Screen displaying a calendar grid of the current month where players can solve daily seeded games.
class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  late DateTime _selectedMonth;
  List<String> _completedDates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _loadCompletions();
  }

  Future<void> _loadCompletions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      _completedDates = prefs.getStringList('completed_daily_challenges') ?? [];
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getDifficultyForDay(DateTime date) {
    final weekday = date.weekday;
    if (weekday == DateTime.monday || weekday == DateTime.tuesday) {
      return 'easy';
    } else if (weekday == DateTime.wednesday || weekday == DateTime.thursday) {
      return 'medium';
    } else {
      return 'hard';
    }
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

  void _playChallenge(DateTime date) {
    final String dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final difficulty = _getDifficultyForDay(date);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GameScreen(difficulty: difficulty, dailyChallengeDate: dateStr),
      ),
    ).then((_) {
      // Reload completions after returning in case the challenge was completed
      _loadCompletions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final firstDayOffset =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday -
        1; // 0 for Monday

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildMonthSelector(),
                          const SizedBox(height: 24),
                          _buildCalendarGrid(daysInMonth, firstDayOffset),
                          const SizedBox(height: 32),
                          _buildDifficultyGuide(),
                          const SizedBox(height: 24),
                        ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.filledTonal(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Text(
            'Daily Challenges',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton.filledTonal(
            onPressed: _loadCompletions,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final theme = Theme.of(context);
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month - 1,
                  );
                });
              },
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text(
              '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month + 1,
                  );
                });
              },
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(int daysInMonth, int firstDayOffset) {
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final theme = Theme.of(context);
    final today = DateTime.now();

    List<Widget> dayWidgets = [];

    // Weekdays label row
    for (var day in weekdays) {
      dayWidgets.add(
        Center(
          child: Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
        ),
      );
    }

    // Offset empty spaces for first week of month
    for (int i = 0; i < firstDayOffset; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    // Days numbers
    for (int day = 1; day <= daysInMonth; day++) {
      final cellDate = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final String cellDateStr =
          '${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}';
      final bool isCompleted = _completedDates.contains(cellDateStr);
      final bool isToday =
          today.year == cellDate.year &&
          today.month == cellDate.month &&
          today.day == cellDate.day;
      final bool isFuture = cellDate.isAfter(today);

      final difficulty = _getDifficultyForDay(cellDate);
      final diffColor = _getDifficultyColor(difficulty);

      dayWidgets.add(
        GestureDetector(
          onTap: isFuture ? null : () => _playChallenge(cellDate),
          child: Opacity(
            opacity: isFuture ? 0.35 : 1.0,
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isToday
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                border: Border.all(
                  color: isToday
                      ? theme.colorScheme.primary
                      : diffColor.withValues(alpha: 0.3),
                  width: isToday ? 2.0 : 1.0,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Day number
                  Text(
                    '$day',
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),

                  // Small dot showing difficulty
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: diffColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // Gold Crown for completion
                  if (isCompleted)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.0,
      children: dayWidgets,
    );
  }

  Widget _buildDifficultyGuide() {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Challenge Difficulty Rules',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildGuideDot(Colors.green, 'Mon & Tue: Easy'),
                const Spacer(),
                _buildGuideDot(Colors.orange, 'Wed & Thu: Medium'),
                const Spacer(),
                _buildGuideDot(Colors.red, 'Fri - Sun: Hard'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
