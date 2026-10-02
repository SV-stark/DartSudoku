import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single unlockable achievement badge in DartSudoku.
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
  });

  Achievement copyWith({bool? isUnlocked}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}

enum AchievementUnlockResult {
  unlocked,
  alreadyUnlocked,
  error,
}

/// Manages unlockable badges and trophy progress.
class AchievementsManager {
  static const String _unlockedKey = 'unlocked_achievements';

  /// Tail of the serialisation chain used by [_synchronized].
  static Future<void> _lock = Future<void>.value();

  /// Runs [action] after every previously queued action has settled, so
  /// read-modify-write cycles against SharedPreferences cannot interleave.
  static Future<T> _synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _lock = _lock.catchError((Object _) {}).then((_) async {
      try {
        completer.complete(await action());
      } catch (e, stack) {
        completer.completeError(e, stack);
      }
    });
    return completer.future;
  }

  static final List<Achievement> _defaultAchievements = [
    const Achievement(
      id: 'first_win',
      title: 'First Step',
      description: 'Solve your very first Sudoku puzzle!',
      icon: Icons.emoji_events_rounded,
    ),
    const Achievement(
      id: 'speed_demon',
      title: 'Speed Demon',
      description: 'Complete a puzzle in under 3 minutes.',
      icon: Icons.bolt_rounded,
    ),
    const Achievement(
      id: 'streak_7',
      title: 'Weekly Warrior',
      description: 'Maintain a 7-day Daily Challenge streak.',
      icon: Icons.local_fire_department_rounded,
    ),
    const Achievement(
      id: 'school_grad',
      title: 'Sudoku Scholar',
      description: 'Complete all Tier 1 Sudoku School lessons.',
      icon: Icons.school_rounded,
    ),
    const Achievement(
      id: 'master_tactician',
      title: 'Master Tactician',
      description: 'Solve a Hard difficulty puzzle without using any hints.',
      icon: Icons.psychology_rounded,
    ),
  ];

  /// Loads all achievements with their unlocked state.
  static Future<List<Achievement>> getAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlockedSet = (prefs.getStringList(_unlockedKey) ?? []).toSet();

      return _defaultAchievements.map((ach) {
        return ach.copyWith(isUnlocked: unlockedSet.contains(ach.id));
      }).toList();
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      return _defaultAchievements;
    }
  }

  /// Unlocks an achievement by ID with detailed status.
  ///
  /// Serialised through [_lock]: two concurrent unlocks (e.g. a daily-challenge
  /// streak firing at the same moment as a win) each read the list, added their
  /// own ID and wrote it back, so the slower write clobbered the faster one and
  /// an achievement was silently lost.
  static Future<AchievementUnlockResult> unlockDetailed(
    String achievementId,
  ) {
    return _synchronized(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final unlockedList = prefs.getStringList(_unlockedKey) ?? [];
        if (unlockedList.contains(achievementId)) {
          return AchievementUnlockResult.alreadyUnlocked;
        }
        await prefs.setStringList(_unlockedKey, [
          ...unlockedList,
          achievementId,
        ]);
        return AchievementUnlockResult.unlocked;
      } catch (e, stack) {
        debugPrint(
          'Error unlocking achievement "$achievementId": $e\n$stack',
        );
        return AchievementUnlockResult.error;
      }
    });
  }

  /// Clears every unlocked achievement. Used by "reset all progress".
  static Future<void> resetAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_unlockedKey);
    } catch (e, stack) {
      debugPrint('Error resetting achievements: $e\n$stack');
    }
  }

  /// Unlocks an achievement by ID. Returns true if newly unlocked.
  static Future<bool> unlock(String achievementId) async {
    final result = await unlockDetailed(achievementId);
    return result == AchievementUnlockResult.unlocked;
  }
}
