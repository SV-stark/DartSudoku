import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/sudoku_logic.dart';
import '../core/stats_manager.dart';
import '../core/difficulty.dart';
import '../core/constants.dart';
import '../core/sudoku_analyzer.dart';
import '../data/prefs_keys.dart';
import 'settings_provider.dart';

/// Represents a snapshot of the board state for undo functionality.
class BoardState {
  final List<List<int>> board;
  final List<List<Set<int>>> notes;
  final int mistakes;

  BoardState({
    required this.board,
    required this.notes,
    required this.mistakes,
  });
}

enum MoveActionType { enterNumber, toggleNote, erase, undo, redo, hint }

/// Record of an individual move for replay and hesitation heatmap calculation.
class MoveRecord {
  final int timestampMs;
  final int row;
  final int col;
  final int value;
  final bool isNote;
  final int durationMs;
  final BoardState? snapshot;
  final MoveActionType actionType;

  MoveRecord({
    required this.timestampMs,
    required this.row,
    required this.col,
    required this.value,
    required this.isNote,
    required this.durationMs,
    this.snapshot,
    this.actionType = MoveActionType.enterNumber,
  });
}

enum GameStatus { idle, loading, playing, paused, won, gameOver, error }

/// Manages the state of the active play game.
class SudokuGameProvider extends ChangeNotifier {
  final ChangeNotifier selectionNotifier = ChangeNotifier();
  final ChangeNotifier timerNotifier = ChangeNotifier();

  List<List<int>> _initialBoard = List.generate(
    GameConstants.boardSize,
    (_) => List.filled(GameConstants.boardSize, 0),
  );
  List<List<int>> _currentBoard = List.generate(
    GameConstants.boardSize,
    (_) => List.filled(GameConstants.boardSize, 0),
  );
  List<List<int>> _solvedBoard = List.generate(
    GameConstants.boardSize,
    (_) => List.filled(GameConstants.boardSize, 0),
  );
  List<List<bool>> _isOriginalClue = List.generate(
    GameConstants.boardSize,
    (_) => List.filled(GameConstants.boardSize, false),
  );
  List<List<Set<int>>> _notes = List.generate(
    GameConstants.boardSize,
    (_) => List.generate(GameConstants.boardSize, (_) => {}),
  );

  // Unmodifiable cached representations to expose to UI safely
  List<List<int>> _unmodifiableInitialBoard = [];
  List<List<int>> _unmodifiableCurrentBoard = [];
  List<List<int>> _unmodifiableSolvedBoard = [];
  List<List<bool>> _unmodifiableIsOriginalClue = [];
  List<List<Set<int>>> _unmodifiableNotes = [];

  int _selectedRow = -1;
  int _selectedCol = -1;

  int _mistakes = 0;
  int _hintsUsed = 0;
  Difficulty _difficulty = Difficulty.easy;
  String? _dailyChallengeDate;
  GameStatus _status = GameStatus.idle;
  String? _errorMessage;

  bool _notesMode = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  Timer? _flashTimer;

  final List<BoardState> _undoHistory = [];
  final List<BoardState> _redoHistory = [];

  int _flashRow = -1;
  int _flashCol = -1;

  // Cached dynamic counts to avoid O(81) loops during widget rebuilds
  Map<int, int> _numberCounts = {};
  int _totalClues = 0;

  // Multi-color Palette State (0: Default, 1: Blue, 2: Green, 3: Orange, 4: Purple)
  int _selectedColorIndex = 0;
  final Map<String, int> _cellColors = {};
  final Map<String, int> _candidateColors = {};

  // Session Replay & Hesitation Heatmap Tracking
  final List<MoveRecord> _moveHistory = [];
  bool _showHesitationHeatmap = false;
  int _lastMoveTimeMs = DateTime.now().millisecondsSinceEpoch;

  // Sudoku Variant & Rules Engine State
  SudokuVariant _activeVariant = SudokuVariant.standard;
  List<KillerCage>? _killerCages;

  // Diagnostic Mistake Analysis Result
  MistakeDiagnosticResult? _lastMistakeDiagnostic;

  SudokuGameProvider() {
    SettingsProvider.instance.addListener(_onSettingsChanged);
    _onBoardStateChanged();
  }

  void _onSettingsChanged() {
    notifyListeners();
  }

  // Getters for internal boards (Unmodifiable views)
  List<List<int>> get initialBoard => _unmodifiableInitialBoard;
  List<List<int>> get currentBoard => _unmodifiableCurrentBoard;
  List<List<int>> get solvedBoard => _unmodifiableSolvedBoard;
  List<List<bool>> get isOriginalClue => _unmodifiableIsOriginalClue;
  List<List<Set<int>>> get notes => _unmodifiableNotes;

  int get selectedRow => _selectedRow;
  int get selectedCol => _selectedCol;
  int get mistakes => _mistakes;
  int get hintsUsed => _hintsUsed;
  int get maxMistakes => GameConstants.maxMistakes;
  Difficulty get difficulty => _difficulty;
  GameStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get notesMode => _notesMode;
  int get elapsedSeconds => _elapsedSeconds;
  bool get canUndo => _undoHistory.isNotEmpty;
  bool get canRedo => _redoHistory.isNotEmpty;

