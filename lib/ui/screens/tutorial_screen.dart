import 'package:flutter/material.dart';
import '../components/sudoku_grid.dart';

/// Interactive tutorial screen providing slides, explainers, and highlighted grids for strategies.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentLessonIndex = 0;
  int _currentSlideIndex = 0;

  // Lesson Definitions
  final List<LessonData> _lessons = [
    // Lesson 1: Basics
    LessonData(
      title: 'Basics: Scanning',
      slides: [
        SlideData(
          text:
              'Sudoku is played on a 9x9 grid. Your goal is to fill the grid so that each row, column, and 3x3 box contains all digits from 1 to 9 without repetition.',
          board: [
            [1, 2, 3, 0, 0, 0, 0, 0, 0],
            [4, 5, 6, 0, 0, 0, 0, 0, 0],
            [7, 8, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
          ],
          highlightedRow: 2,
          highlightedCol: 2,
          notes: {},
        ),
        SlideData(
          text:
              'Look at the highlighted cell (Row 3, Col 3). The top-left 3x3 box already contains the numbers 1 through 8. The only missing number to complete this box is 9! Tap and input 9.',
          board: [
            [1, 2, 3, 0, 0, 0, 0, 0, 0],
            [4, 5, 6, 0, 0, 0, 0, 0, 0],
            [7, 8, 9, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
          ],
          highlightedRow: 2,
          highlightedCol: 2,
          notes: {},
        ),
      ],
    ),

    // Lesson 2: Naked Pairs
    LessonData(
      title: 'Naked Pairs',
      slides: [
        SlideData(
          text:
              'A "Naked Pair" occurs when exactly two cells in a row, column, or box contain the same two candidates. No other numbers can be placed in those cells.',
          board: [
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
          ],
          highlightedRow: 0,
          highlightedCol: 0,
          notes: {
            '0,0': {3, 7},
            '0,4': {3, 7},
            '0,8': {2, 3, 7},
          },
        ),
        SlideData(
          text:
              'In Row 1, Col 1 and Col 5 contain ONLY candidates {3, 7}. Because 3 and 7 must be in these two cells, we can safely eliminate 3 and 7 from the rest of Row 1. Thus, Col 9 must be 2!',
          board: [
            [0, 0, 0, 0, 0, 0, 0, 0, 2],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
          ],
          highlightedRow: 0,
          highlightedCol: 8,
          notes: {
            '0,0': {3, 7},
            '0,4': {3, 7},
          },
        ),
      ],
    ),

    // Lesson 3: Pointing Pairs
    LessonData(
      title: 'Pointing Pairs',
      slides: [
        SlideData(
          text:
              'A "Pointing Pair" occurs when candidate values in a 3x3 box align strictly within a single row or column. This forces that number to be in that line inside the box.',
          board: [
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
          ],
          highlightedRow: 1,
          highlightedCol: 1,
          notes: {
            '1,0': {5},
            '1,1': {5},
            '1,5': {4, 5},
          },
        ),
        SlideData(
          text:
              'In Box 1, candidate 5 is restricted to Row 2. This means 5 MUST appear in Row 2 of Box 1. We can pointing-eliminate candidate 5 from Row 2, Col 6. It only has candidate 4 remaining!',
          board: [
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 4, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
          ],
          highlightedRow: 1,
          highlightedCol: 5,
          notes: {
            '1,0': {5},
            '1,1': {5},
          },
        ),
      ],
    ),

    // Lesson 4: X-Wing
    LessonData(
      title: 'Advanced: X-Wing',
      slides: [
        SlideData(
          text:
              'An X-Wing is formed when a candidate is restricted to exactly two cells in two parallel rows (forming a rectangle). It locks the position of that digit.',
          board: [
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
          ],
          highlightedRow: 1,
          highlightedCol: 1,
          notes: {
            '1,1': {4},
            '1,6': {4},
            '5,1': {4},
            '5,6': {4},
            '3,1': {4, 9},
          },
        ),
        SlideData(
          text:
              'Rows 2 and 6 only have candidate 4 in Cols 2 and 7 (forming a box). This locks the 4s in diagonally. Therefore, 4 cannot appear anywhere else in Cols 2 or 7. Row 4, Col 2 must be 9!',
          board: [
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 9, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
          ],
          highlightedRow: 3,
          highlightedCol: 1,
          notes: {
            '1,1': {4},
            '1,6': {4},
            '5,1': {4},
            '5,6': {4},
          },
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lesson = _lessons[_currentLessonIndex];
    final slide = lesson.slides[_currentSlideIndex];

    // Build notes list representation from map coordinates
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLessonSelector(),
                    const SizedBox(height: 20),
                    // Explanatory Grid
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: SudokuGrid(
                          board: slide.board,
                          selectedRow: slide.highlightedRow,
                          selectedCol: slide.highlightedCol,
                          notes: gridNotes,
                          onCellTap: (_, __) {}, // Read-only grid
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Slide Explainer Card
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
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              slide.text,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildPaginationControls(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
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
          const SizedBox(width: 48), // Equal spacing placeholder
        ],
      ),
    );
  }

  Widget _buildLessonSelector() {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.15),
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
                      });
                    },
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                _lessons[_currentLessonIndex].title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            IconButton(
              onPressed: _currentLessonIndex == _lessons.length - 1
                  ? null
                  : () {
                      setState(() {
                        _currentLessonIndex++;
                        _currentSlideIndex = 0;
                      });
                    },
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    final lesson = _lessons[_currentLessonIndex];
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
                  });
                },
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: const Text('PREVIOUS'),
        ),
        FilledButton.icon(
          onPressed: isLastSlide
              ? (_currentLessonIndex == _lessons.length - 1
                    ? () => Navigator.pop(context)
                    : () {
                        setState(() {
                          _currentLessonIndex++;
                          _currentSlideIndex = 0;
                        });
                      })
              : () {
                  setState(() {
                    _currentSlideIndex++;
                  });
                },
          icon: Icon(
            isLastSlide && _currentLessonIndex == _lessons.length - 1
                ? Icons.check_circle_outline_rounded
                : Icons.arrow_forward_rounded,
            size: 16,
          ),
          label: Text(
            isLastSlide
                ? (_currentLessonIndex == _lessons.length - 1
                      ? 'GRADUATE'
                      : 'NEXT LESSON')
                : 'CONTINUE',
          ),
        ),
      ],
    );
  }
}

// Models
class LessonData {
  final String title;
  final List<SlideData> slides;

  LessonData({required this.title, required this.slides});
}

class SlideData {
  final String text;
  final List<List<int>> board;
  final int highlightedRow;
  final int highlightedCol;
  final Map<String, Set<int>> notes;

  SlideData({
    required this.text,
    required this.board,
    required this.highlightedRow,
    required this.highlightedCol,
    required this.notes,
  });
}
