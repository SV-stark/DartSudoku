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

/// Manages unlockable badges and trophy progress.
class AchievementsManager {
  static const String _unlockedKey = 'unlocked_achievements';

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

  /// Unlocks an achievement by ID.
  static Future<bool> unlock(String achievementId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlockedList = prefs.getStringList(_unlockedKey) ?? [];
      if (!unlockedList.contains(achievementId)) {
        unlockedList.add(achievementId);
        await prefs.setStringList(_unlockedKey, unlockedList);
        return true; // Newly unlocked!
      }
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
    return false;
  }
}