  int get flashRow => _flashRow;
  int get flashCol => _flashCol;

  // Multi-color Palette Getters & Setters
  int get selectedColorIndex => _selectedColorIndex;
  Map<String, int> get cellColors => Map.unmodifiable(_cellColors);
  Map<String, int> get candidateColors => Map.unmodifiable(_candidateColors);

  void setSelectedColorIndex(int index) {
    _selectedColorIndex = index;
    notifyListeners();
  }

  void toggleCellColor(int r, int c) {
    final key = '$r,$c';
    if (_selectedColorIndex == 0) {
      _cellColors.remove(key);
    } else {
      if (_cellColors[key] == _selectedColorIndex) {
        _cellColors.remove(key);
      } else {
        _cellColors[key] = _selectedColorIndex;
      }
    }
    notifyListeners();
  }

  void toggleCandidateColor(int r, int c, int digit) {
    final key = '$r,$c,$digit';
    if (_selectedColorIndex == 0) {
      _candidateColors.remove(key);
    } else {
      if (_candidateColors[key] == _selectedColorIndex) {
        _candidateColors.remove(key);
      } else {
        _candidateColors[key] = _selectedColorIndex;
      }
    }
    notifyListeners();
  }

  void clearColors() {
    _cellColors.clear();
    _candidateColors.clear();
    notifyListeners();
  }

  // Session Replay & Hesitation Heatmap Getters & Setters
  List<MoveRecord> get moveHistory => List.unmodifiable(_moveHistory);
  bool get showHesitationHeatmap => _showHesitationHeatmap;

  void toggleHesitationHeatmap() {
    _showHesitationHeatmap = !_showHesitationHeatmap;
    notifyListeners();
  }

  // Variant & Diagnostic Getters
  SudokuVariant get activeVariant => _activeVariant;
  List<KillerCage>? get killerCages => _killerCages;
  MistakeDiagnosticResult? get lastMistakeDiagnostic => _lastMistakeDiagnostic;

  void clearMistakeDiagnostic() {
    _lastMistakeDiagnostic = null;
    notifyListeners();
  }


  // Settings properties delegated to SettingsProvider
  bool get showMistakes => SettingsProvider.instance.showMistakes;
  bool get highlightConflicts => SettingsProvider.instance.highlightConflicts;
  bool get highlightIdentical => SettingsProvider.instance.highlightIdentical;
  bool get endlessMode => SettingsProvider.instance.endlessMode;
  bool get autoRemoveNotes => SettingsProvider.instance.autoRemoveNotes;

  Map<String, Color> _activeHintHighlights = {};
  List<List<String>> _activeHintLinks = [];

  Map<String, Color> get activeHintHighlights => _activeHintHighlights;
  List<List<String>> get activeHintLinks => _activeHintLinks;

  void setHintVisuals(
    Map<String, Color> highlights,
    List<List<String>> links,
  ) {
    _activeHintHighlights = highlights;
    _activeHintLinks = links;
    notifyListeners();
  }

  void clearHintVisuals() {
    _activeHintHighlights = {};
    _activeHintLinks = [];
    notifyListeners();
  }

  Map<int, int> get numberCounts => _numberCounts;
  int get totalClues => _totalClues;

