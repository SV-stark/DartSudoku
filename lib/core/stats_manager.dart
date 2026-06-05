import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single best time record with a date.
class TimeRecord {
  final int timeInSeconds;
  final String date;

  TimeRecord({required this.timeInSeconds, required this.date});

  Map<String, dynamic> toJson() => {
    'timeInSeconds': timeInSeconds,
    'date': date,
  };

  factory TimeRecord.fromJson(Map<String, dynamic> json) {
    return TimeRecord(
      timeInSeconds: json['timeInSeconds'] ?? 0,
      date: json['date'] ?? '',
    );
  }
}

/// Representation of stats for a single difficulty level.
class SudokuStats {
  int gamesPlayed = 0;
  int gamesWon = 0;
  int bestTime = 0; // in seconds, 0 means no record yet
  int totalTime = 0; // in seconds
  List<TimeRecord> topTimes = [];

  SudokuStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.bestTime = 0,
    this.totalTime = 0,
    List<TimeRecord>? topTimes,
  }) : topTimes = topTimes ?? [];

  Map<String, dynamic> toJson() => {
    'gamesPlayed': gamesPlayed,
    'gamesWon': gamesWon,
    'bestTime': bestTime,
    'totalTime': totalTime,
    'topTimes': topTimes.map((t) => t.toJson()).toList(),
  };

  factory SudokuStats.fromJson(Map<String, dynamic> json) {
    var rawTop = json['topTimes'] as List<dynamic>? ?? [];
    var topList = rawTop
        .map((t) => TimeRecord.fromJson(Map<String, dynamic>.from(t)))
        .toList();

    return SudokuStats(
      gamesPlayed: json['gamesPlayed'] ?? 0,
      gamesWon: json['gamesWon'] ?? 0,
      bestTime: json['bestTime'] ?? 0,
      totalTime: json['totalTime'] ?? 0,
      topTimes: topList,
    );
  }

  double get averageTime {
    if (gamesWon == 0) return 0.0;
    return totalTime / gamesWon;
  }
}

/// Overall stats container holding streaks and stats per difficulty.
class GameStats {
  final Map<String, SudokuStats> difficultyStats;
  int currentStreak = 0;
  int maxStreak = 0;

  GameStats({
    required this.difficultyStats,
    this.currentStreak = 0,
    this.maxStreak = 0,
  });

  factory GameStats.defaultStats() {
    return GameStats(
      difficultyStats: {
        'easy': SudokuStats(),
        'medium': SudokuStats(),
        'hard': SudokuStats(),
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'difficultyStats': difficultyStats.map((k, v) => MapEntry(k, v.toJson())),
    'currentStreak': currentStreak,
    'maxStreak': maxStreak,
  };

  factory GameStats.fromJson(Map<String, dynamic> json) {
    var diffStats = <String, SudokuStats>{};
    var rawDiff = json['difficultyStats'] as Map<String, dynamic>? ?? {};
    rawDiff.forEach((key, value) {
      diffStats[key] = SudokuStats.fromJson(Map<String, dynamic>.from(value));
    });

    // Ensure all difficulties are present
    for (var diff in ['easy', 'medium', 'hard']) {
      diffStats.putIfAbsent(diff, () => SudokuStats());
    }

    return GameStats(
      difficultyStats: diffStats,
      currentStreak: json['currentStreak'] ?? 0,
      maxStreak: json['maxStreak'] ?? 0,
    );
  }
}

/// Helper class to load/save stats in persistent storage.
class StatsManager {
  static const String _key = 'sudoku_nexus_stats';

  /// Load all game stats from SharedPreferences
  static Future<GameStats> getStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_key);
      if (data == null) {
        return GameStats.defaultStats();
      }
      return GameStats.fromJson(jsonDecode(data));
    } catch (_) {
      return GameStats.defaultStats();
    }
  }

  /// Save game stats to SharedPreferences
  static Future<void> saveStats(GameStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(stats.toJson()));
    } catch (_) {}
  }

  /// Increment played games for a difficulty level
  static Future<void> recordGameStart(String difficulty) async {
    final stats = await getStats();
    stats.difficultyStats[difficulty.toLowerCase()]?.gamesPlayed++;
    await saveStats(stats);
  }

  /// Increment won games, update best/total time, and update win streaks
  static Future<void> recordGameWin(String difficulty, int seconds) async {
    final stats = await getStats();
    final diff = difficulty.toLowerCase();
    final diffStats = stats.difficultyStats[diff]!;

    diffStats.gamesWon++;
    diffStats.totalTime += seconds;

    if (diffStats.bestTime == 0 || seconds < diffStats.bestTime) {
      diffStats.bestTime = seconds;
    }

    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';

    final record = TimeRecord(timeInSeconds: seconds, date: dateStr);
    diffStats.topTimes.add(record);
    diffStats.topTimes.sort(
      (a, b) => a.timeInSeconds.compareTo(b.timeInSeconds),
    );
    if (diffStats.topTimes.length > 5) {
      diffStats.topTimes = diffStats.topTimes.sublist(0, 5);
    }

    stats.currentStreak++;
    if (stats.currentStreak > stats.maxStreak) {
      stats.maxStreak = stats.currentStreak;
    }

    await saveStats(stats);
  }

  /// Reset the current win streak to 0
  static Future<void> recordGameLoss() async {
    final stats = await getStats();
    stats.currentStreak = 0;
    await saveStats(stats);
  }

  /// Clear all stats history
  static Future<void> resetStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
