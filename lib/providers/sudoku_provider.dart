import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/sudoku_logic.dart';
import '../core/stats_manager.dart';
import '../data/prefs_keys.dart';

/// Represents a snapshot of the board state for undo functionality.
class BoardState {
  final List<List<int>> board;
  final List<List<Set<int>>> notes;

  BoardState({required this.board, required this.notes});

  BoardState clone() {
    return BoardState(
      board: List.generate(9, (r) => List.from(board[r])),
      notes: List.generate(
        9,
        (r) => List.generate(9, (c) => Set.from(notes[r][c])),
      ),
    );
  }
}

enum GameStatus { idle, loading, playing, paused, won, gameOver }

/// Manages the state of the active play game.
class SudokuGameProvider extends ChangeNotifier {
  final ChangeNotifier selectionNotifier = ChangeNotifier();
  final ChangeNotifier timerNotifier = ChangeNotifier();

  List<List<int>> _currentBoard = List.generate(9, (_) => List.filled(9, 0));
  List<List<int>> _solvedBoard = List.generate(9, (_) => List.filled(9, 0));
  List<List<bool>> _isOriginalClue = List.generate(
    9,
    (_) => List.filled(9, false),
  );
  List<List<Set<int>>> _notes = List.generate(
    9,
    (_) => List.generate(9, (_) => {}),
  );

  int _selectedRow = -1;
  int _selectedCol = -1;

  int _mistakes = 0;
  final int maxMistakes = 3;
  String _difficulty = 'easy';
  String? _dailyChallengeDate;
  GameStatus _status = GameStatus.idle;

  bool _notesMode = false;
  int _elapsedSeconds = 0;
  Timer? _timer;

  final List<BoardState> _undoHistory = [];
  final List<BoardState> _redoHistory = [];

  int _flashRow = -1;
  int _flashCol = -1;

  // Settings properties
  bool _showMistakes = true;
  bool _highlightConflicts = true;
  bool _highlightIdentical = true;
  bool _endlessMode = false;
  bool _autoRemoveNotes = true;

  SudokuGameProvider() {
    loadSettings();
  }

  // Getters
  List<List<int>> get currentBoard => _currentBoard;
  List<List<int>> get solvedBoard => _solvedBoard;
  List<List<bool>> get isOriginalClue => _isOriginalClue;
  List<List<Set<int>>> get notes => _notes;

  int get selectedRow => _selectedRow;
  int get selectedCol => _selectedCol;
  int get mistakes => _mistakes;
  String get difficulty => _difficulty;
  GameStatus get status => _status;
  bool get notesMode => _notesMode;
  int get elapsedSeconds => _elapsedSeconds;
  bool get canUndo => _undoHistory.isNotEmpty;
  bool get canRedo => _redoHistory.isNotEmpty;

  int get flashRow => _flashRow;
  int get flashCol => _flashCol;

  bool get showMistakes => _showMistakes;
  bool get highlightConflicts => _highlightConflicts;
  bool get highlightIdentical => _highlightIdentical;
  bool get endlessMode => _endlessMode;
  bool get autoRemoveNotes => _autoRemoveNotes;