  /// Delegated settings updates
  Future<void> updateSettings({
    bool? showMistakes,
    bool? highlightConflicts,
    bool? highlightIdentical,
    bool? endlessMode,
    bool? autoRemoveNotes,
  }) async {
    await SettingsProvider.instance.updateSettings(
      showMistakes: showMistakes,
      highlightConflicts: highlightConflicts,
      highlightIdentical: highlightIdentical,
      endlessMode: endlessMode,
      autoRemoveNotes: autoRemoveNotes,
    );
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

  BoardState _createCurrentBoardSnapshot() {
    return BoardState(
      board: SudokuLogic.copyBoard(_currentBoard),
      notes: List.generate(
        GameConstants.boardSize,
        (r) => List.generate(
          GameConstants.boardSize,
          (c) => Set<int>.from(_notes[r][c]),
        ),
      ),
      mistakes: _mistakes,
    );
  }

  /// Start a new game with [difficulty], optionally seeded for a [dailyDate] challenge and [variant]
  Future<void> newGame(
    Difficulty difficulty, {
    String? dailyDate,
    SudokuVariant variant = SudokuVariant.standard,
    int? seed,
  }) async {
    _errorMessage = null;
    _status = GameStatus.loading;
    notifyListeners();

    int? effectiveSeed = seed;
    if (dailyDate != null && effectiveSeed == null) {
      // Create a deterministic seed from the date string, e.g. "2026-06-05" -> 20260605
      final cleanDate = dailyDate.replaceAll('-', '');
      effectiveSeed = int.tryParse(cleanDate) ?? dailyDate.hashCode;
    }

    const int maxGenerationRetries = 3;
    SudokuPuzzle? puzzle;
    for (int attempt = 0; attempt < maxGenerationRetries; attempt++) {
      try {
        final currentSeed = effectiveSeed != null ? effectiveSeed + attempt : null;
        puzzle = await Isolate.run(
          () => SudokuLogic.generatePuzzle(difficulty, seed: currentSeed, variant: variant),
        ).timeout(const Duration(seconds: 15));
        break;
      } catch (e) {
        if (attempt == maxGenerationRetries - 1) {
          _status = GameStatus.error;
          _errorMessage = 'Failed to generate puzzle. Please try again.';
          notifyListeners();
          return;
        }
      }
    }

    if (puzzle == null) {
      _status = GameStatus.error;
      _errorMessage = 'Failed to generate puzzle. Please try again.';
      notifyListeners();
      return;
    }

    _applyPuzzle(puzzle, difficulty, dailyDate: dailyDate, variant: variant);
    await _clearSavedGame();

    // Only record standard starts if not in daily challenge mode
    if (dailyDate == null) {
      await StatsManager.recordGameStart(difficulty);
    }
    notifyListeners();
  }

  /// Load a pre-generated or targeted puzzle directly into the provider
  Future<void> loadPuzzle(
    SudokuPuzzle puzzle,
    Difficulty difficulty, {
    SudokuVariant variant = SudokuVariant.standard,
  }) async {
    _errorMessage = null;
    _status = GameStatus.loading;
    notifyListeners();

    _applyPuzzle(puzzle, difficulty, variant: variant);
    await _clearSavedGame();
    await StatsManager.recordGameStart(difficulty);
    notifyListeners();
  }

  void _applyPuzzle(
    SudokuPuzzle puzzle,
    Difficulty difficulty, {
    String? dailyDate,
    SudokuVariant variant = SudokuVariant.standard,
  }) {
    _difficulty = difficulty;
    _dailyChallengeDate = dailyDate;
    _activeVariant = variant;
    _killerCages = puzzle.cages;
    _initialBoard = SudokuLogic.copyBoard(puzzle.puzzleBoard);
    _currentBoard = SudokuLogic.copyBoard(puzzle.puzzleBoard);
    _solvedBoard = SudokuLogic.copyBoard(puzzle.solvedBoard);
    _isOriginalClue = List.generate(
      GameConstants.boardSize,
      (r) => List.generate(
        GameConstants.boardSize,
        (c) => puzzle.puzzleBoard[r][c] != 0,
      ),
    );
    _notes = List.generate(
      GameConstants.boardSize,
      (_) => List.generate(GameConstants.boardSize, (_) => {}),
    );

    _selectedRow = -1;
    _selectedCol = -1;
    _mistakes = 0;
    _hintsUsed = 0;
    _elapsedSeconds = 0;
    _notesMode = false;
    _undoHistory.clear();
    _redoHistory.clear();
    _cellColors.clear();
    _candidateColors.clear();
    _moveHistory.clear();
    _lastMistakeDiagnostic = null;
    _lastMoveTimeMs = DateTime.now().millisecondsSinceEpoch;

    _onBoardStateChanged();

    _status = GameStatus.playing;
    _startTimer();
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
          GameConstants.boardSize,
          (r) => List.generate(
            GameConstants.boardSize,
            (c) => Set.from(_notes[r][c]),
          ),
        ),
        mistakes: _mistakes,
      ),
    );
    // Limit history size to prevent excessive memory usage
    if (_undoHistory.length > GameConstants.maxUndoHistory) {
      _undoHistory.removeAt(0);
    }
  }

  void triggerFlash(int r, int c) {
    _flashTimer?.cancel();
    _flashRow = r;
    _flashCol = c;
    notifyListeners();
    _flashTimer = Timer(const Duration(milliseconds: 400), () {
      _flashRow = -1;
      _flashCol = -1;
      notifyListeners();
    });
  }

  void _findAndFlashDifference(
    List<List<int>> oldBoard,
    List<List<int>> newBoard,
  ) {
    for (int r = 0; r < GameConstants.boardSize; r++) {
      for (int c = 0; c < GameConstants.boardSize; c++) {
        if (oldBoard[r][c] != newBoard[r][c]) {
          triggerFlash(r, c);
          return;
        }
      }
    }
  }

  /// Performs an undo action
  Future<void> undo() async {
    if (_status != GameStatus.playing || _undoHistory.isEmpty) return;

    _redoHistory.add(
      BoardState(
        board: SudokuLogic.copyBoard(_currentBoard),
        notes: List.generate(
          GameConstants.boardSize,
          (r) => List.generate(
            GameConstants.boardSize,
            (c) => Set.from(_notes[r][c]),
          ),
        ),
        mistakes: _mistakes,
      ),
    );

    final prevState = _undoHistory.removeLast();
    final oldBoard = SudokuLogic.copyBoard(_currentBoard);
    _currentBoard = prevState.board;
    _notes = prevState.notes;
    _mistakes = prevState.mistakes;

    final now = DateTime.now().millisecondsSinceEpoch;
    final durationMs = now - _lastMoveTimeMs;
    _lastMoveTimeMs = now;
    _moveHistory.add(
      MoveRecord(
        timestampMs: now,
        row: _selectedRow,
        col: _selectedCol,
        value: 0,
        isNote: false,
        durationMs: durationMs,
        snapshot: _createCurrentBoardSnapshot(),
        actionType: MoveActionType.undo,
      ),
    );

    _onBoardStateChanged();
    _findAndFlashDifference(oldBoard, _currentBoard);
    notifyListeners();
    await _saveGameState();
  }

  /// Performs a redo action
  Future<void> redo() async {
    if (_status != GameStatus.playing || _redoHistory.isEmpty) return;

    _undoHistory.add(
      BoardState(
        board: SudokuLogic.copyBoard(_currentBoard),
        notes: List.generate(
          GameConstants.boardSize,
          (r) => List.generate(
            GameConstants.boardSize,
            (c) => Set.from(_notes[r][c]),
          ),
        ),
        mistakes: _mistakes,
      ),
    );

    final nextState = _redoHistory.removeLast();
    final oldBoard = SudokuLogic.copyBoard(_currentBoard);
    _currentBoard = nextState.board;
    _notes = nextState.notes;
    _mistakes = nextState.mistakes;

    final now = DateTime.now().millisecondsSinceEpoch;
    final durationMs = now - _lastMoveTimeMs;
    _lastMoveTimeMs = now;
    _moveHistory.add(
      MoveRecord(
        timestampMs: now,
        row: _selectedRow,
        col: _selectedCol,
        value: 0,
        isNote: false,
        durationMs: durationMs,
        snapshot: _createCurrentBoardSnapshot(),
        actionType: MoveActionType.redo,
      ),
    );

    _onBoardStateChanged();
    _findAndFlashDifference(oldBoard, _currentBoard);
    notifyListeners();
    await _saveGameState();
  }

  /// Input a number from the numpad
  Future<void> enterNumber(int number, {bool? asNote}) async {
    if (_status != GameStatus.playing) return;
    if (_selectedRow == -1 || _selectedCol == -1) return;
    if (_isOriginalClue[_selectedRow][_selectedCol]) return;

    final effectiveNotesMode = asNote ?? _notesMode;

    if (effectiveNotesMode) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final durationMs = now - _lastMoveTimeMs;
      _lastMoveTimeMs = now;

      // Toggle note
      _saveToHistory();
      if (_notes[_selectedRow][_selectedCol].contains(number)) {
        _notes[_selectedRow][_selectedCol].remove(number);
      } else {
        _notes[_selectedRow][_selectedCol].add(number);
        _currentBoard[_selectedRow][_selectedCol] =
            0; // Clear cell if placing a note
      }

      _moveHistory.add(
        MoveRecord(
          timestampMs: now,
          row: _selectedRow,
          col: _selectedCol,
          value: number,
          isNote: true,
          durationMs: durationMs,
          snapshot: _createCurrentBoardSnapshot(),
          actionType: MoveActionType.toggleNote,
        ),
      );
      _onBoardStateChanged();
    } else {
      // Direct number input - check early before recording move
      if (_currentBoard[_selectedRow][_selectedCol] == number) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final durationMs = now - _lastMoveTimeMs;
      _lastMoveTimeMs = now;

      _saveToHistory();
      _currentBoard[_selectedRow][_selectedCol] = number;
      _notes[_selectedRow][_selectedCol].clear(); // Clear notes for this cell

      _moveHistory.add(
        MoveRecord(
          timestampMs: now,
          row: _selectedRow,
          col: _selectedCol,
          value: number,
          isNote: false,
          durationMs: durationMs,
          snapshot: _createCurrentBoardSnapshot(),
          actionType: MoveActionType.enterNumber,
        ),
      );

      _onBoardStateChanged();

      // Check if the number is correct compared to solution
      if (number != _solvedBoard[_selectedRow][_selectedCol]) {
        if (showMistakes) {
          _lastMistakeDiagnostic = SudokuAnalyzer.analyzeMistake(
            _currentBoard,
            _selectedRow,
            _selectedCol,
            number,
            _solvedBoard,
            variant: _activeVariant,
          );
          _mistakes++;
          if (!endlessMode && _mistakes >= GameConstants.maxMistakes) {
            _status = GameStatus.gameOver;
            _stopTimer();
            await _clearSavedGame();
            await StatsManager.recordGameLoss();
          }
        } else {
          _lastMistakeDiagnostic = null;
        }
      } else {
        _lastMistakeDiagnostic = null;
        // Auto-clean notes for surrounding cells in same row, column, and box
        if (autoRemoveNotes) {
          _cleanSurroundingNotes(_selectedRow, _selectedCol, number);
          _onBoardStateChanged();
        }
      }

      // Check for win
      if (_checkWin()) {
        _status = GameStatus.won;
        _stopTimer();
        await _clearSavedGame();
        await StatsManager.recordGameWin(_difficulty, _elapsedSeconds);
      }
    }
    notifyListeners();
    await _saveGameState();
  }


  /// Clears the selected cell
  Future<void> eraseCell() async {
    if (_status != GameStatus.playing) return;
    if (_selectedRow == -1 || _selectedCol == -1) return;
    if (_isOriginalClue[_selectedRow][_selectedCol]) return;
    if (_currentBoard[_selectedRow][_selectedCol] == 0 &&
        _notes[_selectedRow][_selectedCol].isEmpty) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final durationMs = now - _lastMoveTimeMs;
    _lastMoveTimeMs = now;

    _saveToHistory();
    _currentBoard[_selectedRow][_selectedCol] = 0;
    _notes[_selectedRow][_selectedCol].clear();

    _moveHistory.add(
      MoveRecord(
        timestampMs: now,
        row: _selectedRow,
        col: _selectedCol,
        value: 0,
        isNote: false,
        durationMs: durationMs,
        snapshot: _createCurrentBoardSnapshot(),
        actionType: MoveActionType.erase,
      ),
    );

    _onBoardStateChanged();
    notifyListeners();
    await _saveGameState();
  }

  /// Reveals the correct value for the selected cell
  Future<void> revealHint() async {
    if (_status != GameStatus.playing) return;
    if (_selectedRow == -1 || _selectedCol == -1) return;
    if (_isOriginalClue[_selectedRow][_selectedCol]) return;

    int correctVal = _solvedBoard[_selectedRow][_selectedCol];
    if (_currentBoard[_selectedRow][_selectedCol] == correctVal) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final durationMs = now - _lastMoveTimeMs;
    _lastMoveTimeMs = now;

    _hintsUsed++;
    _saveToHistory();
    _currentBoard[_selectedRow][_selectedCol] = correctVal;
    _notes[_selectedRow][_selectedCol].clear();

    _moveHistory.add(
      MoveRecord(
        timestampMs: now,
        row: _selectedRow,
        col: _selectedCol,
        value: correctVal,
        isNote: false,
        durationMs: durationMs,
        snapshot: _createCurrentBoardSnapshot(),
        actionType: MoveActionType.hint,
      ),
    );

    _onBoardStateChanged();

    if (autoRemoveNotes) {
      _cleanSurroundingNotes(_selectedRow, _selectedCol, correctVal);
      _onBoardStateChanged();
    }

    if (_checkWin()) {
      _status = GameStatus.won;
      _stopTimer();
      await _clearSavedGame();
      await StatsManager.recordGameWin(_difficulty, _elapsedSeconds);
    }
    notifyListeners();
    await _saveGameState();
  }

  Future<void> pauseGame() async {
    if (_status == GameStatus.playing) {
      _status = GameStatus.paused;
      _stopTimer();
      notifyListeners();
      await _saveGameState();
    }
  }

  Future<void> resumeGame() async {
    if (_status == GameStatus.paused) {
      _status = GameStatus.playing;
      _startTimer();
      notifyListeners();
      await _saveGameState();
    }
  }

  void _cleanSurroundingNotes(int row, int col, int value) {
    // Row & Col clean
    for (int i = 0; i < GameConstants.boardSize; i++) {
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
    for (int r = 0; r < GameConstants.boardSize; r++) {
      for (int c = 0; c < GameConstants.boardSize; c++) {
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
      // Save game state at most once every 10 seconds to limit disk writes
      if (_elapsedSeconds % 10 == 0) {
        _saveGameState();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    SettingsProvider.instance.removeListener(_onSettingsChanged);
    _stopTimer();
    _saveGameState();
    selectionNotifier.dispose();
    timerNotifier.dispose();
    super.dispose();
  }

  // Update incremental cached state values
  void _onBoardStateChanged() {
    _updateUnmodifiableViews();
    _updateNumberCounts();
    _updateTotalClues();
  }

  void _updateUnmodifiableViews() {
    _unmodifiableInitialBoard = List<List<int>>.unmodifiable(
      _initialBoard.map((row) => List<int>.unmodifiable(row)),
    );
    _unmodifiableCurrentBoard = List<List<int>>.unmodifiable(
      _currentBoard.map((row) => List<int>.unmodifiable(row)),
    );
    _unmodifiableSolvedBoard = List<List<int>>.unmodifiable(
      _solvedBoard.map((row) => List<int>.unmodifiable(row)),
    );
    _unmodifiableIsOriginalClue = List<List<bool>>.unmodifiable(
      _isOriginalClue.map((row) => List<bool>.unmodifiable(row)),
    );
    _unmodifiableNotes = List<List<Set<int>>>.unmodifiable(
      _notes.map(
        (row) => List<Set<int>>.unmodifiable(
          row.map((s) => Set<int>.unmodifiable(s)),
        ),
      ),
    );
  }

  void _updateNumberCounts() {
    final counts = <int, int>{};
    for (int i = 1; i <= 9; i++) {
      counts[i] = 9;
    }
    for (int r = 0; r < GameConstants.boardSize; r++) {
      for (int c = 0; c < GameConstants.boardSize; c++) {
        final val = _currentBoard[r][c];
        if (val != 0) {
          counts[val] = (counts[val] ?? 9) - 1;
        }
      }
    }
    counts.forEach((key, value) {
      if (value < 0) counts[key] = 0;
    });
    _numberCounts = Map.unmodifiable(counts);
  }

  void _updateTotalClues() {
    int count = 0;
    for (int r = 0; r < GameConstants.boardSize; r++) {
      for (int c = 0; c < GameConstants.boardSize; c++) {
        if (_isOriginalClue[r][c]) count++;
      }
    }
    _totalClues = count;
  }

  Future<void> _saveGameState() async {
    if (_status != GameStatus.playing && _status != GameStatus.paused) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PrefsKeys.savedDifficulty, _difficulty.name);
      if (_dailyChallengeDate != null) {
        await prefs.setString(PrefsKeys.savedDailyDate, _dailyChallengeDate!);
      } else {
        await prefs.remove(PrefsKeys.savedDailyDate);
      }
      await prefs.setString(
        PrefsKeys.savedVariant,
        _activeVariant.name,
      );
      if (_killerCages != null) {
        final cagesJson = _killerCages!.map((c) => {
          'id': c.id,
          'targetSum': c.targetSum,
          'cells': c.cells.map((p) => [p.x, p.y]).toList(),
        }).toList();
        await prefs.setString(PrefsKeys.savedCages, jsonEncode(cagesJson));
      } else {
        await prefs.remove(PrefsKeys.savedCages);
      }

      await prefs.setString(
        PrefsKeys.savedInitialBoard,
        jsonEncode(_initialBoard),
      );
      await prefs.setString(
        PrefsKeys.savedCurrentBoard,
        jsonEncode(_currentBoard),
      );
      await prefs.setString(
        PrefsKeys.savedSolvedBoard,
        jsonEncode(_solvedBoard),
      );
      await prefs.setString(
        PrefsKeys.savedIsOriginalClue,
        jsonEncode(_isOriginalClue),
      );

      final notesList = List.generate(
        GameConstants.boardSize,
        (r) => List.generate(
          GameConstants.boardSize,
          (c) => _notes[r][c].toList(),
        ),
      );
      await prefs.setString(PrefsKeys.savedNotes, jsonEncode(notesList));
      await prefs.setInt(PrefsKeys.savedMistakes, _mistakes);
      await prefs.setInt(PrefsKeys.savedElapsedSeconds, _elapsedSeconds);
      await prefs.setBool(PrefsKeys.hasSavedGame, true);
    } catch (e, stack) {
      debugPrint('Error saving game state in SudokuGameProvider: $e\n$stack');
    }
  }

  Future<void> _clearSavedGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PrefsKeys.savedDifficulty);
      await prefs.remove(PrefsKeys.savedDailyDate);
      await prefs.remove(PrefsKeys.savedVariant);
      await prefs.remove(PrefsKeys.savedCages);
      await prefs.remove(PrefsKeys.savedInitialBoard);
      await prefs.remove(PrefsKeys.savedCurrentBoard);
      await prefs.remove(PrefsKeys.savedSolvedBoard);
      await prefs.remove(PrefsKeys.savedIsOriginalClue);
      await prefs.remove(PrefsKeys.savedNotes);
      await prefs.remove(PrefsKeys.savedMistakes);
      await prefs.remove(PrefsKeys.savedElapsedSeconds);
      await prefs.setBool(PrefsKeys.hasSavedGame, false);
    } catch (e, stack) {
      debugPrint('Error clearing saved game in SudokuGameProvider: $e\n$stack');
    }
  }

  Difficulty _parseDifficulty(String? name) {
    if (name == null) return Difficulty.easy;
    try {
      return Difficulty.values.byName(name.toLowerCase());
    } catch (_) {
      return Difficulty.easy;
    }
  }

  Future<void> loadSavedGame() async {
    _status = GameStatus.loading;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final diffStr = prefs.getString(PrefsKeys.savedDifficulty);
      _difficulty = _parseDifficulty(diffStr);
      final dailyDate = prefs.getString(PrefsKeys.savedDailyDate);
      _dailyChallengeDate = (dailyDate == null || dailyDate.isEmpty)
          ? null
          : dailyDate;

      final variantStr = prefs.getString(PrefsKeys.savedVariant);
      _activeVariant = (variantStr != null)
          ? SudokuVariant.values.firstWhere(
              (v) => v.name == variantStr,
              orElse: () => SudokuVariant.standard,
            )
          : SudokuVariant.standard;

      final cagesStr = prefs.getString(PrefsKeys.savedCages);
      if (cagesStr != null && cagesStr.isNotEmpty) {
        final dynamic cagesJson = jsonDecode(cagesStr);
        if (cagesJson is List) {
          _killerCages = cagesJson.map<KillerCage>((c) {
            final cellsList = (c['cells'] as List)
                .map<Point<int>>((p) => Point<int>(p[0] as int, p[1] as int))
                .toList();
            return KillerCage(
              id: c['id'] as int,
              targetSum: c['targetSum'] as int,
              cells: cellsList,
            );
          }).toList();
        } else {
          _killerCages = null;
        }
      } else {
        _killerCages = null;
      }

      final currentBoardStr =
          prefs.getString(PrefsKeys.savedCurrentBoard) ?? '';
      final solvedBoardStr = prefs.getString(PrefsKeys.savedSolvedBoard) ?? '';
      final originalClueStr =
          prefs.getString(PrefsKeys.savedIsOriginalClue) ?? '';
      final notesStr = prefs.getString(PrefsKeys.savedNotes) ?? '';

      final dynamic currentBoardJson = jsonDecode(currentBoardStr);
      final dynamic solvedBoardJson = jsonDecode(solvedBoardStr);
      final dynamic originalClueJson = jsonDecode(originalClueStr);
      final dynamic notesJson = jsonDecode(notesStr);

      if (currentBoardJson is! List ||
          currentBoardJson.length != GameConstants.boardSize ||
          solvedBoardJson is! List ||
          solvedBoardJson.length != GameConstants.boardSize ||
          originalClueJson is! List ||
          originalClueJson.length != GameConstants.boardSize ||
          notesJson is! List ||
          notesJson.length != GameConstants.boardSize) {
        throw const FormatException('Corrupt board matrix in saved game state');
      }

      _currentBoard = List.generate(
        GameConstants.boardSize,
        (r) => List<int>.from(currentBoardJson[r]),
      );

      _solvedBoard = List.generate(
        GameConstants.boardSize,
        (r) => List<int>.from(solvedBoardJson[r]),
      );

      _isOriginalClue = List.generate(
        GameConstants.boardSize,
        (r) => List<bool>.from(originalClueJson[r]),
      );

      _notes = List.generate(
        GameConstants.boardSize,
        (r) => List.generate(
          GameConstants.boardSize,
          (c) => Set<int>.from(notesJson[r][c]),
        ),
      );

      final initialBoardStr = prefs.getString(PrefsKeys.savedInitialBoard);
      if (initialBoardStr != null && initialBoardStr.isNotEmpty) {
        final dynamic initialBoardJson = jsonDecode(initialBoardStr);
        if (initialBoardJson is List &&
            initialBoardJson.length == GameConstants.boardSize) {
          _initialBoard = List.generate(
            GameConstants.boardSize,
            (r) => List<int>.from(initialBoardJson[r]),
          );
        } else {
          _initialBoard = List.generate(
            GameConstants.boardSize,
            (r) => List.generate(
              GameConstants.boardSize,
              (c) => _isOriginalClue[r][c] ? _solvedBoard[r][c] : 0,
            ),
          );
        }
      } else {
        _initialBoard = List.generate(
          GameConstants.boardSize,
          (r) => List.generate(
            GameConstants.boardSize,
            (c) => _isOriginalClue[r][c] ? _solvedBoard[r][c] : 0,
          ),
        );
      }

      _mistakes = prefs.getInt(PrefsKeys.savedMistakes) ?? 0;
      _hintsUsed = 0;
      _elapsedSeconds = prefs.getInt(PrefsKeys.savedElapsedSeconds) ?? 0;

      _selectedRow = -1;
      _selectedCol = -1;
      _notesMode = false;
      _undoHistory.clear();
      _redoHistory.clear();

      _onBoardStateChanged();

      _status = GameStatus.playing;
      _startTimer();
      notifyListeners();
    } catch (e, stack) {
      debugPrint('Error loading saved game in SudokuGameProvider: $e\n$stack');
      _status = GameStatus.idle;
      await _clearSavedGame();
      notifyListeners();
    }
  }
}

