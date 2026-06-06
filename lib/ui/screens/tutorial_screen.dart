import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/sudoku_grid.dart';
import '../../core/sudoku_lessons_data.dart';
import '../../core/sudoku_logic.dart';

/// Interactive tutorial screen providing slides, explainers, and highlighted grids for strategies.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with TickerProviderStateMixin {
  int _currentLessonIndex = 0;
  int _currentSlideIndex = 0;

  List<List<int>>? _currentBoard;
  int _selectedRow = -1;
  int _selectedCol = -1;
  bool _isSolved = false;
  bool _showErrorHint = false;

  // Progress tracking & Gamification
  Set<int> _completedLessons = {};
  Map<int, int> _practiceCounts = {};

  // Practice Mode State
  int _practiceLessonIndex = 0;
  List<List<int>>? _practiceBoard;
  int? _practiceExpectedValue;
  Map<String, Set<int>>? _practiceNotes;
  String _practiceText = '';
  String _practiceHelp = '';
  int _practiceHighlightedRow = -1;
  int _practiceHighlightedCol = -1;
  Map<String, Color> Function(BuildContext)? _practiceCustomHighlights;
  List<List<String>>? _practiceLinks;

  int _practiceSelectedRow = -1;
  int _practiceSelectedCol = -1;
  bool _practiceIsSolved = false;
  bool _practiceShowError = false;
  int _practiceStreak = 0;
  bool _practiceShowHint = false;

  // Active Learning Practice Stages
  int _practiceStage = 2; // 0: Pattern, 1: Eliminate, 2: Solve
  Set<String> _practicePatternCells = {};
  Set<String> _practiceSelectedPatternCells = {};
  Set<int> _practiceEliminatedCandidates = {};
  Set<int> _practiceIncorrectCandidates = {};
  List<String> _practiceTrace = [];

  // Time-Attack Mode State
  bool _timeAttackActive = false;
  int _timeAttackTimeLeft = 180;
  int _timeAttackScore = 0;
  int _timeAttackHighScore = 0;
  Timer? _timeAttackTimer;
  int _timeAttackCorrectCount = 0;
  int _timeAttackMistakeCount = 0;

  // Candidate Filter & Lesson Autoplay & Analytics
  int _selectedCandidateFilter = -1;
  bool _isPlayingLessons = false;
  Timer? _lessonPlayTimer;
  DateTime? _practiceStage0StartTime;
  int _totalMistakesMade = 0;
  List<double> _stage0SolveTimes = [];

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -8.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 8.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -8.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
    _loadProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentBoard == null) {
      _initSlide();
    }
    if (_practiceBoard == null) {
      _generatePracticeChallenge(_practiceLessonIndex);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _timeAttackTimer?.cancel();
    _lessonPlayTimer?.cancel();
    super.dispose();
  }

  void _initSlide() {
    final lessons = SudokuLessonsData.getLessons(context);
    final lesson = lessons[_currentLessonIndex];
    final slide = lesson.slides[_currentSlideIndex];

    _currentBoard = List.generate(9, (r) => List.from(slide.board[r]));

    if (slide.expectedValue != null) {
      _selectedRow = slide.highlightedRow;
      _selectedCol = slide.highlightedCol;
      _isSolved = false;
    } else {
      _selectedRow = -1;
      _selectedCol = -1;
      _isSolved = true;
    }

    _showErrorHint = false;
  }

  void _updatePracticeText() {
    final rowText = _practiceHighlightedRow + 1;
    final colText = _practiceHighlightedCol + 1;
    final lessons = SudokuLessonsData.getLessons(context);
    final lessonTitle = lessons[_practiceLessonIndex].title;
    final permutedExpected = _practiceExpectedValue ?? 0;

    if (_practiceStage == 0) {
      if (_practiceLinks != null && _practiceLinks!.isNotEmpty) {
        final path = _extractCellPath(_practiceLinks!);
        final remaining = path.length - _practiceTrace.length;
        _practiceText =
            'Trace the **$lessonTitle** conjugate chain in sequence. Tap the cells starting at either endpoint. (Remaining: $remaining cells to trace)';
      } else {
        final remaining =
            _practicePatternCells.length - _practiceSelectedPatternCells.length;
        _practiceText =
            'Locate the cells that form the **$lessonTitle** pattern. Tap each cell to select it. (Remaining: $remaining cells)';
      }
      _practiceHelp = _getPracticeHint(_practiceLessonIndex, permutedExpected);
    } else if (_practiceStage == 1) {
      _practiceText =
          'Correct pattern identified! Now tap on the target cell at Row $rowText, Col $colText to open the Candidate Elimination Panel below, and eliminate the invalid candidates.';
      _practiceHelp =
          'Look at the target cell. Based on the $lessonTitle pattern, which candidates are eliminated? Tap them in the panel below to cross them out.';
    } else {
      _practiceText =
          'Only the correct candidate remains for the target cell. Enter the digit using the numpad below to solve!';
      _practiceHelp =
          'Only the expected value $permutedExpected remains. Enter it using the numpad below.';
    }
  }

  void _generatePracticeChallenge(int lessonIndex) {
    final lessons = SudokuLessonsData.getLessons(context);
    final lesson = lessons[lessonIndex];

    SlideData? practiceSlide;
    for (var s in lesson.slides) {
      if (s.expectedValue != null) {
        practiceSlide = s;
        break;
      }
    }
    practiceSlide ??= lesson.slides.last;

    // Generate a random 1-to-1 digit permutation map for 1-9
    final digits = List.generate(9, (i) => i + 1);
    digits.shuffle();
    final Map<int, int> perm = {};
    for (int i = 0; i < 9; i++) {
      perm[i + 1] = digits[i];
    }

    final int? origExpected = practiceSlide.expectedValue;
    final int? permutedExpected = origExpected == null
        ? null
        : perm[origExpected];

    final String targetKey =
        '${practiceSlide.highlightedRow},${practiceSlide.highlightedCol}';

    // 1. Solve the original slide board to get a complete solved grid reference
    final List<List<int>> solvedRef = SudokuLogic.copyBoard(
      practiceSlide.board,
    );
    SudokuLogic.solve(solvedRef);

    // 2. Generate the permuted solved reference grid
    final permutedSolvedRef = List.generate(9, (r) {
      return List.generate(9, (c) {
        final val = solvedRef[r][c];
        return val == 0 ? 0 : perm[val]!;
      });
    });

    // 3. Define pattern cells to know what cells are untouchable
    final Map<String, Color> customHighlights =
        practiceSlide.customHighlights != null
        ? practiceSlide.customHighlights!(context)
        : {};
    final Set<String> patternCells = {};
    customHighlights.forEach((key, color) {
      if (key != targetKey) {
        patternCells.add(key);
      }
    });
    final Set<String> untouchable = {targetKey, ...patternCells};

    // 4. Build the permuted board with clues and background solved cells
    final Random random = Random();
    final permutedBoard = List.generate(9, (r) {
      return List.generate(9, (c) {
        final key = '$r,$c';
        if (untouchable.contains(key)) {
          return 0; // Must be empty for technique to work
        }
        final val = practiceSlide!.board[r][c];
        if (val != 0) {
          return perm[val]!;
        }
        // For advanced lessons, fill 35% of other empty cells as clues to make it realistic
        if (lessonIndex >= 3) {
          if (random.nextDouble() < 0.35) {
            return permutedSolvedRef[r][c];
          }
        }
        return 0;
      });
    });

    // Copy missing target cell notes from Slide 1 if applicable
    final Map<String, Set<int>> baseNotes = Map.from(practiceSlide.notes);
    if (!baseNotes.containsKey(targetKey)) {
      final firstSlide = lesson.slides.first;
      if (firstSlide.notes.containsKey(targetKey)) {
        baseNotes[targetKey] = firstSlide.notes[targetKey]!;
      }
    }

    // Permute notes
    final Map<String, Set<int>> permutedNotes = {};
    baseNotes.forEach((key, valSet) {
      permutedNotes[key] = valSet.map((v) => perm[v]!).toSet();
    });

    // 5. Populate realistic candidates for empty cells
    if (lessonIndex >= 3) {
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          final key = '$r,$c';
          if (permutedBoard[r][c] == 0) {
            if (permutedNotes.containsKey(key)) {
              // Keep the technique's notes
            } else {
              // Compute realistic candidates based on current clues
              final Set<int> candidates = {};
              for (int val = 1; val <= 9; val++) {
                if (SudokuLogic.isValid(permutedBoard, r, c, val)) {
                  candidates.add(val);
                }
              }
              if (candidates.isNotEmpty) {
                permutedNotes[key] = candidates;
              }
            }
          }
        }
      }
    }

    final targetNotes = permutedNotes[targetKey] ?? {};
    final incorrectCandidates = Set<int>.from(targetNotes)
      ..remove(permutedExpected);

    int initialStage = 2; // Direct solve
    if (lessonIndex >= 3) {
      initialStage = 0; // Identify pattern cells
    }

    if (initialStage == 0 && patternCells.isEmpty) {
      initialStage = 1;
    }
    if (initialStage == 1 && incorrectCandidates.isEmpty) {
      initialStage = 2;
    }

    setState(() {
      _practiceLessonIndex = lessonIndex;
      _practiceBoard = permutedBoard;
      _practiceExpectedValue = permutedExpected;
      _practiceNotes = permutedNotes;
      _practiceHighlightedRow = practiceSlide!.highlightedRow;
      _practiceHighlightedCol = practiceSlide.highlightedCol;
      _practiceCustomHighlights = practiceSlide.customHighlights;
      _practiceLinks = practiceSlide.links;

      _practiceSelectedRow = _practiceHighlightedRow;
      _practiceSelectedCol = _practiceHighlightedCol;
      _practiceIsSolved = false;
      _practiceShowError = false;
      _practiceShowHint = false;

      // Active learning setup
      _practiceStage = initialStage;
      _practicePatternCells = patternCells;
      _practiceSelectedPatternCells = {};
      _practiceTrace = [];
      _practiceStage0StartTime = DateTime.now();
      _practiceEliminatedCandidates = {};
      _practiceIncorrectCandidates = incorrectCandidates;

      _updatePracticeText();
    });
  }

  String _getPracticeHint(int lessonIndex, int expectedVal) {
    final lessons = SudokuLessonsData.getLessons(context);
    final title = lessons[lessonIndex].title;
    if (title.contains('Naked Single')) {
      return 'Examine the row, column, and box of the highlighted cell. Only one candidate is possible here because all other numbers are already present in its intersection.';
    } else if (title.contains('Hidden Single')) {
      return 'Focus on the number $expectedVal. In the highlighted row, column, or box, this number has only one cell where it can possibly be placed.';
    } else if (title.contains('Naked Pair')) {
      return 'Two cells in the highlighted group contain the exact same two candidates. This eliminates those two candidates from all other cells in that group.';
    } else if (title.contains('Naked Triple')) {
      return 'Three cells in the highlighted group contain subsets of the same three candidates. This eliminates those three candidates from all other cells in that group.';
    } else if (title.contains('Naked Quadruple') ||
        title.contains('Naked Quad')) {
      return 'Four cells in the highlighted group contain subsets of the same four candidates. This eliminates those four candidates from all other cells in that group.';
    } else if (title.contains('Hidden Pair')) {
      return 'Two candidates appear only in the same two cells of the highlighted group. Therefore, all other candidates can be eliminated from those two cells, leaving only the correct values.';
    } else if (title.contains('Hidden Triple')) {
      return 'Three candidates appear only in the same three cells of the highlighted group. Therefore, all other candidates can be eliminated from those cells.';
    } else if (title.contains('Hidden Quadruple') ||
        title.contains('Hidden Quad')) {
      return 'Four candidates appear only in the same four cells of the highlighted group. Therefore, all other candidates can be eliminated from those cells.';
    } else if (title.contains('Locked Candidate') ||
        title.contains('Pointing') ||
        title.contains('Claiming')) {
      return 'Focus on candidate $expectedVal. In the highlighted cells, see how it is locked in a row/column within a box, eliminating it elsewhere.';
    } else if (title.contains('X-Wing') ||
        title.contains('Swordfish') ||
        title.contains('Jellyfish') ||
        title.contains('Skyscraper') ||
        title.contains('Two-String-Kite') ||
        title.contains('Empty Rectangle') ||
        title.contains('Crane') ||
        title.contains('Simple Coloring') ||
        title.contains('X-Chain')) {
      return 'Focus on candidate $expectedVal. Look at the highlighted cells to find the pattern (like X-Wing or Skyscraper) for this candidate and see what is eliminated.';
    } else if (title.contains('Wing') ||
        title.contains('Medusa') ||
        title.contains('Chain')) {
      return 'Look at the candidate links starting from the highlighted cells. Trace the alternating strong and weak links to find the elimination or forcing value.';
    } else if (title.contains('Unique Rectangle')) {
      return 'Look at the highlighted cells. To avoid a non-unique solution (two ways to solve the same rectangle), the highlighted cell must contain the extra candidate.';
    } else if (title.contains('BUG') ||
        title.contains('Binary Universal Grave')) {
      return 'Look at the cell with three candidates in a grid where almost all other unsolved cells have exactly two candidates. The correct value is the one that appears three times in its row, column, and box.';
    }
    return 'Look at the highlighted cells and apply the rules of the $title technique to find the correct value.';
  }

  void _handleNumpadTap(int number) {
    if (_isSolved) return;
    final lessons = SudokuLessonsData.getLessons(context);
    final lesson = lessons[_currentLessonIndex];
    final slide = lesson.slides[_currentSlideIndex];

    if (number == slide.expectedValue) {
      setState(() {
        _currentBoard![slide.highlightedRow][slide.highlightedCol] = number;
        _isSolved = true;
        _showErrorHint = false;
      });
      if (_currentSlideIndex == lesson.slides.length - 1) {
        _completeLesson(_currentLessonIndex);
      }
    } else {
      setState(() {
        _currentBoard![slide.highlightedRow][slide.highlightedCol] = number;
        _showErrorHint = true;
      });
      _shakeController.forward(from: 0.0);
    }
  }

  void _handlePracticeNumpadTap(int number) {
    if (_practiceIsSolved) return;
    if (_practiceStage < 2) {
      _shakeController.forward(from: 0.0);
      return;
    }
    final lessons = SudokuLessonsData.getLessons(context);
    final lessonTitle = lessons[_practiceLessonIndex].title;

    if (number == _practiceExpectedValue) {
      setState(() {
        _practiceBoard![_practiceHighlightedRow][_practiceHighlightedCol] =
            number;
        _practiceIsSolved = true;
        _practiceShowError = false;
        if (!_timeAttackActive) {
          _practiceStreak++;
        } else {
          _timeAttackScore++;
          _timeAttackTimeLeft = min(180, _timeAttackTimeLeft + 10);
          _timeAttackCorrectCount++;
          Future.delayed(const Duration(milliseconds: 600), () {
            if (_timeAttackActive) {
              _generateTimeAttackChallenge();
            }
          });
        }
      });
      if (!_timeAttackActive) {
        _solvePractice(_practiceLessonIndex);
      }
    } else {
      setState(() {
        _practiceBoard![_practiceHighlightedRow][_practiceHighlightedCol] =
            number;
        _practiceShowError = true;
        _practiceHelp =
            "Oops! You entered $number. But according to the rules of $lessonTitle, the correct solution is $_practiceExpectedValue. Check the strategy guide to review the elimination steps.";
        if (_timeAttackActive) {
          _timeAttackTimeLeft = max(0, _timeAttackTimeLeft - 15);
          _timeAttackMistakeCount++;
          if (_timeAttackTimeLeft <= 0) {
            _endTimeAttack();
          }
        } else {
          _practiceStreak = 0; // Reset streak on mistake
        }
      });
      _shakeController.forward(from: 0.0);
    }
  }

  void _showLessonList({bool forPractice = false}) {
    final theme = Theme.of(context);
    final lessons = SudokuLessonsData.getLessons(context);

    final Map<String, List<int>> categories = {
      'Basics & Scanning': [0],
      'Hidden Techniques': [1, 2, 3, 4, 5],
      'Naked Techniques': [6, 7, 8, 9],
      'Locked Candidates': [10, 11],
      'Fish Techniques': [12, 13, 14],
      'Advanced Fish': [15, 16, 17],
      'Single-Digit Patterns': [18, 19, 20, 21],
      'Wings (Y-Wing / W-Wing)': [22, 23, 24, 25, 26, 27, 28, 29],
      'Chaining Techniques': [30, 31, 32, 33, 34, 35, 36, 37, 38],
      'Uniqueness Techniques': [39, 40, 41, 42, 43, 44],
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  forPractice
                      ? 'Select Practice Technique'
                      : 'Sudoku School Syllabus',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: categories.entries.map((entry) {
                      final categoryName = entry.key;
                      final indices = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              top: 16,
                              bottom: 8,
                            ),
                            child: Text(
                              categoryName.toUpperCase(),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          Card(
                            elevation: 0,
                            color: theme.colorScheme.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: indices.map((idx) {
                                final lesson = lessons[idx];
                                final isCurrent = forPractice
                                    ? idx == _practiceLessonIndex
                                    : idx == _currentLessonIndex;
                                final isLocked = _isLessonLocked(idx);
                                final isCompleted = _completedLessons.contains(
                                  idx,
                                );

                                return ListTile(
                                  onTap: () {
                                    if (isLocked) {
                                      final tier = _getLessonTier(idx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Tier $tier is locked! Complete all lessons and 3 practice challenges in Tier ${tier - 1} to unlock.',
                                          ),
                                          backgroundColor:
                                              theme.colorScheme.error,
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.pop(context);
                                    if (forPractice) {
                                      _generatePracticeChallenge(idx);
                                    } else {
                                      setState(() {
                                        _currentLessonIndex = idx;
                                        _currentSlideIndex = 0;
                                        _initSlide();
                                      });
                                    }
                                  },
                                  leading: CircleAvatar(
                                    backgroundColor: isLocked
                                        ? theme
                                              .colorScheme
                                              .surfaceContainerHighest
                                        : (isCurrent
                                              ? theme.colorScheme.primary
                                              : theme
                                                    .colorScheme
                                                    .primaryContainer
                                                    .withValues(alpha: 0.2)),
                                    foregroundColor: isLocked
                                        ? theme.colorScheme.outline
                                        : (isCurrent
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.primary),
                                    radius: 16,
                                    child: isLocked
                                        ? const Icon(
                                            Icons.lock_rounded,
                                            size: 14,
                                          )
                                        : Text(
                                            '${idx + 1}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                  title: Text(
                                    lesson.title,
                                    style: TextStyle(
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isLocked
                                          ? theme.colorScheme.onSurface
                                                .withValues(alpha: 0.38)
                                          : (isCurrent
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurface),
                                    ),
                                  ),
                                  trailing: isLocked
                                      ? Icon(
                                          Icons.lock_outline_rounded,
                                          color: theme.colorScheme.outline
                                              .withValues(alpha: 0.5),
                                          size: 18,
                                        )
                                      : (isCompleted
                                            ? Icon(
                                                Icons.check_circle_rounded,
                                                color: Colors.green.shade600,
                                                size: 18,
                                              )
                                            : (isCurrent
                                                  ? Icon(
                                                      Icons
                                                          .arrow_right_alt_rounded,
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                    )
                                                  : const Icon(
                                                      Icons
                                                          .chevron_right_rounded,
                                                      size: 16,
                                                    ))),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessons = SudokuLessonsData.getLessons(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              const SizedBox(height: 8),
              TabBar(
                tabs: const [
                  Tab(text: 'LESSONS', icon: Icon(Icons.menu_book_rounded)),
                  Tab(
                    text: 'MASTERY PRACTICE',
                    icon: Icon(Icons.psychology_rounded),
                  ),
                  Tab(text: 'TIME ATTACK', icon: Icon(Icons.timer_rounded)),
                ],
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildLessonsTab(lessons),
                    _buildPracticeTab(lessons),
                    _buildTimeAttackTab(lessons),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.filledTonal(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Text(
            'Sudoku School',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton.filledTonal(
            onPressed: _showAnalyticsDashboard,
            icon: const Icon(Icons.analytics_rounded),
            tooltip: 'Syllabus & Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsTab(List<LessonData> lessons) {
    final lesson = lessons[_currentLessonIndex];
    final slide = lesson.slides[_currentSlideIndex];

    final String targetKey = '${slide.highlightedRow},${slide.highlightedCol}';
    final Map<String, Set<int>> combinedNotes = Map.from(slide.notes);
    if (slide.expectedValue != null && !combinedNotes.containsKey(targetKey)) {
      final firstSlide = lesson.slides.first;
      if (firstSlide.notes.containsKey(targetKey)) {
        combinedNotes[targetKey] = firstSlide.notes[targetKey]!;
      }
    }

    List<List<Set<int>>> gridNotes = List.generate(
      9,
      (_) => List.generate(9, (_) => {}),
    );
    combinedNotes.forEach((key, value) {
      final parts = key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      gridNotes[r][c] = value;
    });

    final Map<String, Color> customBgs = slide.customHighlights != null
        ? slide.customHighlights!(context)
        : {};

    List<List<int>> solvedBoard = List.generate(
      9,
      (r) => List.generate(9, (c) {
        if (r == slide.highlightedRow &&
            c == slide.highlightedCol &&
            slide.expectedValue != null) {
          return slide.expectedValue!;
        }
        return slide.board[r][c];
      }),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLessonSelector(lessons),
          const SizedBox(height: 8),
          _buildStepProgress(lesson),
          const SizedBox(height: 16),
          _buildCandidateFilterBar(),
          const SizedBox(height: 12),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0.0),
                    child: child,
                  );
                },
                child: Stack(
                  children: [
                    SudokuGrid(
                      board: _currentBoard ?? slide.board,
                      selectedRow: _selectedRow,
                      selectedCol: _selectedCol,
                      notes: gridNotes,
                      solvedBoard: solvedBoard,
                      customCellBgs: customBgs,
                      candidateFilter: _selectedCandidateFilter,
                      onCellTap: (r, c) {
                        if (slide.expectedValue != null) {
                          if (r == slide.highlightedRow &&
                              c == slide.highlightedCol) {
                            setState(() {
                              _selectedRow = r;
                              _selectedCol = c;
                            });
                          }
                        }
                      },
                    ),
                    if (slide.links != null && slide.links!.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: SudokuLinkPainter(
                              links: slide.links!,
                              strongColor: Colors.teal.shade500,
                              weakColor: Colors.deepOrange.shade400,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (slide.expectedValue != null && !_isSolved)
            _buildTutorialNumpad(onTap: _handleNumpadTap),
          const SizedBox(height: 16),
          _buildFeedbackBanner(
            isSolved: _isSolved,
            showErrorHint: _showErrorHint,
            interactiveHelp: slide.interactiveHelp,
            expectedValue: slide.expectedValue,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${_currentSlideIndex + 1} of ${lesson.slides.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    slide.text,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildPaginationControls(lessons),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPracticeTab(List<LessonData> lessons) {
    final theme = Theme.of(context);
    final lessonTitle = lessons[_practiceLessonIndex].title;

    List<List<Set<int>>> gridNotes = List.generate(
      9,
      (_) => List.generate(9, (_) => {}),
    );
    if (_practiceNotes != null) {
      _practiceNotes!.forEach((key, value) {
        final parts = key.split(',');
        final r = int.parse(parts[0]);
        final c = int.parse(parts[1]);
        gridNotes[r][c] = value;
      });
    }

    Map<String, Color> customBgs = {};
    if (_practiceStage == 0) {
      final targetColor = theme.colorScheme.primaryContainer.withValues(
        alpha: 0.65,
      );
      customBgs['$_practiceHighlightedRow,$_practiceHighlightedCol'] =
          targetColor;
      for (var cellKey in _practiceSelectedPatternCells) {
        customBgs[cellKey] = Colors.orange.withValues(alpha: 0.5);
      }
    } else {
      if (_practiceCustomHighlights != null) {
        customBgs = _practiceCustomHighlights!(context);
      }
    }

    List<List<int>> solvedBoard = List.generate(
      9,
      (r) => List.generate(9, (c) {
        if (r == _practiceHighlightedRow &&
            c == _practiceHighlightedCol &&
            _practiceExpectedValue != null) {
          return _practiceExpectedValue!;
        }
        return _practiceBoard != null ? _practiceBoard![r][c] : 0;
      }),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            color: theme.colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRACTICING TECHNIQUE',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lessonTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_practiceStreak',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCandidateFilterBar(),
          const SizedBox(height: 12),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0.0),
                    child: child,
                  );
                },
                child: _practiceBoard != null
                    ? Stack(
                        children: [
                          SudokuGrid(
                            board: _practiceBoard!,
                            selectedRow: _practiceSelectedRow,
                            selectedCol: _practiceSelectedCol,
                            notes: gridNotes,
                            solvedBoard: solvedBoard,
                            customCellBgs: customBgs,
                            candidateFilter: _selectedCandidateFilter,
                            onCellTap: (r, c) {
                              final key = '$r,$c';
                              if (_practiceStage == 0) {
                                if (_practiceLinks != null &&
                                    _practiceLinks!.isNotEmpty) {
                                  final path = _extractCellPath(
                                    _practiceLinks!,
                                  );
                                  if (_practiceTrace.contains(key)) {
                                    if (_practiceTrace.last == key) {
                                      setState(() {
                                        _practiceTrace.removeLast();
                                        _practiceSelectedPatternCells.remove(
                                          key,
                                        );
                                        _updatePracticeText();
                                      });
                                    }
                                  } else {
                                    bool isCorrect = false;
                                    if (_practiceTrace.isEmpty) {
                                      isCorrect =
                                          (key == path.first ||
                                          key == path.last);
                                    } else {
                                      if (_practiceTrace.first == path.first) {
                                        isCorrect =
                                            (key ==
                                            path[_practiceTrace.length]);
                                      } else {
                                        isCorrect =
                                            (key ==
                                            path[path.length -
                                                1 -
                                                _practiceTrace.length]);
                                      }
                                    }

                                    if (isCorrect) {
                                      setState(() {
                                        _practiceTrace.add(key);
                                        _practiceSelectedPatternCells.add(key);
                                        _practiceShowError = false;
                                        if (_practiceTrace.length ==
                                            path.length) {
                                          _practiceStage = 1;
                                          if (_practiceIncorrectCandidates
                                              .isEmpty) {
                                            _practiceStage = 2;
                                          }
                                          if (_practiceStage0StartTime !=
                                              null) {
                                            final seconds =
                                                DateTime.now()
                                                    .difference(
                                                      _practiceStage0StartTime!,
                                                    )
                                                    .inMilliseconds /
                                                1000.0;
                                            _recordStage0Duration(seconds);
                                          }
                                        }
                                        _updatePracticeText();
                                      });
                                    } else {
                                      _recordMistake();
                                      setState(() {
                                        _practiceShowError = true;
                                        _practiceHelp =
                                            "Oops! Cell at Row ${r + 1}, Col ${c + 1} does not continue the chain sequence. Alternating links must follow the path in order. Start at an endpoint cell.";
                                        if (_timeAttackActive) {
                                          _timeAttackTimeLeft = max(
                                            0,
                                            _timeAttackTimeLeft - 15,
                                          );
                                          _timeAttackMistakeCount++;
                                          if (_timeAttackTimeLeft <= 0) {
                                            _endTimeAttack();
                                          }
                                        } else {
                                          _practiceStreak = 0;
                                        }
                                      });
                                      _shakeController.forward(from: 0.0);
                                    }
                                  }
                                } else {
                                  if (_practicePatternCells.contains(key)) {
                                    setState(() {
                                      if (_practiceSelectedPatternCells
                                          .contains(key)) {
                                        _practiceSelectedPatternCells.remove(
                                          key,
                                        );
                                      } else {
                                        _practiceSelectedPatternCells.add(key);
                                      }
                                      if (_practiceSelectedPatternCells
                                                  .length ==
                                              _practicePatternCells.length &&
                                          _practiceSelectedPatternCells
                                              .containsAll(
                                                _practicePatternCells,
                                              )) {
                                        _practiceStage = 1;
                                        if (_practiceIncorrectCandidates
                                            .isEmpty) {
                                          _practiceStage = 2;
                                        }
                                        if (_practiceStage0StartTime != null) {
                                          final seconds =
                                              DateTime.now()
                                                  .difference(
                                                    _practiceStage0StartTime!,
                                                  )
                                                  .inMilliseconds /
                                              1000.0;
                                          _recordStage0Duration(seconds);
                                        }
                                      }
                                      _updatePracticeText();
                                    });
                                  } else if (r == _practiceHighlightedRow &&
                                      c == _practiceHighlightedCol) {
                                    // Tapping target cell: do nothing
                                  } else {
                                    _recordMistake();
                                    setState(() {
                                      _practiceShowError = true;
                                      _practiceHelp =
                                          "Oops! Cell at Row ${r + 1}, Col ${c + 1} is not part of the $lessonTitle pattern. Look for the cells highlighted in the strategy guide or check the hint.";
                                      if (_timeAttackActive) {
                                        _timeAttackTimeLeft = max(
                                          0,
                                          _timeAttackTimeLeft - 15,
                                        );
                                        _timeAttackMistakeCount++;
                                        if (_timeAttackTimeLeft <= 0) {
                                          _endTimeAttack();
                                        }
                                      } else {
                                        _practiceStreak = 0;
                                      }
                                    });
                                    _shakeController.forward(from: 0.0);
                                  }
                                }
                              } else {
                                if (r == _practiceHighlightedRow &&
                                    c == _practiceHighlightedCol) {
                                  setState(() {
                                    _practiceSelectedRow = r;
                                    _practiceSelectedCol = c;
                                  });
                                }
                              }
                            },
                          ),
                          if (_practiceLinks != null &&
                              _practiceLinks!.isNotEmpty &&
                              (_practiceStage > 0 || _practiceShowHint))
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: SudokuLinkPainter(
                                    links: _practiceLinks!,
                                    strongColor: Colors.teal.shade500,
                                    weakColor: Colors.deepOrange.shade400,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (!_practiceIsSolved) ...[
            if (_practiceStage == 0)
              _buildPatternSelectionPanel()
            else if (_practiceStage == 1)
              _buildCandidateEliminationPanel()
            else
              _buildTutorialNumpad(onTap: _handlePracticeNumpadTap),
          ],
          const SizedBox(height: 16),
          _buildFeedbackBanner(
            isSolved: _practiceIsSolved,
            showErrorHint: _practiceShowError,
            interactiveHelp: _practiceHelp,
            expectedValue: _practiceExpectedValue,
          ),
          if (!_practiceIsSolved) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _practiceShowHint = !_practiceShowHint;
                  });
                },
                icon: Icon(
                  _practiceShowHint
                      ? Icons.lightbulb_rounded
                      : Icons.lightbulb_outline_rounded,
                ),
                label: Text(_practiceShowHint ? 'HIDE HINT' : 'REVEAL HINT'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.tertiary,
                ),
              ),
            ),
            if (_practiceShowHint) ...[
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: theme.colorScheme.tertiaryContainer.withValues(
                  alpha: 0.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_rounded,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _practiceHelp,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _practiceText,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ExpansionTile(
                title: Text(
                  'STRATEGY GUIDE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                    letterSpacing: 1.1,
                  ),
                ),
                leading: Icon(
                  Icons.menu_book_rounded,
                  color: theme.colorScheme.secondary,
                ),
                collapsedBackgroundColor: theme.colorScheme.surfaceContainerLow,
                backgroundColor: theme.colorScheme.surfaceContainer,
                childrenPadding: const EdgeInsets.all(16.0),
                expandedAlignment: Alignment.topLeft,
                children: [
                  Text(
                    lessons[_practiceLessonIndex].slides.first.text,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showLessonList(forPractice: true),
                icon: const Icon(Icons.psychology_rounded),
                label: const Text('CHANGE TECHNIQUE'),
              ),
              FilledButton.icon(
                onPressed: () =>
                    _generatePracticeChallenge(_practiceLessonIndex),
                icon: Icon(
                  _practiceIsSolved
                      ? Icons.arrow_forward_rounded
                      : Icons.refresh_rounded,
                ),
                label: Text(
                  _practiceIsSolved ? 'NEXT CHALLENGE' : 'NEW CHALLENGE',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStepProgress(LessonData lesson) {
    final theme = Theme.of(context);

    return Row(
      children: List.generate(lesson.slides.length, (index) {
        final isCompleted = index < _currentSlideIndex;
        final isActive = index == _currentSlideIndex;

        return Expanded(
          child: Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: isCompleted
                  ? theme.colorScheme.primary
                  : (isActive
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLessonSelector(List<LessonData> lessons) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _currentLessonIndex == 0
                  ? null
                  : () {
                      setState(() {
                        _currentLessonIndex--;
                        _currentSlideIndex = 0;
                        _initSlide();
                      });
                    },
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _showLessonList(forPractice: false),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      lessons[_currentLessonIndex].title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: _currentLessonIndex == lessons.length - 1
                  ? null
                  : () {
                      setState(() {
                        _currentLessonIndex++;
                        _currentSlideIndex = 0;
                        _initSlide();
                      });
                    },
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialNumpad({required Function(int) onTap}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            'SELECT A CANDIDATE VALUE',
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(9, (index) {
              final num = index + 1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Material(
                    color: theme.colorScheme.secondaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => onTap(num),
                      customBorder: const CircleBorder(),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        child: Text(
                          '$num',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBanner({
    required bool isSolved,
    required bool showErrorHint,
    required String? interactiveHelp,
    required int? expectedValue,
  }) {
    final theme = Theme.of(context);

    if (isSolved && expectedValue != null) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correct!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Excellent work solving this step!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (showErrorHint && interactiveHelp != null) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: theme.colorScheme.error,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not quite right',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      interactiveHelp,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPaginationControls(List<LessonData> lessons) {
    final lesson = lessons[_currentLessonIndex];
    final isLastSlide = _currentSlideIndex == lesson.slides.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton.icon(
          onPressed: _currentSlideIndex == 0
              ? null
              : () {
                  setState(() {
                    _currentSlideIndex--;
                    _initSlide();
                  });
                },
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: const Text('PREVIOUS'),
        ),
        IconButton.filledTonal(
          onPressed: _togglePlayLessons,
          icon: Icon(
            _isPlayingLessons ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
          tooltip: 'Autoplay Lessons',
        ),
        FilledButton.icon(
          onPressed: !_isSolved
              ? null
              : (isLastSlide
                    ? (_currentLessonIndex == lessons.length - 1
                          ? () => Navigator.pop(context)
                          : () {
                              setState(() {
                                _currentLessonIndex++;
                                _currentSlideIndex = 0;
                                _initSlide();
                              });
                            })
                    : () {
                        setState(() {
                          _currentSlideIndex++;
                          _initSlide();
                        });
                      }),
          icon: Icon(
            isLastSlide && _currentLessonIndex == lessons.length - 1
                ? Icons.check_circle_outline_rounded
                : Icons.arrow_forward_rounded,
            size: 16,
          ),
          label: Text(
            isLastSlide
                ? (_currentLessonIndex == lessons.length - 1
                      ? 'GRADUATE'
                      : 'NEXT LESSON')
                : 'CONTINUE',
          ),
        ),
      ],
    );
  }

  Widget _buildPatternSelectionPanel() {
    final theme = Theme.of(context);
    final count = _practiceSelectedPatternCells.length;
    final total = _practicePatternCells.length;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_searching_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'LOCATE THE PATTERN CELLS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap all the cells forming the strategy pattern.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '$count of $total cells identified',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateEliminationPanel() {
    final theme = Theme.of(context);
    final targetKey = '$_practiceHighlightedRow,$_practiceHighlightedCol';
    final targetNotes = _practiceNotes?[targetKey] ?? {};
    final lessons = SudokuLessonsData.getLessons(context);
    final lessonTitle = lessons[_practiceLessonIndex].title;

    return Card(
      elevation: 2,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Text(
              'CANDIDATE ELIMINATION PANEL',
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the candidates to eliminate them from the target cell:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: targetNotes.map((candidate) {
                final isEliminated = _practiceEliminatedCandidates.contains(
                  candidate,
                );
                final isIncorrect = _practiceIncorrectCandidates.contains(
                  candidate,
                );

                return Padding(
                  key: ValueKey<int>(candidate),
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Material(
                    color: isEliminated
                        ? theme.colorScheme.errorContainer.withValues(
                            alpha: 0.3,
                          )
                        : theme.colorScheme.secondaryContainer.withValues(
                            alpha: 0.3,
                          ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isEliminated
                            ? theme.colorScheme.error.withValues(alpha: 0.3)
                            : theme.colorScheme.secondary.withValues(
                                alpha: 0.2,
                              ),
                      ),
                    ),
                    child: InkWell(
                      onTap: isEliminated
                          ? null
                          : () {
                              if (isIncorrect) {
                                setState(() {
                                  _practiceEliminatedCandidates.add(candidate);
                                  _practiceNotes?[targetKey]?.remove(candidate);
                                  _practiceShowError = false;
                                  if (_practiceEliminatedCandidates.containsAll(
                                    _practiceIncorrectCandidates,
                                  )) {
                                    _practiceStage = 2; // Move to solve stage
                                  }
                                  _updatePracticeText();
                                });
                              } else {
                                setState(() {
                                  _practiceShowError = true;
                                  _practiceHelp =
                                      "Oops! Candidate $candidate is the actual solution for this cell. In $lessonTitle, we only eliminate invalid candidates, leaving the correct one.";
                                  if (_timeAttackActive) {
                                    _timeAttackTimeLeft = max(
                                      0,
                                      _timeAttackTimeLeft - 15,
                                    );
                                    _timeAttackMistakeCount++;
                                    if (_timeAttackTimeLeft <= 0) {
                                      _endTimeAttack();
                                    }
                                  } else {
                                    _practiceStreak = 0;
                                  }
                                });
                                _shakeController.forward(from: 0.0);
                              }
                            },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 50,
                        height: 44,
                        alignment: Alignment.center,
                        child: Text(
                          '$candidate',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isEliminated
                                ? theme.colorScheme.error.withValues(alpha: 0.4)
                                : theme.colorScheme.secondary,
                            decoration: isEliminated
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // --- Progress Tracking and Time Attack Helpers ---

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getStringList('completed_lessons') ?? [];
      final completedSet = completed.map((e) => int.parse(e)).toSet();

      final practiceCountsRaw = prefs.getString('practice_counts') ?? '{}';
      final Map<String, dynamic> practiceMapRaw = jsonDecode(practiceCountsRaw);
      final Map<int, int> practiceMap = {};
      practiceMapRaw.forEach((k, v) {
        practiceMap[int.parse(k)] = v as int;
      });

      final highScore = prefs.getInt('time_attack_high_score') ?? 0;

      if (mounted) {
        setState(() {
          _completedLessons = completedSet;
          _practiceCounts = practiceMap;
          _timeAttackHighScore = highScore;
        });
      }
    } catch (e) {
      debugPrint('Error loading progress: $e');
    }
  }

  Future<void> _completeLesson(int lessonIndex) async {
    if (_completedLessons.contains(lessonIndex)) return;
    setState(() {
      _completedLessons.add(lessonIndex);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'completed_lessons',
      _completedLessons.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _solvePractice(int lessonIndex) async {
    setState(() {
      _practiceCounts[lessonIndex] = (_practiceCounts[lessonIndex] ?? 0) + 1;
    });
    final prefs = await SharedPreferences.getInstance();
    final countsMap = _practiceCounts.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString('practice_counts', jsonEncode(countsMap));
  }

  bool _isTierLocked(int tier) {
    if (tier == 1) return false;
    if (tier == 2) {
      for (int i = 0; i <= 11; i++) {
        if (!_completedLessons.contains(i)) return true;
      }
      int tier1PracticeCount = 0;
      for (int i = 0; i <= 11; i++) {
        tier1PracticeCount += _practiceCounts[i] ?? 0;
      }
      return tier1PracticeCount < 3;
    }
    if (tier == 3) {
      if (_isTierLocked(2)) return true;
      for (int i = 12; i <= 21; i++) {
        if (!_completedLessons.contains(i)) return true;
      }
      int tier2PracticeCount = 0;
      for (int i = 12; i <= 21; i++) {
        tier2PracticeCount += _practiceCounts[i] ?? 0;
      }
      return tier2PracticeCount < 3;
    }
    if (tier == 4) {
      if (_isTierLocked(3)) return true;
      for (int i = 22; i <= 29; i++) {
        if (!_completedLessons.contains(i)) return true;
      }
      int tier3PracticeCount = 0;
      for (int i = 22; i <= 29; i++) {
        tier3PracticeCount += _practiceCounts[i] ?? 0;
      }
      return tier3PracticeCount < 3;
    }
    return false;
  }

  int _getLessonTier(int lessonIndex) {
    if (lessonIndex <= 11) return 1;
    if (lessonIndex <= 21) return 2;
    if (lessonIndex <= 29) return 3;
    return 4;
  }

  bool _isLessonLocked(int lessonIndex) =>
      _isTierLocked(_getLessonTier(lessonIndex));

  int _pickRandomUnlockedLesson() {
    final unlocked = <int>[];
    for (int i = 0; i < 45; i++) {
      if (!_isLessonLocked(i)) {
        unlocked.add(i);
      }
    }
    if (unlocked.isEmpty) {
      return 0;
    }
    return unlocked[Random().nextInt(unlocked.length)];
  }

  void _startTimeAttack() {
    _timeAttackTimer?.cancel();
    final randomLesson = _pickRandomUnlockedLesson();
    _generatePracticeChallenge(randomLesson);

    setState(() {
      _timeAttackActive = true;
      _timeAttackTimeLeft = 180;
      _timeAttackScore = 0;
      _timeAttackCorrectCount = 0;
      _timeAttackMistakeCount = 0;
      _practiceShowError = false;
    });

    _timeAttackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeAttackTimeLeft > 0) {
          _timeAttackTimeLeft--;
        } else {
          _endTimeAttack();
        }
      });
    });
  }

  void _generateTimeAttackChallenge() {
    final randomLesson = _pickRandomUnlockedLesson();
    _generatePracticeChallenge(randomLesson);
    setState(() {
      _practiceShowError = false;
    });
  }

  Future<void> _endTimeAttack() async {
    _timeAttackTimer?.cancel();
    _timeAttackTimer = null;

    setState(() {
      _timeAttackActive = false;
    });

    final prefs = await SharedPreferences.getInstance();
    if (_timeAttackScore > _timeAttackHighScore) {
      _timeAttackHighScore = _timeAttackScore;
      await prefs.setInt('time_attack_high_score', _timeAttackHighScore);
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.timer_off_rounded, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                const Text("Time's Up!"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Great effort! Here is your performance summary:',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _buildScoreStatRow('Final Score', '$_timeAttackScore pts'),
                _buildScoreStatRow(
                  'Correct Solves',
                  '$_timeAttackCorrectCount',
                ),
                _buildScoreStatRow('Mistakes Made', '$_timeAttackMistakeCount'),
                const SizedBox(height: 12),
                if (_timeAttackScore >= _timeAttackHighScore &&
                    _timeAttackHighScore > 0)
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events_rounded, color: Colors.amber),
                          SizedBox(width: 8),
                          Text(
                            'NEW PERSONAL BEST!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('CLOSE'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startTimeAttack();
                },
                child: const Text('PLAY AGAIN'),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildScoreStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTimeAttackTab(List<LessonData> lessons) {
    final theme = Theme.of(context);
    if (!_timeAttackActive) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.timer_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'TIME ATTACK BLITZ',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Solve as many pattern puzzles as possible in 3 minutes under pressure! Only techniques you have unlocked will appear.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: theme.colorScheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatDisplay(
                            context,
                            'PERSONAL BEST',
                            '$_timeAttackHighScore',
                            Icons.emoji_events_rounded,
                            Colors.amber.shade700,
                          ),
                          _buildStatDisplay(
                            context,
                            'UNLOCKED TECHNIQUES',
                            '${_countUnlockedLessons()}/45',
                            Icons.lock_open_rounded,
                            theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _startTimeAttack,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text(
                  'START BLITZ CHALLENGE',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final lessonTitle = lessons[_practiceLessonIndex].title;
    final int minutes = _timeAttackTimeLeft ~/ 60;
    final int seconds = _timeAttackTimeLeft % 60;
    final String timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';
    final progress = _timeAttackTimeLeft / 180.0;

    List<List<Set<int>>> gridNotes = List.generate(
      9,
      (_) => List.generate(9, (_) => {}),
    );
    if (_practiceNotes != null) {
      _practiceNotes!.forEach((key, value) {
        final parts = key.split(',');
        final r = int.parse(parts[0]);
        final c = int.parse(parts[1]);
        gridNotes[r][c] = value;
      });
    }

    Map<String, Color> customBgs = {};
    if (_practiceStage == 0) {
      final targetColor = theme.colorScheme.primaryContainer.withValues(
        alpha: 0.65,
      );
      customBgs['$_practiceHighlightedRow,$_practiceHighlightedCol'] =
          targetColor;
      for (var cellKey in _practiceSelectedPatternCells) {
        customBgs[cellKey] = Colors.orange.withValues(alpha: 0.5);
      }
    } else {
      if (_practiceCustomHighlights != null) {
        customBgs = _practiceCustomHighlights!(context);
      }
    }

    List<List<int>> solvedBoard = List.generate(
      9,
      (r) => List.generate(9, (c) {
        if (r == _practiceHighlightedRow &&
            c == _practiceHighlightedCol &&
            _practiceExpectedValue != null) {
          return _practiceExpectedValue!;
        }
        return _practiceBoard != null ? _practiceBoard![r][c] : 0;
      }),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            color: theme.colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            color: _timeAttackTimeLeft < 30
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _timeAttackTimeLeft < 30
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Score: $_timeAttackScore',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    color: _timeAttackTimeLeft < 30
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current Strategy: $lessonTitle',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCandidateFilterBar(),
          const SizedBox(height: 12),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0.0),
                    child: child,
                  );
                },
                child: _practiceBoard != null
                    ? Stack(
                        children: [
                          SudokuGrid(
                            board: _practiceBoard!,
                            selectedRow: _practiceSelectedRow,
                            selectedCol: _practiceSelectedCol,
                            notes: gridNotes,
                            solvedBoard: solvedBoard,
                            customCellBgs: customBgs,
                            candidateFilter: _selectedCandidateFilter,
                            onCellTap: (r, c) {
                              final key = '$r,$c';
                              if (_practiceStage == 0) {
                                if (_practiceLinks != null &&
                                    _practiceLinks!.isNotEmpty) {
                                  final path = _extractCellPath(
                                    _practiceLinks!,
                                  );
                                  if (_practiceTrace.contains(key)) {
                                    if (_practiceTrace.last == key) {
                                      setState(() {
                                        _practiceTrace.removeLast();
                                        _practiceSelectedPatternCells.remove(
                                          key,
                                        );
                                        _updatePracticeText();
                                      });
                                    }
                                  } else {
                                    bool isCorrect = false;
                                    if (_practiceTrace.isEmpty) {
                                      isCorrect =
                                          (key == path.first ||
                                          key == path.last);
                                    } else {
                                      if (_practiceTrace.first == path.first) {
                                        isCorrect =
                                            (key ==
                                            path[_practiceTrace.length]);
                                      } else {
                                        isCorrect =
                                            (key ==
                                            path[path.length -
                                                1 -
                                                _practiceTrace.length]);
                                      }
                                    }

                                    if (isCorrect) {
                                      setState(() {
                                        _practiceTrace.add(key);
                                        _practiceSelectedPatternCells.add(key);
                                        _practiceShowError = false;
                                        if (_practiceTrace.length ==
                                            path.length) {
                                          _practiceStage = 1;
                                          if (_practiceIncorrectCandidates
                                              .isEmpty) {
                                            _practiceStage = 2;
                                          }
                                          if (_practiceStage0StartTime !=
                                              null) {
                                            final seconds =
                                                DateTime.now()
                                                    .difference(
                                                      _practiceStage0StartTime!,
                                                    )
                                                    .inMilliseconds /
                                                1000.0;
                                            _recordStage0Duration(seconds);
                                          }
                                        }
                                        _updatePracticeText();
                                      });
                                    } else {
                                      _recordMistake();
                                      setState(() {
                                        _practiceShowError = true;
                                        _practiceHelp =
                                            "Oops! Cell at Row ${r + 1}, Col ${c + 1} does not continue the chain sequence. Alternating links must follow the path in order. Start at an endpoint cell.";
                                        _timeAttackTimeLeft = max(
                                          0,
                                          _timeAttackTimeLeft - 15,
                                        );
                                        _timeAttackMistakeCount++;
                                        if (_timeAttackTimeLeft <= 0) {
                                          _endTimeAttack();
                                        }
                                      });
                                      _shakeController.forward(from: 0.0);
                                    }
                                  }
                                } else {
                                  if (_practicePatternCells.contains(key)) {
                                    setState(() {
                                      if (_practiceSelectedPatternCells
                                          .contains(key)) {
                                        _practiceSelectedPatternCells.remove(
                                          key,
                                        );
                                      } else {
                                        _practiceSelectedPatternCells.add(key);
                                      }
                                      if (_practiceSelectedPatternCells
                                                  .length ==
                                              _practicePatternCells.length &&
                                          _practiceSelectedPatternCells
                                              .containsAll(
                                                _practicePatternCells,
                                              )) {
                                        _practiceStage = 1;
                                        if (_practiceIncorrectCandidates
                                            .isEmpty) {
                                          _practiceStage = 2;
                                        }
                                        if (_practiceStage0StartTime != null) {
                                          final seconds =
                                              DateTime.now()
                                                  .difference(
                                                    _practiceStage0StartTime!,
                                                  )
                                                  .inMilliseconds /
                                              1000.0;
                                          _recordStage0Duration(seconds);
                                        }
                                      }
                                      _updatePracticeText();
                                    });
                                  } else if (r == _practiceHighlightedRow &&
                                      c == _practiceHighlightedCol) {
                                    // Tapping target cell: do nothing
                                  } else {
                                    _recordMistake();
                                    setState(() {
                                      _practiceShowError = true;
                                      _practiceHelp =
                                          "Oops! Cell at Row ${r + 1}, Col ${c + 1} is not part of the $lessonTitle pattern. Look for the cells highlighted in the strategy guide or check the hint.";
                                      _timeAttackTimeLeft = max(
                                        0,
                                        _timeAttackTimeLeft - 15,
                                      );
                                      _timeAttackMistakeCount++;
                                      if (_timeAttackTimeLeft <= 0) {
                                        _endTimeAttack();
                                      }
                                    });
                                    _shakeController.forward(from: 0.0);
                                  }
                                }
                              } else {
                                if (r == _practiceHighlightedRow &&
                                    c == _practiceHighlightedCol) {
                                  setState(() {
                                    _practiceSelectedRow = r;
                                    _practiceSelectedCol = c;
                                  });
                                }
                              }
                            },
                          ),
                          if (_practiceLinks != null &&
                              _practiceLinks!.isNotEmpty &&
                              (_practiceStage > 0 || _practiceShowHint))
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: SudokuLinkPainter(
                                    links: _practiceLinks!,
                                    strongColor: Colors.teal.shade500,
                                    weakColor: Colors.deepOrange.shade400,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (!_practiceIsSolved) ...[
            if (_practiceStage == 0)
              _buildPatternSelectionPanel()
            else if (_practiceStage == 1)
              _buildCandidateEliminationPanel()
            else
              _buildTutorialNumpad(onTap: _handlePracticeNumpadTap),
          ],
          const SizedBox(height: 16),
          _buildFeedbackBanner(
            isSolved: _practiceIsSolved,
            showErrorHint: _practiceShowError,
            interactiveHelp: _practiceHelp,
            expectedValue: _practiceExpectedValue,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _practiceText,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Surrender Run?'),
                  content: const Text(
                    'Are you sure you want to end this Time Attack run? Your current score will be saved if it is a new high score.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _endTimeAttack();
                      },
                      child: const Text('SURRENDER'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.exit_to_app_rounded),
            label: const Text('ABANDON RUN'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatDisplay(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  int _countUnlockedLessons() {
    int count = 0;
    for (int i = 0; i < 45; i++) {
      if (!_isLessonLocked(i)) count++;
    }
    return count;
  }

  // --- New Suggestions Helpers (Path Tracing, Autoplay, Analytics) ---

  List<String> _extractCellPath(List<List<String>> links) {
    if (links.isEmpty) return [];

    // 1. Build adjacency list representation of the links graph
    final Map<String, List<String>> adj = {};
    for (var link in links) {
      if (link.length < 2) continue;
      final u = link[0];
      final v = link[1];
      adj.putIfAbsent(u, () => []).add(v);
      adj.putIfAbsent(v, () => []).add(u);
    }

    // 2. Find starting cell. Prefer a cell with degree 1 (endpoint of chain).
    // If none (e.g. it's a closed loop/cycle), pick the first node in the links list.
    String start = links[0][0];
    for (var node in adj.keys) {
      if (adj[node]!.length == 1) {
        start = node;
        break;
      }
    }

    // 3. Traverse the graph to construct a sequential path of unique cells
    final path = <String>[start];
    final visited = <String>{start};
    String current = start;

    while (true) {
      final neighbors = adj[current] ?? [];
      String? next;
      for (var n in neighbors) {
        if (!visited.contains(n)) {
          next = n;
          break;
        }
      }
      if (next == null) {
        break;
      }
      path.add(next);
      visited.add(next);
      current = next;
    }
    return path;
  }

  void _togglePlayLessons() {
    if (_isPlayingLessons) {
      _lessonPlayTimer?.cancel();
      setState(() {
        _isPlayingLessons = false;
      });
    } else {
      setState(() {
        _isPlayingLessons = true;
      });
      _runLessonAutoplay();
    }
  }

  void _runLessonAutoplay() {
    _lessonPlayTimer?.cancel();
    _lessonPlayTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || !_isPlayingLessons) return;

      final lessons = SudokuLessonsData.getLessons(context);
      final lesson = lessons[_currentLessonIndex];
      final isLastSlide = _currentSlideIndex == lesson.slides.length - 1;

      if (_isSolved) {
        if (isLastSlide) {
          if (_currentLessonIndex < lessons.length - 1) {
            setState(() {
              _currentLessonIndex++;
              _currentSlideIndex = 0;
              _initSlide();
            });
            _runLessonAutoplay();
          } else {
            setState(() {
              _isPlayingLessons = false;
            });
          }
        } else {
          setState(() {
            _currentSlideIndex++;
            _initSlide();
          });
          _runLessonAutoplay();
        }
      } else {
        setState(() {
          _isPlayingLessons = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Autoplay paused. Please solve the current step to proceed.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _recordMistake() async {
    setState(() {
      _totalMistakesMade++;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_mistakes_made', _totalMistakesMade);
  }

  Future<void> _recordStage0Duration(double seconds) async {
    setState(() {
      _stage0SolveTimes.add(seconds);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stage0_solve_times', jsonEncode(_stage0SolveTimes));
  }

  Widget _buildCandidateFilterBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              'CANDIDATE FILTER',
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.8,
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(9, (index) {
              final digit = index + 1;
              final isSelected = _selectedCandidateFilter == digit;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: ChoiceChip(
                    label: Text(
                      '$digit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCandidateFilter = selected ? digit : -1;
                      });
                    },
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    showCheckmark: false,
                    padding: EdgeInsets.zero,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsDashboard() {
    final theme = Theme.of(context);
    final completedCount = _completedLessons.length;
    final avgSpeed = _stage0SolveTimes.isEmpty
        ? 'N/A'
        : '${(_stage0SolveTimes.reduce((a, b) => a + b) / _stage0SolveTimes.length).toStringAsFixed(1)}s';

    int tier1Count = 0;
    int tier2Count = 0;
    int tier3Count = 0;
    int tier4Count = 0;
    for (int idx in _completedLessons) {
      final t = _getLessonTier(idx);
      if (t == 1) tier1Count++;
      if (t == 2) tier2Count++;
      if (t == 3) tier3Count++;
      if (t == 4) tier4Count++;
    }

    String advice =
        "Start practicing techniques and solving lessons to see personalized training tips here!";
    if (_totalMistakesMade > 15) {
      advice =
          "Training Tip: Take your time to locate and trace patterns in Stage 0. Rushing cell selections is causing mistake penalties!";
    } else if (_stage0SolveTimes.isNotEmpty) {
      final avg =
          _stage0SolveTimes.reduce((a, b) => a + b) / _stage0SolveTimes.length;
      if (avg > 15) {
        advice =
            "Training Tip: Your accuracy is solid, but scanning speed could improve. Try the Time Attack blitz to train quick recognition under pressure!";
      } else {
        advice =
            "Training Tip: Outstanding! Your pattern recognition speed is super fast ($avgSpeed) with minimal mistakes. Keep pushing advanced chaining tiers!";
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'School Analytics',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: theme.colorScheme.surfaceContainerHigh,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'LESSONS',
                                  style: TextStyle(fontSize: 10),
                                ),
                                Text(
                                  '$completedCount / 45',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          color: theme.colorScheme.surfaceContainerHigh,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.speed_rounded,
                                  color: Colors.green,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'AVG RECOGNITION',
                                  style: TextStyle(fontSize: 10),
                                ),
                                Text(
                                  avgSpeed,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: theme.colorScheme.surfaceContainerHigh,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.report_problem_rounded,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'MISTAKES MADE',
                                  style: TextStyle(fontSize: 10),
                                ),
                                Text(
                                  '$_totalMistakesMade',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          color: theme.colorScheme.surfaceContainerHigh,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.timer_rounded,
                                  color: Colors.amber,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'TIME ATTACK BEST',
                                  style: TextStyle(fontSize: 10),
                                ),
                                Text(
                                  '$_timeAttackHighScore pts',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'CURRICULUM TIERS PROGRESS',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTierProgressBar(
                    'Tier 1: Basics & scanning',
                    tier1Count,
                    12,
                    theme,
                  ),
                  _buildTierProgressBar(
                    'Tier 2: Advanced Fish',
                    tier2Count,
                    10,
                    theme,
                  ),
                  _buildTierProgressBar(
                    'Tier 3: Wing Strategies',
                    tier3Count,
                    8,
                    theme,
                  ),
                  _buildTierProgressBar(
                    'Tier 4: Chaining & Uniqueness',
                    tier4Count,
                    15,
                    theme,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              advice,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTierProgressBar(
    String title,
    int count,
    int total,
    ThemeData theme,
  ) {
    final percent = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$count/$total completed',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percent,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class SudokuLinkPainter extends CustomPainter {
  final List<List<String>> links;
  final Color strongColor;
  final Color weakColor;

  SudokuLinkPainter({
    required this.links,
    required this.strongColor,
    required this.weakColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / 9.0;
    final double cellHeight = size.height / 9.0;

    final strongPaint = Paint()
      ..color = strongColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final weakPaint = Paint()
      ..color = weakColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.indigo.shade800
      ..style = PaintingStyle.fill;

    for (final link in links) {
      if (link.length < 3) continue;
      final startParts = link[0].split(',');
      final endParts = link[1].split(',');
      final type = link[2];

      if (startParts.length < 2 || endParts.length < 2) continue;
      final r1 = int.tryParse(startParts[0]);
      final c1 = int.tryParse(startParts[1]);
      final r2 = int.tryParse(endParts[0]);
      final c2 = int.tryParse(endParts[1]);

      if (r1 == null || c1 == null || r2 == null || c2 == null) continue;

      final startOffset = Offset(
        (c1 + 0.5) * cellWidth,
        (r1 + 0.5) * cellHeight,
      );
      final endOffset = Offset((c2 + 0.5) * cellWidth, (r2 + 0.5) * cellHeight);

      if (type == 'strong') {
        canvas.drawLine(startOffset, endOffset, strongPaint);
      } else {
        _drawDashedLine(canvas, startOffset, endOffset, weakPaint);
      }

      canvas.drawCircle(startOffset, 5.0, dotPaint);
      canvas.drawCircle(endOffset, 5.0, dotPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashLength = 6.0;
    const double gapLength = 4.0;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = sqrt(dx * dx + dy * dy);
    if (distance == 0) return;
    final int count = (distance / (dashLength + gapLength)).floor();

    for (int i = 0; i < count; i++) {
      final double startFraction = (i * (dashLength + gapLength)) / distance;
      final double endFraction =
          (i * (dashLength + gapLength) + dashLength) / distance;
      canvas.drawLine(
        Offset(p1.dx + dx * startFraction, p1.dy + dy * startFraction),
        Offset(p1.dx + dx * endFraction, p1.dy + dy * endFraction),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SudokuLinkPainter oldDelegate) {
    return oldDelegate.links != links ||
        oldDelegate.strongColor != strongColor ||
        oldDelegate.weakColor != weakColor;
  }
}