  Map<int, int> get numberCounts {
    final counts = <int, int>{};
    for (int i = 1; i <= 9; i++) {
      counts[i] = 9;
    }
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final val = _currentBoard[r][c];
        if (val != 0) {
          counts[val] = (counts[val] ?? 9) - 1;
        }
      }
    }
    counts.forEach((key, value) {
      if (value < 0) counts[key] = 0;
    });
    return counts;
  }

  Future<void> updateSettings({
    bool? showMistakes,
    bool? highlightConflicts,
    bool? highlightIdentical,
    bool? endlessMode,
    bool? autoRemoveNotes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (showMistakes != null) {
      _showMistakes = showMistakes;
      await prefs.setBool(PrefsKeys.showMistakes, showMistakes);
    }
    if (highlightConflicts != null) {
      _highlightConflicts = highlightConflicts;
      await prefs.setBool(PrefsKeys.highlightConflicts, highlightConflicts);
    }
    if (highlightIdentical != null) {
      _highlightIdentical = highlightIdentical;
      await prefs.setBool(PrefsKeys.highlightIdentical, highlightIdentical);
    }
    if (endlessMode != null) {
      _endlessMode = endlessMode;
      await prefs.setBool(PrefsKeys.endlessMode, endlessMode);
    }
    if (autoRemoveNotes != null) {
      _autoRemoveNotes = autoRemoveNotes;
      await prefs.setBool(PrefsKeys.autoRemoveNotes, autoRemoveNotes);
    }
    notifyListeners();
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showMistakes = prefs.getBool(PrefsKeys.showMistakes) ?? true;
      _highlightConflicts = prefs.getBool(PrefsKeys.highlightConflicts) ?? true;
      _highlightIdentical = prefs.getBool(PrefsKeys.highlightIdentical) ?? true;
      _endlessMode = prefs.getBool(PrefsKeys.endlessMode) ?? false;
      _autoRemoveNotes = prefs.getBool(PrefsKeys.autoRemoveNotes) ?? true;
      notifyListeners();
    } catch (_) {}
  }

  String get formattedTime {
    int minutes = _elapsedSeconds ~/ 60;
    int seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void selectCell(int r, int c) {
    if (_status != GameStatus.playing) return;
    _selectedRow = r;
    _selectedCol = c;
    selectionNotifier.notifyListeners();
  }

  /// Start a new game with [difficulty], optionally seeded for a [dailyDate] challenge
  Future<void> newGame(String difficulty, {String? dailyDate}) async {
    _status = GameStatus.loading;
    notifyListeners();

    Random? random;
    if (dailyDate != null) {
      // Create a deterministic seed from the date string, e.g. "2026-06-05" -> 20260605
      final cleanDate = dailyDate.replaceAll('-', '');
      final seed = int.tryParse(cleanDate) ?? dailyDate.hashCode;
      random = Random(seed);
    }

    // Generate puzzle
    final puzzle = await Future.value(
      SudokuLogic.generatePuzzle(difficulty, random: random),
    );

    _difficulty = difficulty;
    _dailyChallengeDate = dailyDate;
    _currentBoard = SudokuLogic.copyBoard(puzzle.puzzleBoard);
    _solvedBoard = SudokuLogic.copyBoard(puzzle.solvedBoard);
    _isOriginalClue = List.generate(
      9,
      (r) => List.generate(9, (c) => puzzle.puzzleBoard[r][c] != 0),
    );
    _notes = List.generate(9, (_) => List.generate(9, (_) => {}));

    _selectedRow = -1;
    _selectedCol = -1;
    _mistakes = 0;
    _elapsedSeconds = 0;
    _notesMode = false;
    _undoHistory.clear();
    _redoHistory.clear();

    _status = GameStatus.playing;
    _startTimer();

    // Clear any previously saved active game since we started a new one
    await _clearSavedGame();

    // Only record standard starts if not in daily challenge mode
    if (dailyDate == null) {
      StatsManager.recordGameStart(difficulty);
    }
    notifyListeners();
  }

  void toggleNotesMode() {
    _notesMode = !_notesMode;
    notifyListeners();
  }

  /// Saves the current board state to undo history
  void _saveToHistory() {
    _redoHistory.clear(); // Clear redo history when a new action is performed!
    _undoHistory.add(
      BoardState(
        board: SudokuLogic.copyBoard(_currentBoard),
        notes: List.generate(
          9,
          (r) => List.generate(9, (c) => Set.from(_notes[r][c])),
        ),
      ),
    );
    // Limit history size to 20 to prevent excessive memory usage
    if (_undoHistory.length > 20) {
      _undoHistory.removeAt(0);
    }
  }

  void triggerFlash(int r, int c) {
    _flashRow = r;
    _flashCol = c;
    notifyListeners();
    Timer(const Duration(milliseconds: 400), () {
      _flashRow = -1;
      _flashCol = -1;
      notifyListeners();
    });
  }

  void _findAndFlashDifference(
    List<List<int>> oldBoard,
    List<List<int>> newBoard,
  ) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (oldBoard[r][c] != newBoard[r][c]) {
          triggerFlash(r, c);
          return;
        }
      }
    }
  }

  /// Performs an undo action
  void undo() {
    if (_status != GameStatus.playing || _undoHistory.isEmpty) return;

    _redoHistory.add(
      BoardState(
        board: SudokuLogic.copyBoard(_currentBoard),
        notes: List.generate(
          9,
          (r) => List.generate(9, (c) => Set.from(_notes[r][c])),
        ),
      ),
    );

    final prevState = _undoHistory.removeLast();
    final oldBoard = SudokuLogic.copyBoard(_currentBoard);
    _currentBoard = prevState.board;
    _notes = prevState.notes;

    _findAndFlashDifference(oldBoard, _currentBoard);
    notifyListeners();
    _saveGameState();
  }

  /// Performs a redo action
  void redo() {
    if (_status != GameStatus.playing || _redoHistory.isEmpty) return;

    _undoHistory.add(
      BoardState(
        board: SudokuLogic.copyBoard(_currentBoard),
        notes: List.generate(
          9,
          (r) => List.generate(9, (c) => Set.from(_notes[r][c])),
        ),
      ),
    );

    final nextState = _redoHistory.removeLast();
    final oldBoard = SudokuLogic.copyBoard(_currentBoard);
    _currentBoard = nextState.board;
    _notes = nextState.notes;

    _findAndFlashDifference(oldBoard, _currentBoard);
    notifyListeners();
    _saveGameState();
  }

  /// Input a number from the numpad
  void enterNumber(int number) {
    if (_status != GameStatus.playing) return;
    if (_selectedRow == -1 || _selectedCol == -1) return;
    if (_isOriginalClue[_selectedRow][_selectedCol]) return;

    if (_notesMode) {
      // Toggle note
      _saveToHistory();
      if (_notes[_selectedRow][_selectedCol].contains(number)) {
        _notes[_selectedRow][_selectedCol].remove(number);
      } else {
        _notes[_selectedRow][_selectedCol].add(number);
        _currentBoard[_selectedRow][_selectedCol] =
            0; // Clear cell if placing a note
      }
    } else {
      // Direct number input
      if (_currentBoard[_selectedRow][_selectedCol] == number) return;

      _saveToHistory();
      _currentBoard[_selectedRow][_selectedCol] = number;
      _notes[_selectedRow][_selectedCol].clear(); // Clear notes for this cell

      // Check if the number is correct compared to solution
      if (number != _solvedBoard[_selectedRow][_selectedCol]) {
        if (_showMistakes) {
          _mistakes++;
          if (!_endlessMode && _mistakes >= maxMistakes) {
            _status = GameStatus.gameOver;
            _stopTimer();
            _clearSavedGame();
            StatsManager.recordGameLoss();
          }
        }
      } else {
        // Auto-clean notes for surrounding cells in same row, column, and box
        if (_autoRemoveNotes) {
          _cleanSurroundingNotes(_selectedRow, _selectedCol, number);
        }
      }

      // Check for win
      if (_checkWin()) {
        _status = GameStatus.won;
        _stopTimer();
        _clearSavedGame();
        StatsManager.recordGameWin(_difficulty, _elapsedSeconds);
      }
    }
    notifyListeners();
    _saveGameState();
  }

  /// Clears the selected cell
  void eraseCell() {
    if (_status != GameStatus.playing) return;
    if (_selectedRow == -1 || _selectedCol == -1) return;
    if (_isOriginalClue[_selectedRow][_selectedCol]) return;
    if (_currentBoard[_selectedRow][_selectedCol] == 0 &&
        _notes[_selectedRow][_selectedCol].isEmpty) {
      return;
    }

    _saveToHistory();
    _currentBoard[_selectedRow][_selectedCol] = 0;
    _notes[_selectedRow][_selectedCol].clear();
    notifyListeners();
    _saveGameState();
  }

  /// Reveals the correct value for the selected cell
  void revealHint() {
    if (_status != GameStatus.playing) return;
    if (_selectedRow == -1 || _selectedCol == -1) return;
    if (_isOriginalClue[_selectedRow][_selectedCol]) return;

    int correctVal = _solvedBoard[_selectedRow][_selectedCol];
    if (_currentBoard[_selectedRow][_selectedCol] == correctVal) return;

    _saveToHistory();
    _currentBoard[_selectedRow][_selectedCol] = correctVal;
    _notes[_selectedRow][_selectedCol].clear();

    if (_autoRemoveNotes) {
      _cleanSurroundingNotes(_selectedRow, _selectedCol, correctVal);
    }

    if (_checkWin()) {
      _status = GameStatus.won;
      _stopTimer();
      _clearSavedGame();
      StatsManager.recordGameWin(_difficulty, _elapsedSeconds);
    }
    notifyListeners();
    _saveGameState();
  }

  void pauseGame() {
    if (_status == GameStatus.playing) {
      _status = GameStatus.paused;
      _stopTimer();
      notifyListeners();
      _saveGameState();
    }
  }

  void resumeGame() {
    if (_status == GameStatus.paused) {
      _status = GameStatus.playing;
      _startTimer();
      notifyListeners();
      _saveGameState();
    }
  }

  void _cleanSurroundingNotes(int row, int col, int value) {
    // Row & Col clean
    for (int i = 0; i < 9; i++) {
      _notes[row][i].remove(value);
      _notes[i][col].remove(value);
    }
    // Box clean
    int boxRowStart = row - row % 3;
    int boxColStart = col - col % 3;
    for (int r = boxRowStart; r < boxRowStart + 3; r++) {
      for (int c = boxColStart; c < boxColStart + 3; c++) {
        _notes[r][c].remove(value);
      }
    }
  }

  bool _checkWin() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_currentBoard[r][c] != _solvedBoard[r][c]) {
          return false;
        }
      }
    }
    return true;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      timerNotifier.notifyListeners();
      _saveGameState();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    selectionNotifier.dispose();
    timerNotifier.dispose();
    super.dispose();
  }

  Future<void> _saveGameState() async {
    if (_status != GameStatus.playing && _status != GameStatus.paused) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PrefsKeys.savedDifficulty, _difficulty);
      if (_dailyChallengeDate != null) {
        await prefs.setString(PrefsKeys.savedDailyDate, _dailyChallengeDate!);
      } else {
        await prefs.remove(PrefsKeys.savedDailyDate);
      }
      await prefs.setString(PrefsKeys.savedCurrentBoard, jsonEncode(_currentBoard));
      await prefs.setString(PrefsKeys.savedSolvedBoard, jsonEncode(_solvedBoard));
      await prefs.setString(
        PrefsKeys.savedIsOriginalClue,
        jsonEncode(_isOriginalClue),
      );

      final notesList = List.generate(
        9,
        (r) => List.generate(9, (c) => _notes[r][c].toList()),
      );
      await prefs.setString(PrefsKeys.savedNotes, jsonEncode(notesList));
      await prefs.setInt(PrefsKeys.savedMistakes, _mistakes);
      await prefs.setInt(PrefsKeys.savedElapsedSeconds, _elapsedSeconds);
      await prefs.setBool(PrefsKeys.hasSavedGame, true);
    } catch (_) {}
  }

  Future<void> _clearSavedGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PrefsKeys.savedDifficulty);
      await prefs.remove(PrefsKeys.savedDailyDate);
      await prefs.remove(PrefsKeys.savedCurrentBoard);
      await prefs.remove(PrefsKeys.savedSolvedBoard);
      await prefs.remove(PrefsKeys.savedIsOriginalClue);
      await prefs.remove(PrefsKeys.savedNotes);
      await prefs.remove(PrefsKeys.savedMistakes);
      await prefs.remove(PrefsKeys.savedElapsedSeconds);
      await prefs.setBool(PrefsKeys.hasSavedGame, false);
    } catch (_) {}
  }

  Future<void> loadSavedGame() async {
    _status = GameStatus.loading;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _difficulty = prefs.getString(PrefsKeys.savedDifficulty) ?? 'easy';
      final dailyDate = prefs.getString(PrefsKeys.savedDailyDate);
      _dailyChallengeDate = (dailyDate == null || dailyDate.isEmpty)
          ? null
          : dailyDate;

      final currentBoardStr = prefs.getString(PrefsKeys.savedCurrentBoard) ?? '';
      final solvedBoardStr = prefs.getString(PrefsKeys.savedSolvedBoard) ?? '';
      final originalClueStr = prefs.getString(PrefsKeys.savedIsOriginalClue) ?? '';
      final notesStr = prefs.getString(PrefsKeys.savedNotes) ?? '';

      final dynamic currentBoardJson = jsonDecode(currentBoardStr);
      _currentBoard = List.generate(
        9,
        (r) => List<int>.from(currentBoardJson[r]),
      );

      final dynamic solvedBoardJson = jsonDecode(solvedBoardStr);
      _solvedBoard = List.generate(
        9,
        (r) => List<int>.from(solvedBoardJson[r]),
      );

      final dynamic originalClueJson = jsonDecode(originalClueStr);
      _isOriginalClue = List.generate(
        9,
        (r) => List<bool>.from(originalClueJson[r]),
      );

      final dynamic notesJson = jsonDecode(notesStr);
      _notes = List.generate(
        9,
        (r) => List.generate(9, (c) => Set<int>.from(notesJson[r][c])),
      );

      _mistakes = prefs.getInt(PrefsKeys.savedMistakes) ?? 0;
      _elapsedSeconds = prefs.getInt(PrefsKeys.savedElapsedSeconds) ?? 0;

      _selectedRow = -1;
      _selectedCol = -1;
      _notesMode = false;
      _undoHistory.clear();
      _redoHistory.clear();

      _status = GameStatus.playing;
      _startTimer();
      notifyListeners();
    } catch (_) {
      _status = GameStatus.idle;
      notifyListeners();
    }
  }
}

