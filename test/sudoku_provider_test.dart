import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_sudoku/providers/sudoku_provider.dart';
import 'package:dart_sudoku/providers/settings_provider.dart';
import 'package:dart_sudoku/core/difficulty.dart';
import 'package:dart_sudoku/core/sudoku_logic.dart';
import 'package:dart_sudoku/core/daily_challenge_manager.dart';
import 'package:dart_sudoku/core/achievements_manager.dart';
import 'package:dart_sudoku/core/stats_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SudokuGameProvider Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      StatsManager.resetCache();
      await SettingsProvider.instance.loadSettings();
    });

    test('Initial state should be correct', () {
      final provider = SudokuGameProvider();
      expect(provider.status, GameStatus.idle);
      expect(provider.difficulty, Difficulty.easy);
      expect(provider.selectedRow, -1);
      expect(provider.selectedCol, -1);
      expect(provider.mistakes, 0);
      expect(provider.notesMode, false);
      expect(provider.elapsedSeconds, 0);
      expect(provider.canUndo, false);
      expect(provider.canRedo, false);
    });

    test('newGame should initialize board state correctly', () async {
      final provider = SudokuGameProvider();
      await provider.newGame(Difficulty.medium);

      expect(provider.status, GameStatus.playing);
      expect(provider.difficulty, Difficulty.medium);
      expect(provider.selectedRow, -1);
      expect(provider.selectedCol, -1);
      expect(provider.mistakes, 0);

      // Verify boards are populated
      int emptyCells = 0;
      int clues = 0;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (provider.currentBoard[r][c] == 0) {
            emptyCells++;
          }
          if (provider.isOriginalClue[r][c]) {
            clues++;
          }
        }
      }
      expect(clues + emptyCells, 81);
      expect(clues, provider.totalClues);
    });

    test('selectCell should update selected coordinate', () async {
      final provider = SudokuGameProvider();
      await provider.newGame(Difficulty.easy);

      provider.selectCell(2, 3);
      expect(provider.selectedRow, 2);
      expect(provider.selectedCol, 3);
    });

    test(
      'enterNumber should input values and handle correct/incorrect inputs',
      () async {
        final provider = SudokuGameProvider();
        await provider.newGame(Difficulty.easy);

        // Find an empty cell that is NOT a clue
        int emptyRow = -1;
        int emptyCol = -1;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (!provider.isOriginalClue[r][c]) {
              emptyRow = r;
              emptyCol = c;
              break;
            }
          }
          if (emptyRow != -1) break;
        }

        provider.selectCell(emptyRow, emptyCol);
        final correctValue = provider.solvedBoard[emptyRow][emptyCol];

        // Enter a wrong value (different from correct value, between 1-9)
        final wrongValue = correctValue == 9 ? 8 : correctValue + 1;
        await provider.enterNumber(wrongValue);

        expect(provider.currentBoard[emptyRow][emptyCol], wrongValue);
        expect(provider.mistakes, 1);

        // Enter correct value
        await provider.enterNumber(correctValue);
        expect(provider.currentBoard[emptyRow][emptyCol], correctValue);
        // Mistakes count should not decrease
        expect(provider.mistakes, 1);
      },
    );

    test(
      'undo and redo should step back and forward through changes',
      () async {
        final provider = SudokuGameProvider();
        await provider.newGame(Difficulty.easy);

        int emptyRow = -1;
        int emptyCol = -1;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (!provider.isOriginalClue[r][c]) {
              emptyRow = r;
              emptyCol = c;
              break;
            }
          }
          if (emptyRow != -1) break;
        }

        provider.selectCell(emptyRow, emptyCol);
        final val = provider.solvedBoard[emptyRow][emptyCol];

        await provider.enterNumber(val);
        expect(provider.currentBoard[emptyRow][emptyCol], val);
        expect(provider.canUndo, true);

        await provider.undo();
        expect(provider.currentBoard[emptyRow][emptyCol], 0);
        expect(provider.canRedo, true);

        await provider.redo();
        expect(provider.currentBoard[emptyRow][emptyCol], val);
      },
    );

    test('toggleNotesMode and entering notes works correctly', () async {
      final provider = SudokuGameProvider();
      await provider.newGame(Difficulty.easy);

      int emptyRow = -1;
      int emptyCol = -1;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (!provider.isOriginalClue[r][c]) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
        if (emptyRow != -1) break;
      }

      provider.selectCell(emptyRow, emptyCol);
      provider.toggleNotesMode();
      expect(provider.notesMode, true);

      // Enter note 5
      await provider.enterNumber(5);
      expect(provider.notes[emptyRow][emptyCol].contains(5), true);
      expect(provider.currentBoard[emptyRow][emptyCol], 0);

      // Toggle note 5 again to remove
      await provider.enterNumber(5);
      expect(provider.notes[emptyRow][emptyCol].contains(5), false);
    });

    test(
      'save and load game state preserves state in shared preferences',
      () async {
        final provider = SudokuGameProvider();
        await provider.newGame(Difficulty.hard);

        // Make a move
        int emptyRow = -1;
        int emptyCol = -1;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (!provider.isOriginalClue[r][c]) {
              emptyRow = r;
              emptyCol = c;
              break;
            }
          }
          if (emptyRow != -1) break;
        }

        provider.selectCell(emptyRow, emptyCol);
        final val = provider.solvedBoard[emptyRow][emptyCol];
        await provider.enterNumber(val);

        final originalDifficulty = provider.difficulty;
        final originalBoard = List.generate(
          9,
          (r) => List<int>.from(provider.currentBoard[r]),
        );

        final newProvider = SudokuGameProvider();
        await newProvider.loadSavedGame();

        expect(newProvider.difficulty, originalDifficulty);
        expect(newProvider.status, GameStatus.playing);
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            expect(newProvider.currentBoard[r][c], originalBoard[r][c]);
          }
        }
      },
    );

    test('initialBoard remains unchanged when player makes moves', () async {
      final provider = SudokuGameProvider();
      await provider.newGame(Difficulty.easy);

      final clonedInitial = List.generate(
        9,
        (r) => List<int>.from(provider.initialBoard[r]),
      );

      // Find an empty cell and enter a number
      int emptyRow = -1;
      int emptyCol = -1;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (!provider.isOriginalClue[r][c]) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
        if (emptyRow != -1) break;
      }

      provider.selectCell(emptyRow, emptyCol);
      final val = provider.solvedBoard[emptyRow][emptyCol];
      await provider.enterNumber(val);

      // currentBoard has mutated, but initialBoard must NOT have mutated
      expect(provider.currentBoard[emptyRow][emptyCol], val);
      expect(provider.initialBoard[emptyRow][emptyCol], clonedInitial[emptyRow][emptyCol]);
      expect(provider.initialBoard[emptyRow][emptyCol], 0);
    });

    test('undo restores mistakes count when retracting a mistake', () async {
      final provider = SudokuGameProvider();
      await provider.newGame(Difficulty.easy);

      int emptyRow = -1;
      int emptyCol = -1;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (!provider.isOriginalClue[r][c]) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
        if (emptyRow != -1) break;
      }

      provider.selectCell(emptyRow, emptyCol);
      final correctVal = provider.solvedBoard[emptyRow][emptyCol];
      final wrongVal = (correctVal % 9) + 1;

      expect(provider.mistakes, 0);
      await provider.enterNumber(wrongVal);
      expect(provider.mistakes, 1);

      await provider.undo();
      expect(provider.mistakes, 0);
      expect(provider.currentBoard[emptyRow][emptyCol], 0);
    });

    test('entering identical digit does not record ghost MoveRecord', () async {
      final provider = SudokuGameProvider();
      await provider.newGame(Difficulty.easy);

      int emptyRow = -1;
      int emptyCol = -1;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (!provider.isOriginalClue[r][c]) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
        if (emptyRow != -1) break;
      }

      provider.selectCell(emptyRow, emptyCol);
      final correctVal = provider.solvedBoard[emptyRow][emptyCol];

      await provider.enterNumber(correctVal);
      expect(provider.moveHistory.length, 1);

      // Entering same number on same cell again should early return without adding MoveRecord
      await provider.enterNumber(correctVal);
      expect(provider.moveHistory.length, 1);
    });

    test('variants and killer cages are preserved across save and load', () async {
      final provider = SudokuGameProvider();
      await provider.newGame(
        Difficulty.medium,
        variant: SudokuVariant.killer,
      );

      expect(provider.activeVariant, SudokuVariant.killer);
      expect(provider.killerCages, isNotNull);
      expect(provider.killerCages!.isNotEmpty, true);

      final cageCount = provider.killerCages!.length;
      await provider.pauseGame(); // Trigger save game state

      final newProvider = SudokuGameProvider();
      await newProvider.loadSavedGame();

      expect(newProvider.activeVariant, SudokuVariant.killer);
      expect(newProvider.killerCages, isNotNull);
      expect(newProvider.killerCages!.length, cageCount);
    });

    test('DailyChallengeManager streak calculation and streak_7 unlock', () async {
      final baseDate = DateTime(2026, 7, 1);

      for (int i = 0; i < 7; i++) {
        await DailyChallengeManager.markDateCompleted(
          baseDate.add(Duration(days: i)),
        );
      }

      final bestStreak = await DailyChallengeManager.getBestStreak();
      expect(bestStreak, greaterThanOrEqualTo(7));

      final achievements = await AchievementsManager.getAchievements();
      final streak7 = achievements.firstWhere((a) => a.id == 'streak_7');
      expect(streak7.isUnlocked, true);
    });

    test('SettingsProvider sound and haptics persistence', () async {
      final settings = SettingsProvider.instance;
      await settings.updateSettings(
        soundEnabled: false,
        hapticsEnabled: false,
      );

      expect(settings.soundEnabled, false);
      expect(settings.hapticsEnabled, false);

      await settings.loadSettings();
      expect(settings.soundEnabled, false);
      expect(settings.hapticsEnabled, false);

      // Reset to defaults
      await settings.updateSettings(
        soundEnabled: true,
        hapticsEnabled: true,
      );
      expect(settings.soundEnabled, true);
      expect(settings.hapticsEnabled, true);
    });
  });
}