enum SolverStatus { idle, solving, solved, error }

/// Manages the state of the custom puzzle solver interface.
class SudokuSolverProvider extends ChangeNotifier {
  final ChangeNotifier selectionNotifier = ChangeNotifier();

  List<List<int>> _solverBoard = List.generate(
    GameConstants.boardSize,
    (_) => List.filled(GameConstants.boardSize, 0),
  );
  int _selectedRow = -1;
  int _selectedCol = -1;
  SolverStatus _status = SolverStatus.idle;
  String? _errorMessage;
  int _flashRow = -1;
  int _flashCol = -1;
  String? _stepExplanation;
  Timer? _flashTimer;

  List<List<int>> get solverBoard => _solverBoard;
  int get selectedRow => _selectedRow;
  int get selectedCol => _selectedCol;
  SolverStatus get status => _status;
  String? get errorMessage => _errorMessage;
  int get flashRow => _flashRow;
  int get flashCol => _flashCol;
  String? get stepExplanation => _stepExplanation;

  void selectCell(int r, int c) {
    _selectedRow = r;
    _selectedCol = c;
    _stepExplanation = null;
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    } else {
      selectionNotifier.notifyListeners();
      notifyListeners();
    }
  }

  void enterNumber(int number) {
    if (_selectedRow == -1 || _selectedCol == -1) return;
    _solverBoard[_selectedRow][_selectedCol] = number;
    _status = SolverStatus.idle;
    _errorMessage = null;
    _stepExplanation = null;
    notifyListeners();
  }

  void clearCell() {
    if (_selectedRow == -1 || _selectedCol == -1) return;
    _solverBoard[_selectedRow][_selectedCol] = 0;
    _status = SolverStatus.idle;
    _errorMessage = null;
    _stepExplanation = null;
    notifyListeners();
  }

  void clearBoard() {
    _solverBoard = List.generate(
      GameConstants.boardSize,
      (_) => List.filled(GameConstants.boardSize, 0),
    );
    _selectedRow = -1;
    _selectedCol = -1;
    _status = SolverStatus.idle;
    _errorMessage = null;
    _stepExplanation = null;
    notifyListeners();
  }

  void triggerFlash(int r, int c) {
    _flashTimer?.cancel();
    _flashRow = r;
    _flashCol = c;
    notifyListeners();
    _flashTimer = Timer(const Duration(milliseconds: 600), () {
      _flashRow = -1;
      _flashCol = -1;
      notifyListeners();
    });
  }

  /// 1st way: Complete solve of the board asynchronously.
  Future<void> solveComplete() async {
    _errorMessage = null;
    _stepExplanation = null;

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

    // Create a copy to solve in background isolate
    final boardCopy = SudokuLogic.copyBoard(_solverBoard);
    try {
      final result = await Isolate.run(() {
        final solvedCopy = SudokuLogic.copyBoard(boardCopy);
        final success = SudokuLogic.solve(solvedCopy);
        return {'success': success, 'solved': solvedCopy};
      }).timeout(const Duration(seconds: 15));

      if (result['success'] == true) {
        _solverBoard = result['solved'] as List<List<int>>;
        _status = SolverStatus.solved;
      } else {
        _status = SolverStatus.error;
        _errorMessage =
            "This Sudoku layout is unsolvable. Please check your entered values.";
      }
    } catch (e) {
      _status = SolverStatus.error;
      _errorMessage = "Solving failed: $e";
    }
    notifyListeners();
  }

  /// 2nd way: Solve only the selected cell asynchronously.
  Future<void> solveSelectedCell() async {
    _errorMessage = null;
    _stepExplanation = null;

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

    final targetRow = _selectedRow;
    final targetCol = _selectedCol;
    final boardCopy = SudokuLogic.copyBoard(_solverBoard);

    try {
      final result = await Isolate.run(() {
        final solvedCopy = SudokuLogic.copyBoard(boardCopy);
        final success = SudokuLogic.solve(solvedCopy);
        return {'success': success, 'solved': solvedCopy};
      }).timeout(const Duration(seconds: 15));

      if (result['success'] == true) {
        final solvedCopy = result['solved'] as List<List<int>>;
        final solvedVal = solvedCopy[targetRow][targetCol];
        _solverBoard[targetRow][targetCol] = solvedVal;
        _status = SolverStatus.idle;
        triggerFlash(targetRow, targetCol);
      } else {
        _status = SolverStatus.error;
        _errorMessage =
            "This Sudoku layout is unsolvable. Cannot solve the selected cell.";
      }
    } catch (e) {
      _status = SolverStatus.error;
      _errorMessage = "Solving failed: $e";
    }
    notifyListeners();
  }

  /// 3rd way: Solve stepwise, solving one cell at a time and explaining the technique asynchronously.
  Future<void> solveStepWise() async {
    _errorMessage = null;
    _stepExplanation = null;

    // Check general rules validity of the current user inputs
    if (!SudokuLogic.isBoardValid(_solverBoard)) {
      _status = SolverStatus.error;
      _errorMessage =
          "The grid contains rule violations (duplicate numbers in rows, columns, or 3x3 grids)!";
      notifyListeners();
      return;
    }

    // Check if the board is already completely solved
    bool isComplete = true;
    for (int r = 0; r < GameConstants.boardSize; r++) {
      for (int c = 0; c < GameConstants.boardSize; c++) {
        if (_solverBoard[r][c] == 0) {
          isComplete = false;
          break;
        }
      }
      if (!isComplete) break;
    }

    if (isComplete) {
      _status = SolverStatus.error;
      _errorMessage = "The board is already fully solved!";
      notifyListeners();
      return;
    }

    _status = SolverStatus.solving;
    notifyListeners();

    final boardCopy = SudokuLogic.copyBoard(_solverBoard);
    try {
      final result = await Isolate.run(() {
        final solvedCopy = SudokuLogic.copyBoard(boardCopy);
        final success = SudokuLogic.solve(solvedCopy);
        if (!success) {
          return {'success': false};
        }

        int targetRow = -1;
        int targetCol = -1;
        int minOptions = 10;

        for (int r = 0; r < GameConstants.boardSize; r++) {
          for (int c = 0; c < GameConstants.boardSize; c++) {
            if (boardCopy[r][c] == 0) {
              int options = 0;
              for (int val = 1; val <= 9; val++) {
                if (SudokuLogic.isValid(boardCopy, r, c, val)) {
                  options++;
                }
              }
              if (options < minOptions) {
                minOptions = options;
                targetRow = r;
                targetCol = c;
              }
            }
          }
        }

        String? explanation;
        int solvedVal = 0;
        if (targetRow != -1 && targetCol != -1) {
          solvedVal = solvedCopy[targetRow][targetCol];
          explanation = SudokuAnalyzer.analyzeCell(
            boardCopy,
            targetRow,
            targetCol,
            solvedVal,
          );
        }

        return {
          'success': true,
          'targetRow': targetRow,
          'targetCol': targetCol,
          'solvedVal': solvedVal,
          'explanation': explanation,
        };
      }).timeout(const Duration(seconds: 15));

      if (result['success'] == true) {
        final targetRow = result['targetRow'] as int;
        final targetCol = result['targetCol'] as int;
        final solvedVal = result['solvedVal'] as int;
        final explanation = result['explanation'] as String?;

        if (targetRow != -1 && targetCol != -1) {
          _stepExplanation = explanation;
          _solverBoard[targetRow][targetCol] = solvedVal;
          _selectedRow = targetRow;
          _selectedCol = targetCol;
          _status = SolverStatus.idle;
          triggerFlash(targetRow, targetCol);
        } else {
          _status = SolverStatus.error;
          _errorMessage = "Could not find a cell to solve.";
        }
      } else {
        _status = SolverStatus.error;
        _errorMessage =
            "This Sudoku layout is unsolvable. Please check your entered values.";
      }
    } catch (e) {
      _status = SolverStatus.error;
      _errorMessage = "Step-wise solve failed: $e";
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    selectionNotifier.dispose();
    super.dispose();
  }
}