enum SolverStatus { idle, solving, solved, error }

/// Manages the state of the custom puzzle solver interface.
class SudokuSolverProvider extends ChangeNotifier {
  final ChangeNotifier selectionNotifier = ChangeNotifier();

  List<List<int>> _solverBoard = List.generate(9, (_) => List.filled(9, 0));
  int _selectedRow = -1;
  int _selectedCol = -1;
  SolverStatus _status = SolverStatus.idle;
  String? _errorMessage;

  List<List<int>> get solverBoard => _solverBoard;
  int get selectedRow => _selectedRow;
  int get selectedCol => _selectedCol;
  SolverStatus get status => _status;
  String? get errorMessage => _errorMessage;

  void selectCell(int r, int c) {
    _selectedRow = r;
    _selectedCol = c;
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    } else {
      selectionNotifier.notifyListeners();
    }
  }

  void enterNumber(int number) {
    if (_selectedRow == -1 || _selectedCol == -1) return;
    _solverBoard[_selectedRow][_selectedCol] = number;
    _status = SolverStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void clearCell() {
    if (_selectedRow == -1 || _selectedCol == -1) return;
    _solverBoard[_selectedRow][_selectedCol] = 0;
    _status = SolverStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void clearBoard() {
    _solverBoard = List.generate(9, (_) => List.filled(9, 0));
    _selectedRow = -1;
    _selectedCol = -1;
    _status = SolverStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// 1st way: Complete solve of the board.
  void solveComplete() {
    _errorMessage = null;

    // Check general rules validity of the current user inputs
    if (!SudokuLogic.isBoardValid(_solverBoard)) {
      _status = SolverStatus.error;
      _errorMessage =
          "The grid contains rule violations (duplicate numbers in rows, columns, or 3x3 grids)!";
      notifyListeners();
      return;
    }

    _status = SolverStatus.solving;
    notifyListeners();

    // Create a copy to solve
    List<List<int>> solvedCopy = SudokuLogic.copyBoard(_solverBoard);
    bool success = SudokuLogic.solve(solvedCopy);

    if (success) {
      _solverBoard = solvedCopy;
      _status = SolverStatus.solved;
    } else {
      _status = SolverStatus.error;
      _errorMessage =
          "This Sudoku layout is unsolvable. Please check your entered values.";
    }
    notifyListeners();
  }

  /// 2nd way: Solve only the selected cell.
  void solveSelectedCell() {
    _errorMessage = null;

    if (_selectedRow == -1 || _selectedCol == -1) {
      _status = SolverStatus.error;
      _errorMessage = "Please select a cell on the grid first!";
      notifyListeners();
      return;
    }

    if (_solverBoard[_selectedRow][_selectedCol] != 0) {
      // Cell is already filled, nothing to solve
      return;
    }

    // Check general rules validity of the current user inputs
    if (!SudokuLogic.isBoardValid(_solverBoard)) {
      _status = SolverStatus.error;
      _errorMessage = "The grid contains rule violations!";
      notifyListeners();
      return;
    }

    _status = SolverStatus.solving;
    notifyListeners();

    // Find the value for the selected cell by solving a copy of the board
    List<List<int>> solvedCopy = SudokuLogic.copyBoard(_solverBoard);
    bool success = SudokuLogic.solve(solvedCopy);

    if (success) {
      int solvedVal = solvedCopy[_selectedRow][_selectedCol];
      _solverBoard[_selectedRow][_selectedCol] = solvedVal;
      _status =
          SolverStatus.idle; // return to idle so they can solve more cells
    } else {
      _status = SolverStatus.error;
      _errorMessage =
          "This Sudoku layout is unsolvable. Cannot solve the selected cell.";
    }
    notifyListeners();
  }

  @override
  void dispose() {
    selectionNotifier.dispose();
    super.dispose();
  }
}
