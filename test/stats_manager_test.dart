import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_sudoku/core/stats_manager.dart';
import 'package:dart_sudoku/core/difficulty.dart';
import 'package:dart_sudoku/data/prefs_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StatsManager Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      StatsManager.resetCache();
    });

    test('getStats should return default stats when no data exists', () async {
      final stats = await StatsManager.getStats();
      expect(stats.currentStreak, 0);
      expect(stats.maxStreak, 0);
      expect(stats.difficultyStats['easy']!.gamesPlayed, 0);
      expect(stats.difficultyStats['medium']!.gamesPlayed, 0);
      expect(stats.difficultyStats['hard']!.gamesPlayed, 0);
    });

    test(
      'getStats should return default stats on JSON decode failure',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(PrefsKeys.stats, 'invalid json data{');

        final stats = await StatsManager.getStats();
        expect(stats.currentStreak, 0);
        expect(stats.difficultyStats['easy']!.gamesPlayed, 0);
      },
    );

    test(
      'recordGameStart should increment gamesPlayed for difficulty',
      () async {
        await StatsManager.recordGameStart(Difficulty.easy);
        var stats = await StatsManager.getStats();
        expect(stats.difficultyStats['easy']!.gamesPlayed, 1);
        expect(stats.difficultyStats['medium']!.gamesPlayed, 0);

        await StatsManager.recordGameStart(Difficulty.easy);
        await StatsManager.recordGameStart(Difficulty.medium);
        stats = await StatsManager.getStats();
        expect(stats.difficultyStats['easy']!.gamesPlayed, 2);
        expect(stats.difficultyStats['medium']!.gamesPlayed, 1);
      },
    );

    test(
      'recordGameWin should update won count, streaks, best time, and average time',
      () async {
        await StatsManager.recordGameWin(Difficulty.easy, 300); // 5 minutes
        var stats = await StatsManager.getStats();
        var easyStats = stats.difficultyStats['easy']!;

        expect(easyStats.gamesWon, 1);
        expect(easyStats.totalTime, 300);
        expect(easyStats.bestTime, 300);
        expect(easyStats.averageTime, 300.0);
        expect(stats.currentStreak, 1);
        expect(stats.maxStreak, 1);
        expect(easyStats.topTimes.length, 1);
        expect(easyStats.topTimes.first.timeInSeconds, 300);

        // Record a slower win
        await StatsManager.recordGameWin(Difficulty.easy, 400);
        stats = await StatsManager.getStats();
        easyStats = stats.difficultyStats['easy']!;
        expect(easyStats.gamesWon, 2);
        expect(easyStats.totalTime, 700);
        expect(easyStats.bestTime, 300); // Should stay 300
        expect(easyStats.averageTime, 350.0);
        expect(stats.currentStreak, 2);
        expect(stats.maxStreak, 2);
        expect(easyStats.topTimes.length, 2);
        // Top times should be sorted
        expect(easyStats.topTimes[0].timeInSeconds, 300);
        expect(easyStats.topTimes[1].timeInSeconds, 400);
      },
    );

    test('recordGameWin should cap topTimes at 5 and sort them', () async {
      // Record 6 wins with varying times
      await StatsManager.recordGameWin(Difficulty.easy, 500);
      await StatsManager.recordGameWin(Difficulty.easy, 300);
      await StatsManager.recordGameWin(Difficulty.easy, 600);
      await StatsManager.recordGameWin(Difficulty.easy, 200);
      await StatsManager.recordGameWin(Difficulty.easy, 400);
      await StatsManager.recordGameWin(Difficulty.easy, 100);

      final stats = await StatsManager.getStats();
      final easyStats = stats.difficultyStats['easy']!;

      expect(easyStats.topTimes.length, 5); // Capped at 5
      // Verify sorted order
      expect(easyStats.topTimes[0].timeInSeconds, 100);
      expect(easyStats.topTimes[1].timeInSeconds, 200);
      expect(easyStats.topTimes[2].timeInSeconds, 300);
      expect(easyStats.topTimes[3].timeInSeconds, 400);
      expect(easyStats.topTimes[4].timeInSeconds, 500);
      // 600 should have been discarded
    });

    test(
      'recordGameLoss should reset currentStreak but preserve maxStreak',
      () async {
        await StatsManager.recordGameWin(Difficulty.easy, 300);
        await StatsManager.recordGameWin(Difficulty.easy, 200);
        var stats = await StatsManager.getStats();
        expect(stats.currentStreak, 2);
        expect(stats.maxStreak, 2);

        await StatsManager.recordGameLoss();
        stats = await StatsManager.getStats();
        expect(stats.currentStreak, 0);
        expect(stats.maxStreak, 2);
      },
    );

    test('resetStats should clear SharedPreferences key completely', () async {
      await StatsManager.recordGameWin(Difficulty.easy, 300);
      var stats = await StatsManager.getStats();
      expect(stats.difficultyStats['easy']!.gamesWon, 1);

      await StatsManager.resetStats();
      stats = await StatsManager.getStats();
      expect(stats.difficultyStats['easy']!.gamesWon, 0);
    });
  });
}
