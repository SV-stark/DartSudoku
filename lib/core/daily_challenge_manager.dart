import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/prefs_keys.dart';
import 'achievements_manager.dart';

/// Manages reproducible daily challenge seed puzzles, completion calendar, and streak tracking.
class DailyChallengeManager {
  static const String _legacyCompletedDatesKey =
      'daily_challenge_completed_dates';
  static const String _currentStreakKey = 'daily_challenge_current_streak';
  static const String _bestStreakKey = 'daily_challenge_best_streak';

  /// Generates a standardized "YYYY-MM-DD" date key for the given DateTime.
  static String getDateKey([DateTime? date]) {
    final d = date ?? DateTime.now();
    final year = d.year.toString().padLeft(4, '0');
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Helper to normalize any date string ("YYYY-MM-DD" or "YYYYMMDD") to "YYYY-MM-DD".
  static String _normalizeDateKey(String key) {
    if (key.contains('-')) return key;
    if (key.length == 8) {
      final y = key.substring(0, 4);
      final m = key.substring(4, 6);
      final d = key.substring(6, 8);
      return '$y-$m-$d';
    }
    return key;
  }

  /// Calculates a deterministic seed integer based on date.
  static int getSeedForDate(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  /// Loads set of completed date strings in "YYYY-MM-DD" format.
  static Future<Set<String>> getCompletedDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list1 =
          prefs.getStringList(PrefsKeys.completedDailyChallenges) ?? [];
      final list2 = prefs.getStringList(_legacyCompletedDatesKey) ?? [];

      final set = <String>{};
      for (final item in [...list1, ...list2]) {
        set.add(_normalizeDateKey(item));
      }
      return set;
    } catch (e) {
      debugPrint('Error loading completed dates in DailyChallengeManager: $e');
      return {};
    }
  }

  /// Marks a specific date as completed and recalculates streaks properly.
  static Future<void> markDateCompleted(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = await getCompletedDates();
      final key = getDateKey(date);

      if (!completed.contains(key)) {
        completed.add(key);
        final list = completed.toList();
        await prefs.setStringList(PrefsKeys.completedDailyChallenges, list);
        await prefs.setStringList(_legacyCompletedDatesKey, list);
      }

      // Recalculate streak deterministically based on all completed dates
      final sortedDates = <DateTime>[];
      for (final dStr in completed) {
        final parts = dStr.split('-');
        if (parts.length == 3) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) {
            sortedDates.add(DateTime(y, m, d));
          }
        }
      }

      sortedDates.sort((a, b) => a.compareTo(b));

      int bestStreak = 0;
      int tempStreak = 0;
      DateTime? prev;

      for (final d in sortedDates) {
        if (prev == null) {
          tempStreak = 1;
        } else {
          final diff = d.difference(prev).inDays;
          if (diff == 1) {
            tempStreak++;
          } else if (diff > 1) {
            tempStreak = 1;
          }
        }
        if (tempStreak > bestStreak) {
          bestStreak = tempStreak;
        }
        prev = d;
      }

      // Calculate current streak
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      int currentStreak = 0;
      final dateSet = sortedDates
          .map((d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}')
          .toSet();

      DateTime checkDate = dateSet.contains(getDateKey(today)) ? today : yesterday;
      while (dateSet.contains(getDateKey(checkDate))) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      await prefs.setInt(_currentStreakKey, currentStreak);
      await prefs.setInt(_bestStreakKey, bestStreak);

      if (currentStreak >= 7 || bestStreak >= 7) {
        AchievementsManager.unlock('streak_7');
      }
    } catch (e) {
      debugPrint('Error marking date completed: $e');
    }
  }

  /// Returns current active streak count.
  static Future<int> getCurrentStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_currentStreakKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Returns best streak count.
  static Future<int> getBestStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_bestStreakKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
