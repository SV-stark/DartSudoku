import 'package:flutter/material.dart';
import '../components/sudoku_grid.dart';
import '../../core/sudoku_lessons_data.dart';

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

  int _practiceSelectedRow = -1;
  int _practiceSelectedCol = -1;
  bool _practiceIsSolved = false;
  bool _practiceShowError = false;
  int _practiceStreak = 0;
  bool _practiceShowHint = false;

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

    // Permute board
    final permutedBoard = List.generate(9, (r) {
      return List.generate(9, (c) {
        final val = practiceSlide!.board[r][c];
        return val == 0 ? 0 : perm[val]!;
      });
    });

    final int? origExpected = practiceSlide.expectedValue;
    final int? permutedExpected = origExpected == null
        ? null
        : perm[origExpected];

    // Permute notes
    final Map<String, Set<int>> permutedNotes = {};
    practiceSlide.notes.forEach((key, valSet) {
      permutedNotes[key] = valSet.map((v) => perm[v]!).toSet();
    });

    final rowText = practiceSlide.highlightedRow + 1;
    final colText = practiceSlide.highlightedCol + 1;
    final lessonTitle = lesson.title;
    final permutedText =
        'Identify the correct candidate for the highlighted cell at Row $rowText, Col $colText using the **$lessonTitle** technique. Analyze the candidates and enter your choice below.';
    final permutedHelp = _getPracticeHint(lessonIndex, permutedExpected ?? 0);

    setState(() {
      _practiceLessonIndex = lessonIndex;
      _practiceBoard = permutedBoard;
      _practiceExpectedValue = permutedExpected;
      _practiceNotes = permutedNotes;
      _practiceText = permutedText;
      _practiceHelp = permutedHelp;
      _practiceHighlightedRow = practiceSlide!.highlightedRow;
      _practiceHighlightedCol = practiceSlide.highlightedCol;
      _practiceCustomHighlights = practiceSlide.customHighlights;

      _practiceSelectedRow = _practiceHighlightedRow;
      _practiceSelectedCol = _practiceHighlightedCol;
      _practiceIsSolved = false;
      _practiceShowError = false;
      _practiceShowHint = false;
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
    if (number == _practiceExpectedValue) {
      setState(() {
        _practiceBoard![_practiceHighlightedRow][_practiceHighlightedCol] =
            number;
        _practiceIsSolved = true;
        _practiceShowError = false;
        _practiceStreak++;
      });
    } else {
      setState(() {
        _practiceBoard![_practiceHighlightedRow][_practiceHighlightedCol] =
            number;
        _practiceShowError = true;
        _practiceStreak = 0; // Reset streak on mistake
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
                                return ListTile(
                                  onTap: () {
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
                                    backgroundColor: isCurrent
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.primaryContainer
                                              .withValues(alpha: 0.2),
                                    foregroundColor: isCurrent
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.primary,
                                    radius: 16,
                                    child: Text(
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
                                      color: isCurrent
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  trailing: isCurrent
                                      ? Icon(
                                          Icons.arrow_right_alt_rounded,
                                          color: theme.colorScheme.primary,
                                        )
                                      : const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 16,
                                        ),
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
      length: 2,
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
          const SizedBox(width: 48), // Spacer to balance back button
        ],
      ),
    );
  }

  Widget _buildLessonsTab(List<LessonData> lessons) {
    final lesson = lessons[_currentLessonIndex];
    final slide = lesson.slides[_currentSlideIndex];

    List<List<Set<int>>> gridNotes = List.generate(
      9,
      (_) => List.generate(9, (_) => {}),
    );
    slide.notes.forEach((key, value) {
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
                child: SudokuGrid(
                  board: _currentBoard ?? slide.board,
                  selectedRow: _selectedRow,
                  selectedCol: _selectedCol,
                  notes: gridNotes,
                  solvedBoard: solvedBoard,
                  customCellBgs: customBgs,
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

    final Map<String, Color> customBgs = _practiceCustomHighlights != null
        ? _practiceCustomHighlights!(context)
        : {};

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
                    ? SudokuGrid(
                        board: _practiceBoard!,
                        selectedRow: _practiceSelectedRow,
                        selectedCol: _practiceSelectedCol,
                        notes: gridNotes,
                        solvedBoard: solvedBoard,
                        customCellBgs: customBgs,
                        onCellTap: (r, c) {
                          if (r == _practiceHighlightedRow &&
                              c == _practiceHighlightedCol) {
                            setState(() {
                              _practiceSelectedRow = r;
                              _practiceSelectedCol = c;
                            });
                          }
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (!_practiceIsSolved)
            _buildTutorialNumpad(onTap: _handlePracticeNumpadTap),
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
}
