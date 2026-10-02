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
        // Single source of truth. The legacy key is only written when the
        // dedicated key was previously empty, so upgrading users keep their
        // history exactly once instead of accumulating two divergent lists.
        if (prefs.getStringList(PrefsKeys.completedDailyChallenges) == null) {
          await prefs.setStringList(_legacyCompletedDatesKey, list);
        }
        await prefs.setStringList(PrefsKeys.completedDailyChallenges, list);
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
            final parsed = DateTime(y, m, d);
            // Guard against junk like "2026-02-31" rolling into March.
            if (parsed.year == y && parsed.month == m && parsed.day == d) {
              sortedDates.add(parsed);
            }
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
          // Calendar-day difference, not elapsed hours. `difference().inDays`
          // under-reports across a DST boundary, which broke streaks for
          // players in DST timezones.
          final diff = d.difference(prev).inDays;
          if (diff == 1) {
            tempStreak++;
          } else if (diff > 1) {
            tempStreak = 1;
          } else {
            // Same day recorded twice (duplicate data): leave the run intact.
            continue;
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
      final yesterday = DateTime(today.year, today.month, today.day - 1);

      int currentStreak = 0;
      final dateSet = sortedDates.map(getDateKey).toSet();

      var checkDate = dateSet.contains(getDateKey(today)) ? today : yesterday;
      // Bound the walk so a corrupt date set can never spin forever.
      while (currentStreak <= bestStreak &&
          dateSet.contains(getDateKey(checkDate))) {
        currentStreak++;
        // Calendar arithmetic keeps DST out of the picture.
        checkDate = DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day - 1,
        );
      }

      await prefs.setInt(_currentStreakKey, currentStreak);
      await prefs.setInt(_bestStreakKey, bestStreak);

      if (bestStreak >= 7) {
        await AchievementsManager.unlock('streak_7');
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
