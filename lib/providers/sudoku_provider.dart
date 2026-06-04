import 'dart:async';
import 'package:flutter/material.dart';
import '../core/sudoku_logic.dart';

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
  List<List<int>> _currentBoard = List.generate(9, (_) => List.filled(9, 0));
  List<List<int>> _solvedBoard = List.generate(9, (_) => List.filled(9, 0));
  List<List<bool>> _isOriginalClue = List.generate(9, (_) => List.filled(9, false));
  List<List<Set<int>>> _notes = List.generate(9, (_) => List.generate(9, (_) => {}));

  int _selectedRow = -1;
  int _selectedCol = -1;

  int _mistakes = 0;
  final int maxMistakes = 3;
  String _difficulty = 'easy';
  GameStatus _status = GameStatus.idle;

  bool _notesMode = false;
  int _elapsedSeconds = 0;
  Timer? _timer;

  final List<BoardState> _undoHistory = [];

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

  String get formattedTime {
    int minutes = _elapsedSeconds ~/ 60;
    int seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void selectCell(int r, int c) {
    if (_status != GameStatus.playing) return;
    _selectedRow = r;
    _selectedCol = c;
    notifyListeners();
  }

  /// Start a new game with [difficulty]
  Future<void> newGame(String difficulty) async {
    _status = GameStatus.loading;
    notifyListeners();

    // Generate puzzle
    final puzzle = await Future.value(SudokuLogic.generatePuzzle(difficulty));

    _difficulty = difficulty;
    _currentBoard = SudokuLogic.copyBoard(puzzle.puzzleBoard);
    _solvedBoard = SudokuLogic.copyBoard(puzzle.solvedBoard);
    _isOriginalClue = List.generate(9, (r) => List.generate(9, (c) => puzzle.puzzleBoard[r][c] != 0));
    _notes = List.generate(9, (_) => List.generate(9, (_) => {}));

    _selectedRow = -1;
    _selectedCol = -1;
    _mistakes = 0;
    _elapsedSeconds = 0;
    _notesMode = false;
    _undoHistory.clear();

    _status = GameStatus.playing;
    _startTimer();
    notifyListeners();
  }

  void toggleNotesMode() {
    _notesMode = !_notesMode;
    notifyListeners();
  }

  /// Saves the current board state to undo history
  void _saveToHistory() {
    _undoHistory.add(BoardState(
      board: SudokuLogic.copyBoard(_currentBoard),
      notes: List.generate(9, (r) => List.generate(9, (c) => Set.from(_notes[r][c]))),
    ));
    // Limit history size to 20 to prevent excessive memory usage
    if (_undoHistory.length > 20) {
      _undoHistory.removeAt(0);
    }
  }

  /// Performs an undo action
  void undo() {
    if (_status != GameStatus.playing || _undoHistory.isEmpty) return;
    final prevState = _undoHistory.removeLast();
    _currentBoard = prevState.board;
    _notes = prevState.notes;
    notifyListeners();
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
        _currentBoard[_selectedRow][_selectedCol] = 0; // Clear cell if placing a note
      }
    } else {
      // Direct number input
      if (_currentBoard[_selectedRow][_selectedCol] == number) return;

      _saveToHistory();
      _currentBoard[_selectedRow][_selectedCol] = number;
      _notes[_selectedRow][_selectedCol].clear(); // Clear notes for this cell

      // Check if the number is correct compared to solution
      if (number != _solvedBoard[_selectedRow][_selectedCol]) {
        _mistakes++;
        if (_mistakes >= maxMistakes) {
          _status = GameStatus.gameOver;
          _stopTimer();
        }
      } else {
        // Auto-clean notes for surrounding cells in same row, column, and box
        _cleanSurroundingNotes(_selectedRow, _selectedCol, number);
        // Check for win
        if (_checkWin()) {
          _status = GameStatus.won;
          _stopTimer();
        }
      }
    }
    notifyListeners();
  }

  /// Clears the selected cell
  void eraseCell() {
    if (_status != GameStatus.playing) return;
    if (_selectedRow == -1 || _selectedCol == -1) return;
    if (_isOriginalClue[_selectedRow][_selectedCol]) return;
    if (_currentBoard[_selectedRow][_selectedCol] == 0 && _notes[_selectedRow][_selectedCol].isEmpty) return;

    _saveToHistory();
    _currentBoard[_selectedRow][_selectedCol] = 0;
    _notes[_selectedRow][_selectedCol].clear();
    notifyListeners();
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
    _cleanSurroundingNotes(_selectedRow, _selectedCol, correctVal);

    if (_checkWin()) {
      _status = GameStatus.won;
      _stopTimer();
    }
    notifyListeners();
  }

  void pauseGame() {
    if (_status == GameStatus.playing) {
      _status = GameStatus.paused;
      _stopTimer();
      notifyListeners();
    }
  }

  void resumeGame() {
    if (_status == GameStatus.paused) {
      _status = GameStatus.playing;
      _startTimer();
      notifyListeners();
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
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

enum SolverStatus { idle, solving, solved, error }

/// Manages the state of the custom puzzle solver interface.
class SudokuSolverProvider extends ChangeNotifier {
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
    _errorMessage = null;
    notifyListeners();
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
      _errorMessage = "The grid contains rule violations (duplicate numbers in rows, columns, or 3x3 grids)!";
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
      _errorMessage = "This Sudoku layout is unsolvable. Please check your entered values.";
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
      _status = SolverStatus.idle; // return to idle so they can solve more cells
    } else {
      _status = SolverStatus.error;
      _errorMessage = "This Sudoku layout is unsolvable. Cannot solve the selected cell.";
    }
    notifyListeners();
  }
}
