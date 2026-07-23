import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/prefs_keys.dart';

/// Manages reproducible daily challenge seed puzzles, completion calendar, and streak tracking.
class DailyChallengeManager {
  static const String _completedDatesKey = 'daily_challenge_completed_dates';
  static const String _currentStreakKey = 'daily_challenge_current_streak';
  static const String _bestStreakKey = 'daily_challenge_best_streak';

  /// Generates a reproducible 8-digit date key for the given DateTime (e.g., "20260723").
  static String getDateKey([DateTime? date]) {
    final d = date ?? DateTime.now();
    final year = d.year.toString().padLeft(4, '0');
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  /// Calculates a deterministic seed integer based on date.
  static int getSeedForDate(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  /// Loads set of completed date strings ("YYYYMMDD").
  static Future<Set<String>> getCompletedDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_completedDatesKey);
      if (list != null) {
        return list.toSet();
      }
    } catch (e) {
      debugPrint('Error loading completed dates: $e');
    }
    return {};
  }

  /// Marks a specific date as completed, updating streaks.
  static Future<void> markDateCompleted(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = await getCompletedDates();
      final key = getDateKey(date);

      if (!completed.contains(key)) {
        completed.add(key);
        await prefs.setStringList(_completedDatesKey, completed.toList());

        // Update streak
        int currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
        int bestStreak = prefs.getInt(_bestStreakKey) ?? 0;

        // Check if yesterday was completed
        final yesterdayKey = getDateKey(date.subtract(const Duration(days: 1)));
        if (completed.contains(yesterdayKey) || currentStreak == 0) {
          currentStreak++;
        } else {
          currentStreak = 1;
        }

        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }

        await prefs.setInt(_currentStreakKey, currentStreak);
        await prefs.setInt(_bestStreakKey, bestStreak);
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
