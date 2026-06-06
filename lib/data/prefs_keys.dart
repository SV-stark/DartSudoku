/// Centralized storage keys for SharedPreferences to avoid keys desynchronization.
class PrefsKeys {
  PrefsKeys._();

  // App Theme Key
  static const String themeMode = 'sudoku_app_theme_mode';

  // Stats Key
  static const String stats = 'sudoku_nexus_stats'; // Legacy key name preserved for compatibility

  // Settings Keys
  static const String showMistakes = 'show_mistakes';
  static const String highlightConflicts = 'highlight_conflicts';
  static const String highlightIdentical = 'highlight_identical';
  static const String endlessMode = 'endless_mode';
  static const String autoRemoveNotes = 'auto_remove_notes';

  // Save Game Keys
  static const String savedDifficulty = 'saved_difficulty';
  static const String savedDailyDate = 'saved_daily_date';
  static const String savedCurrentBoard = 'saved_current_board';
  static const String savedSolvedBoard = 'saved_solved_board';
  static const String savedIsOriginalClue = 'saved_is_original_clue';
  static const String savedNotes = 'saved_notes';
  static const String savedMistakes = 'saved_mistakes';
  static const String savedElapsedSeconds = 'saved_elapsed_seconds';
  static const String hasSavedGame = 'has_saved_game';

  // Daily Challenge Keys
  static const String completedDailyChallenges = 'completed_daily_challenges';

  // Sudoku School Progress Keys
  static const String completedLessons = 'completed_lessons';
  static const String practiceCounts = 'practice_counts';
  static const String timeAttackHighScore = 'time_attack_high_score';
  static const String totalMistakesMade = 'total_mistakes_made';
  static const String stage0SolveTimes = 'stage0_solve_times';
}
